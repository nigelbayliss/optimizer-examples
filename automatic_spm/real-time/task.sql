set pagesize 1000
set linesize 250
set trims on
column task_name format a30

select current_timestamp now from dual;


select task_name, interval,status, last_schedule_time, systimestamp-last_schedule_time ago 
from dba_autotask_schedule_control 
where dbid = sys_context('userenv','con_dbid')
and (task_name = 'Auto STS Capture Task'
     or
     task_name = 'Auto SPM Task');
