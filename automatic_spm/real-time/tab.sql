set echo on
--
-- Create two tables
--
set echo on
drop table if exists sales_area1 purge;
drop table if exists sales_area2 purge;

create table sales_area1 (sale_code number(10), b varchar2(2000), amount number(10,2), sale_type number(10), c varchar2(1000));


var str VARCHAR2(1200)
exec :str := dbms_random.string('u',2000);
var str2 VARCHAR2(1200)
exec :str2 := dbms_random.string('u',10);
insert /*+ APPEND */ into sales_area1
select mod(rn,1000), :str, rn/1000, mod(rn,100),:str2
from (
    select trunc((rownum+1)/2) as rn, mod(rownum+1,2) as parity
    from (select null from dual connect by level <= 4000)
       , (select null from dual connect by level <= 500)
     );

commit;

create table sales_area2 as select sale_code,b,rownum/1000 amount,sale_type,c from sales_area1;

create index sales_area1i on sales_area1 (sale_code);
create index sales_area2i on sales_area2 (sale_code);
create index sales_typ1i on sales_area1 (sale_type);
create index sales_typ2i on sales_area2 (sale_type);
--
-- Gather statistics (without histograms for the purposes of this test)
--
exec dbms_stats.gather_table_stats(user,'sales_area1',method_opt=>'for all columns size 1',no_invalidate=>false)
exec dbms_stats.gather_table_stats(user,'sales_area2',method_opt=>'for all columns size 1',no_invalidate=>false)

