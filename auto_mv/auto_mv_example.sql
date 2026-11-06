-- Automatic materialized-view demonstration.
--
-- Run this in a scratch schema with the privileges required by
-- DBMS_SQLTUNE and DBMS_AUTO_MV.  The script intentionally does not contain
-- database credentials.

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SET ECHO ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 240
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET PAGESIZE 1000
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TAB OFF
SET TERMOUT ON
SET TRIMSPOOL ON

ALTER SESSION SET QUERY_REWRITE_ENABLED = TRUE;
ALTER SESSION SET QUERY_REWRITE_INTEGRITY = TRUSTED;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

PROMPT === Create source tables ===

CREATE TABLE amv_demo_customers
(
  customer_id NUMBER CONSTRAINT amv_demo_customers_pk PRIMARY KEY,
  region      VARCHAR2(20) NOT NULL,
  segment     VARCHAR2(20) NOT NULL
);

CREATE TABLE amv_demo_products
(
  product_id   NUMBER CONSTRAINT amv_demo_products_pk PRIMARY KEY,
  category     VARCHAR2(20) NOT NULL,
  product_name VARCHAR2(40) NOT NULL,
  unit_price   NUMBER(10,2) NOT NULL
);

CREATE TABLE amv_demo_customer_profile
(
  customer_id     NUMBER CONSTRAINT amv_demo_customer_profile_pk PRIMARY KEY,
  market          VARCHAR2(20) NOT NULL,
  acquisition_channel VARCHAR2(20) NOT NULL,
  CONSTRAINT amv_demo_customer_profile_fk
    FOREIGN KEY (customer_id) REFERENCES amv_demo_customers(customer_id)
);

CREATE TABLE amv_demo_product_profile
(
  product_id   NUMBER CONSTRAINT amv_demo_product_profile_pk PRIMARY KEY,
  product_line VARCHAR2(20) NOT NULL,
  supplier_tier VARCHAR2(20) NOT NULL,
  CONSTRAINT amv_demo_product_profile_fk
    FOREIGN KEY (product_id) REFERENCES amv_demo_products(product_id)
);

CREATE TABLE amv_demo_sales
(
  sale_id     NUMBER CONSTRAINT amv_demo_sales_pk PRIMARY KEY,
  customer_id NUMBER NOT NULL,
  product_id  NUMBER NOT NULL,
  sale_date   DATE NOT NULL,
  quantity    NUMBER(10) NOT NULL,
  amount      NUMBER(12,2) NOT NULL,
  CONSTRAINT amv_demo_sales_customer_fk
    FOREIGN KEY (customer_id) REFERENCES amv_demo_customers(customer_id),
  CONSTRAINT amv_demo_sales_product_fk
    FOREIGN KEY (product_id) REFERENCES amv_demo_products(product_id)
);

INSERT INTO amv_demo_customers (customer_id, region, segment)
SELECT level,
       CASE MOD(level - 1, 5)
         WHEN 0 THEN 'NORTH'
         WHEN 1 THEN 'SOUTH'
         WHEN 2 THEN 'EAST'
         WHEN 3 THEN 'WEST'
         ELSE 'CENTRAL'
       END,
       CASE MOD(level - 1, 3)
         WHEN 0 THEN 'CONSUMER'
         WHEN 1 THEN 'SMB'
         ELSE 'ENTERPRISE'
       END
FROM dual
CONNECT BY level <= 1000;

INSERT INTO amv_demo_products (product_id, category, product_name, unit_price)
SELECT level,
       CASE MOD(level - 1, 5)
         WHEN 0 THEN 'COMPUTE'
         WHEN 1 THEN 'STORAGE'
         WHEN 2 THEN 'NETWORK'
         WHEN 3 THEN 'DATABASE'
         ELSE 'SECURITY'
       END,
       'PRODUCT-' || TO_CHAR(level),
       ROUND(10 + MOD(level * 37, 10000) / 100, 2)
FROM dual
CONNECT BY level <= 100;

INSERT INTO amv_demo_customer_profile
       (customer_id, market, acquisition_channel)
SELECT customer_id,
       CASE MOD(customer_id - 1, 4)
         WHEN 0 THEN 'DOMESTIC'
         WHEN 1 THEN 'EMEA'
         WHEN 2 THEN 'APAC'
         ELSE 'LATAM'
       END,
       CASE MOD(customer_id - 1, 3)
         WHEN 0 THEN 'DIRECT'
         WHEN 1 THEN 'PARTNER'
         ELSE 'ONLINE'
       END
FROM amv_demo_customers;

INSERT INTO amv_demo_product_profile
       (product_id, product_line, supplier_tier)
SELECT product_id,
       CASE MOD(product_id - 1, 4)
         WHEN 0 THEN 'CORE'
         WHEN 1 THEN 'CLOUD'
         WHEN 2 THEN 'EDGE'
         ELSE 'SECURITY'
       END,
       CASE MOD(product_id - 1, 3)
         WHEN 0 THEN 'GOLD'
         WHEN 1 THEN 'SILVER'
         ELSE 'BRONZE'
       END
FROM amv_demo_products;

INSERT /*+ APPEND */ INTO amv_demo_sales
       (sale_id, customer_id, product_id, sale_date, quantity, amount)
SELECT level,
       MOD(level - 1, 1000) + 1,
       MOD(level * 17 - 1, 100) + 1,
       TRUNC(SYSDATE) - MOD(level - 1, 365),
       MOD(level - 1, 10) + 1,
       ROUND((10 + MOD(level * 37, 10000) / 100) *
             (MOD(level - 1, 10) + 1), 2)
FROM dual
CONNECT BY level <= 1000000;

COMMIT;

PROMPT === Create materialized-view logs ===

/*
CREATE MATERIALIZED VIEW LOG ON amv_demo_customers
  WITH ROWID, SEQUENCE (customer_id, region, segment)
  INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON amv_demo_products
  WITH ROWID, SEQUENCE (product_id, category, unit_price)
  INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON amv_demo_customer_profile
  WITH ROWID, SEQUENCE (customer_id, market, acquisition_channel)
  INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON amv_demo_product_profile
  WITH ROWID, SEQUENCE (product_id, product_line, supplier_tier)
  INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON amv_demo_sales
  WITH ROWID, SEQUENCE (sale_id, customer_id, product_id, sale_date,
                        quantity, amount)
  INCLUDING NEW VALUES;
*/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    tabname => 'AMV_DEMO_CUSTOMERS',
    cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    tabname => 'AMV_DEMO_PRODUCTS',
    cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    tabname => 'AMV_DEMO_CUSTOMER_PROFILE',
    cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    tabname => 'AMV_DEMO_PRODUCT_PROFILE',
    cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    tabname => 'AMV_DEMO_SALES',
    cascade => TRUE);
END;
/

PROMPT === Record the existing AutoMV count ===

VARIABLE before_auto_mv_count NUMBER
BEGIN
  SELECT COUNT(*)
  INTO :before_auto_mv_count
  FROM user_mviews
  WHERE auto = 'YES';
END;
/

PROMPT === Execute 30 tagged five-table workload queries ===

-- Each distinct SQL comment creates a separate workload statement. All 30
-- statements share a five-table, four-join aggregate shape. The joinset
-- pruning default is 4 query blocks, so this gives the advisor repeated
-- query blocks for the same joinset without changing that configuration.
SET TERMOUT OFF

SELECT /* AMV_RECO_Q01 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q02 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q03 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q04 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q05 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q06 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q07 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q08 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q09 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q10 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q11 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q12 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q13 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q14 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q15 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q16 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q17 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q18 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q19 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q20 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q21 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q22 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q23 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q24 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q25 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q26 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q27 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q28 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q29 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SELECT /* AMV_RECO_Q30 */ c.region, cp.market, p.category,
       pp.product_line, SUM(s.amount) total_amount, COUNT(*) sale_count
FROM amv_demo_sales s
JOIN amv_demo_customers c
  ON c.customer_id = s.customer_id
JOIN amv_demo_customer_profile cp
  ON cp.customer_id = c.customer_id
JOIN amv_demo_products p
  ON p.product_id = s.product_id
JOIN amv_demo_product_profile pp
  ON pp.product_id = p.product_id
GROUP BY c.region, cp.market, p.category, pp.product_line;

SET TERMOUT ON

PROMPT === Capture the workload in AUTO_MV_TEST_SET ===

BEGIN
  BEGIN
    DBMS_SQLTUNE.DROP_SQLSET(
      sqlset_name => 'AUTO_MV_TEST_SET',
      sqlset_owner => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE NOT IN (-13754, -13757) THEN
        RAISE;
      END IF;
  END;

  DBMS_SQLTUNE.CREATE_SQLSET(
    sqlset_name => 'AUTO_MV_TEST_SET',
    sqlset_owner => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    description => 'Automatic materialized-view demonstration workload');
END;
/

DECLARE
  l_sqlset_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  OPEN l_sqlset_cursor FOR
    SELECT VALUE(p)
    FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE(
      'parsing_schema_name = ''' ||
      SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') ||
      ''' AND sql_text LIKE ''SELECT /* AMV_RECO_Q%''')) p;

  DBMS_SQLTUNE.LOAD_SQLSET('AUTO_MV_TEST_SET', l_sqlset_cursor);
  CLOSE l_sqlset_cursor;
END;
/

SELECT COUNT(*) AS captured_statement_count
FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET('AUTO_MV_TEST_SET'));

DECLARE
  l_captured_statement_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO l_captured_statement_count
  FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET('AUTO_MV_TEST_SET'));

  IF l_captured_statement_count < 30 THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'Expected at least 30 tagged workload statements; captured ' ||
      TO_CHAR(l_captured_statement_count));
  END IF;
END;
/

PROMPT === Configure and implement AutoMV recommendations ===

-- The explicit IMPLEMENT mode on RECOMMEND controls this run.  This release
-- accepts OFF for the background mode; the broader mode name is not valid.
EXEC DBMS_AUTO_MV.CONFIGURE('AUTO_MV_MODE', 'OFF');
EXEC DBMS_AUTO_MV.CONFIGURE('AUTO_MV_ANALYZE_WORKLOAD_MIN_TIME', 0);
EXEC DBMS_AUTO_MV.CONFIGURE('AUTO_MV_SPACE_BUDGET', 100);
-- _AUTO_MV_ADV_PRUNE_JOINSET_QB_THRESHOLD is intentionally untouched.

VARIABLE auto_mv_execution_name VARCHAR2(200)
BEGIN
  :auto_mv_execution_name := DBMS_AUTO_MV.RECOMMEND(
    sts_owner => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    sts_name => 'AUTO_MV_TEST_SET',
    workload_start_time => CAST(SYSTIMESTAMP - INTERVAL '1' DAY AS TIMESTAMP),
    workload_end_time => CAST(SYSTIMESTAMP + INTERVAL '1' DAY AS TIMESTAMP),
    automv_mode => 'IMPLEMENT');
  DBMS_OUTPUT.PUT_LINE('AutoMV execution: ' || :auto_mv_execution_name);
END;
/

COMMIT;

PROMPT === Generated AutoMV report ===

SELECT execution_name, status, execution_start, execution_end
FROM dba_auto_mv_analysis_executions
WHERE execution_name = :auto_mv_execution_name;

SET LONG 1000000
SELECT recommendations
FROM dba_auto_mv_analysis_recommendations
WHERE execution_name = :auto_mv_execution_name;


set long 1000000
column rep format a240
set tab off
set linesize 250
set trims on
set pagesize 0
set echo off

set termout off
SPOOL auto_mv_report.txt
select DBMS_AUTO_MV.REPORT_ACTIVITY (level=>'ALL') rep from dual;
SPOOL OFF
set termout on

PROMPT === Materialized views created ===

COLUMN owner FORMAT A20
COLUMN mview_name FORMAT A40
SELECT owner, mview_name, refresh_mode, staleness, compile_state, auto
FROM dba_mviews
WHERE owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
  AND (auto = 'YES' OR mview_name LIKE 'AMV%')
ORDER BY owner, mview_name;

PROMPT === Materialized-view logs created ===

COLUMN log_owner FORMAT A20
COLUMN master FORMAT A32
COLUMN log_table FORMAT A32
SELECT log_owner, master, log_table
FROM dba_mview_logs
WHERE log_owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
  AND master LIKE 'AMV_DEMO_%'
ORDER BY master;

DECLARE
  l_after_auto_mv_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO l_after_auto_mv_count
  FROM user_mviews
  WHERE auto = 'YES';

  IF l_after_auto_mv_count <= :before_auto_mv_count THEN
    RAISE_APPLICATION_ERROR(
      -20001, 'DBMS_AUTO_MV.RECOMMEND did not create a new AutoMV');
  END IF;

  DBMS_OUTPUT.PUT_LINE(
    'PASS: created ' ||
    TO_CHAR(l_after_auto_mv_count - :before_auto_mv_count) ||
    ' new automatic materialized view(s)');
END;
/

PROMPT === Final automatic materialized-view count ===
SELECT COUNT(*) AS automatic_materialized_view_count
FROM user_mviews
WHERE auto = 'YES';

EXIT SUCCESS
