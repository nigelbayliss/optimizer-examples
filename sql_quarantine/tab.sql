set echo on

drop table fact1 purge;

create table fact1 (a number(10), txt varchar2(1024));

begin
  for i in 1..10
  loop
     insert /*+ APPEND */ into fact1 select i*rownum,
     'XXXXXXXXXXXX'
     from dual connect by rownum < 100000;
     commit;
  end loop;
end;
/
exec dbms_stats.gather_table_stats(user,'fact1');
--
-- Insert an extra row to ensure statistics are not fully up-to-date
-- and statistics-based query transformation is disabled for the table because
-- we want to see raw query transformation
--
insert into fact1 values(1,'ONEROW');
commit;
