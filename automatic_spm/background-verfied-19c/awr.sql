--
prompt Search AWR to confirm we have captured the test query
--
select distinct snap_id,plan_hash_value,buffer_gets_delta 
from DBA_HIST_SQLSTAT 
where sql_id in (select sql_id from dba_hist_sqltext where sql_text like 'select /* SPM_TEST_QUERY_Q1 */%')
order by snap_id;
