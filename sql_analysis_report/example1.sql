drop table products purge;
drop table sources purge;

create table products (p_category varchar2(100), tpmethod varchar2(100), prod_category varchar2(100), method_typ varchar2(100),scid varchar2(10), tp varchar2(100));
create table sources (p_category varchar2(100), tpmethod varchar2(100), scid varchar2(100),carrier varchar2(100), s_area char(4));

create index prod_cat_idx on products(prod_category);
create index prod_mtyp_idx on products(method_typ);
create index src_carr_idx on sources(carrier);
create index s_area_idx on sources (s_area);

insert into products values('A','B','C','D','E','F');
insert into sources values('A','B','C','D',1);

begin
  for i in 1..10
  loop
     insert into products select * from products;
     insert into sources select p_category,tpmethod,scid,rownum*i,i from sources;
  end loop;
end;
/
commit;

exec dbms_stats.gather_table_Stats(user,'sources')
exec dbms_stats.gather_table_Stats(user,'products')

--
-- The bind variable is the wrong type for the query
-- since s_area is CHAR(4)
--
var bind1 number
exec :bind1 := 1

select t1.p_category, t2.tpmethod 
from products t1, products t2
where t1.prod_category || '_1' = 'SFD_1'
and   t2.method_typ != 'SEA'
union
select t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid 
and   t4.carrier   = 'AAC'
and   t4.s_area    = :bind1;

set linesize 200
set tab off
set trims on
set pagesize 1000
column plan_table_output format a180

SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

