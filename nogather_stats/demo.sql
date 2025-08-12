set linesize 150
set tab off
set pagesize 1000
column plan_table_output format a140

drop table t1 purge;

create table t1 (id number, v1 number, v2 number, v3 number, v4 number, v5 number, t varchar2(100));

begin
  for i in 1..100000
  loop
     insert into t1 values (i,mod(i,5000),mod(i,5000),mod(i,5000),mod(i,5000),mod(i,5000),'XXXXXXXXXXXXXXXXXXXX');
  end loop;
end;
/
commit;

create index t1i on t1 (v1,v3,v4);
create index t2i on t1 (v1,v2,v3,v4,t);

exec dbms_stats.gather_table_stats(user,'t1')

var bind1 number
var bind2 number

exec :bind1 := 1
exec :bind2 := 1

select /*+ gather_plan_statistics */ /* EG1 */ sum(v5) from t1 where v1 = 1 and v2 = 1;
--
-- Observe below that the cardinality estimate is accurate. In other words A-Rows equals E-Rows.
-- Note also that index T1I is used
--
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));

--
-- We add new data to the database
--
begin
  for i in 1..10000
  loop
     insert into t1 values (i,mod(i,5),10000,mod(i,5000),mod(i,5000),mod(i,5000),'XXXXXXXXXXXXXXXXXXXX');
  end loop;
end;
/
commit;

--
-- The application now expects the value 10000 to be in the database
-- so we'll change the bind value to retrieve the rows we know to be there
--
-- Note that we have not regathered statstics - they are unchanged
-- In other words, "nothing has changed" other than the data in the database
-- and the values we are retrieving.
--
exec :bind2 := 10000

select /*+ gather_plan_statistics */ /* EG2 */ sum(v5) from t1 where v1 = 1 and v2 = 10000;
--
-- Observe below that the cardinality estimate is NOT accurate. In other words A-Rows doesn't equal E-Rows.
-- Note that the plan has changed: index T2I is now used instead of T1I
--
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));
