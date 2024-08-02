set echo on
--
-- Create two tables with a skewed dataset
--
declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table sales_area1 purge';
exception when ORA_00942 then null;
end;
/

declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table sales_area2 purge';
exception when ORA_00942 then null;
end;
/

create table sales_area1 (sale_code number(10), b varchar2(1000), amount number(10,2), sale_type number(10));


var str VARCHAR2(10)
exec :str := dbms_random.string('u',10);
insert /*+ APPEND */ into sales_area1
select DECODE(parity, 0,rn, 1,rn+1000000), :str, dbms_random.value(1,5), DECODE(parity, 0,rn, 1,10)
from (
    select trunc((rownum+1)/2) as rn, mod(rownum+1,2) as parity
    from (select null from dual connect by level <= 9000)
       , (select null from dual connect by level <= 500)
     );

commit;

create table sales_area2 as select sale_code,b,dbms_random.value(1,3) amount,sale_type from sales_area1;

create index sales_area1i on sales_area1 (sale_code);
create index sales_area2i on sales_area2 (sale_code);

--
-- Gather with histograms
--
@@gatherh
