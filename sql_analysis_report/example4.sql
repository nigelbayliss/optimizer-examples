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

var bind1 varchar2(20)

exec :bind1 := '%X%'

set linesize 200
set tab off
set trims on
set pagesize 1000
column plan_table_output format a180

--
prompt LIKE example that can't be used in a range scan
--
select t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid 
and   t4.carrier   like '%X%';
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

--
prompt Can be used in range scan
--
select t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid
and   t4.carrier   like 'X%';
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

--
prompt Works with bind values too
--
select t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid
and   t4.carrier   like :bind1;
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

--
prompt Sees previous bind value (no reparse): '%X%'
--
exec :bind1 := 'X%'

select t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid
and   t4.carrier   like :bind1;
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

--
prompt Sees new bind value (new SQL statement parsed): 'X%'
--
select /* 2 */ t3.p_category, t4.tpmethod
from products t3, sources t4
where t3.scid = t4.scid
and   t4.carrier   like :bind1;
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

