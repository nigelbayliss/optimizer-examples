set linesize 250
set pagesize 1000
column txt format a100
column sql_plan_baseline format a50
column exact_matching_signature format 999999999999999999999999999

--
-- For real-time SPM to kick in, the initial plan must be captured in the
-- automatic SQL tuning set. The following query will return a row if the
-- SQL statement has been captured.
--
select substr(sql_text,1,100) txt,executions,decode(executions,0,-1,round(buffer_gets/executions)) bget_per_exec,plan_hash_value,exact_matching_signature
from dba_sqlset_statements 
where sqlset_name = 'SYS_AUTO_STS' 
and sql_text like 'select /* SPM_TEST_QUERY_Q1 */%'
order by 3;
