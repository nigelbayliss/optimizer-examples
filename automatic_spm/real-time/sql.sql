set linesize 250
set pagesize 1000
column txt format a100
column sql_plan_baseline format a50

select substr(sql_text,1,100) txt,executions
from   v$sqlstats
where sql_text like 'select /* SPM_TEST_QUERY_Q1 */%'
;
