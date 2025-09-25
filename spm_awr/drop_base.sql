set linesize 200
set verify off
set feedback off
set serveroutput on
column signature format 9999999999999999999999999999
set serveroutput on
column sql_text format a60
column plan_name format a50
accept sig prompt "Enter the SIGNATURE: " 
accept pname char prompt "Enter the PLAN_NAME: " 

prompt
prompt SQL plan baseline(s) for the SQL statement
prompt
select signature, sql_handle, plan_name, accepted, fixed, substr(sql_text,1,55) || '...' sql_text
from  dba_sql_plan_baselines
where signature = &sig;

prompt
prompt Dropping SQL plan baseline...
prompt

declare
  handle    varchar2(100);
  plan_name varchar2(100);
  n         number;
begin
  select count(*)
  into   n
  from   dba_sql_plan_baselines
  where  signature = &sig
  and    plan_name = '&pname';

  if n = 0
  then
     raise_application_error(-20000, 'Cannot find a SQL plan baseline with this SIGNATURE and PLAN_NAME');
  end if;

  select sql_handle
  into   handle
  from   dba_sql_plan_baselines
  where  signature = &sig
  and    plan_name = '&pname';

  n := dbms_spm.drop_sql_plan_baseline(handle,plan_name);
  dbms_output.put_line('Number of SQL plan baselines dropped: '||n);
end;
/

prompt
prompt SQL plan baseline(s) for the SQL statement
prompt
select signature, sql_handle, plan_name, accepted, fixed, substr(sql_text,1,55) || '...' sql_text
from  dba_sql_plan_baselines
where signature = &sig;

