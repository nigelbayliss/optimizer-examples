set linesize 250
set trims on
set tab off
set tab off
set pagesize 1000
column plan_table_output format a130

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(SQL_HANDLE=>'SQL_2044b318726d1c30',FORMAT=>'TYPICAL'));
set echo on
