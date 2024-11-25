--
-- Wait for the Auto SQL Tuning Set Capture Task
--
prompt Waiting for Auto SQL Tuning Set Capture...
prompt By defauult, this is 15mins, but we'll temporarilty shorten it to two mins speed things up
--
exec dbms_auto_task_admin.modify_autotask_setting('Auto STS Capture Task', 'INTERVAL', 120)
--
@@task
declare
   lasttime timestamp ;
   thistime timestamp ;
   executed boolean := false;
   sts varchar2(20) := '-';
   cursor c1 is
      select last_schedule_time,status
      into   thistime,sts
      from   dba_autotask_schedule_control 
      where  dbid = sys_context('userenv','con_dbid')
      and    task_name = 'Auto STS Capture Task';
begin
   while sts != 'RUNNING'
   loop
      open c1;
      fetch c1 into lasttime,sts;
      close c1;
   end loop;
   while not executed
   loop 
      open c1;
      fetch c1 into thistime,sts;
      close c1;
      if thistime>lasttime and sts = 'SUCCEEDED'
      then
         executed := true;
      else
         dbms_lock.sleep(2);
      end if; 
   end loop;
end;
/
--
@@task
--
-- Back to the default
--
exec dbms_auto_task_admin.modify_autotask_setting('Auto STS Capture Task', 'INTERVAL', 900)
