--
-- Create a test table
--

drop table if exists t1;

create table t1 (a number, b number);

begin
  for i in 1..100
  loop
     for j in 1..i
     loop
        insert into t1 values (i,i*2);
     end loop;
  end loop;
end;
/

--
-- No stats are gathered so that dynamic sampling will be used
--
exec dbms_stats.lock_table_stats(user,'t1');
