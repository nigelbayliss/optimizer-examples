--
prompt  Wait for Auto SPM task
prompt  We will shorten the interval temporarily to 2mins
prompt  This is NOT recommended, but is done here for the sake of the demo
--
exec dbms_auto_task_admin.modify_autotask_setting('Auto SPM Task', 'INTERVAL', 120);

declare
   lasttime timestamp ;
   thistime timestamp ;
   executed boolean := false;
   sts varchar2(20) := '-';
   n number := 0;
   cursor c1 is
      select last_schedule_time,status
      into   thistime,sts
      from   dba_autotask_schedule_control 
      where  dbid = sys_context('userenv','con_dbid')
      and    task_name = 'Auto SPM Task';
begin
    open c1;
    fetch c1 into lasttime,sts;
    close c1;
    while not executed
    loop 
        open c1;
        fetch c1 into thistime,sts;
        close c1;
        if thistime>lasttime and sts = 'SUCCEEDED' and n > 0
        then
            executed := true;
        else
            dbms_lock.sleep(2);
        end if;
        n := n + 1;
    end loop;
end;
/

--
-- Back to the default
--
exec dbms_auto_task_admin.modify_autotask_setting('Auto SPM Task', 'INTERVAL', 3600);

