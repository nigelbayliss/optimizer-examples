--
-- Purge AWR to remove test queries - this resets the test
--
declare
  n1 number;
  n2 number;
  cursor c1 is select min(snap_id),max(snap_id)
               from   dba_hist_snapshot
               where  begin_interval_time > sysdate - 5
               and    dbid = sys_context('userenv','con_dbid');
begin
  open c1;
  fetch c1 into n1,n2;
  close c1;
  if n1 is not null
  then
     dbms_workload_repository.drop_snapshot_range(n1,n2);
  end if;
end;
/
