var sig number
set linesize 200
set verify off
set feedback off
set serveroutput on
column signature format 9999999999999999999999999999
column sql_text format a60
column plan_name format a40
accept sqlid char prompt "Enter the SQL ID: " 
accept phv number prompt "Enter the plan hash value: "

prompt 
prompt This is the SIGNATURE of the SQL statement (used by the SQL plan baselines)
prompt 
select dbms_sqltune.sqltext_to_signature(sql_text) signature
from   dba_hist_sqltext
where  sql_id = '&sqlid'
and    rownum < 2;

prompt
prompt An AWR SNAP ID for the SQl statement
prompt
select max(snap_id) snap_id
from   dba_hist_sqlstat
where  sql_id = '&sqlid'
and    plan_hash_value = &phv;

prompt 
prompt Loading the plan from AWR
prompt
declare
   bsnap number;
   esnap number;
   bcount number;
   awrcount number;
begin
   select max(snap_id)
   into   esnap
   from   dba_hist_sqlstat
   where  sql_id = '&sqlid'
   and    plan_hash_value = &phv;

   select max(snap_id)
   into   bsnap
   from   dba_hist_snapshot
   where  snap_id < esnap;

   if esnap is null
   then
      raise_application_error(-20000, 'This SQLID/PLAN_HASH_VALUE combination is not in AWR');
   end if;

   dbms_output.put_line('Begin snapshot: '||bsnap);
   dbms_output.put_line('End snapshot: '||esnap);

   select dbms_sqltune.sqltext_to_signature(sql_text) signature
   into   :sig
   from   dba_hist_sqltext
   where  sql_id = '&sqlid'
   and    rownum < 2;

   bcount := dbms_spm.load_plans_from_awr(
     begin_snap => bsnap,
     end_snap   => esnap,
     fixed      => 'YES',
     basic_filter => 'sql_id = ''&sqlid'' and plan_hash_value = &phv');

   dbms_output.put_line('Baselines created: '||bcount);
end;
/

prompt
prompt SQL plan baseline(s) for the SQL statement
prompt
select signature, sql_handle, plan_name, accepted, fixed, substr(sql_text,1,55) || '...' sql_text
from  dba_sql_plan_baselines
where signature = :sig;

   


