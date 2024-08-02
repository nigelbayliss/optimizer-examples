set linesize 250
column plan_name format a40
column signature format 999999999999999999999
--
prompt SQL plan baseline data
--
select signature,plan_name,accepted,sql_text
from   dba_sql_plan_baselines 
where  sql_text LIKE 'select /* SPM_TEST_QUERY_Q1 */%';
