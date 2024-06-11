set define on
--
-- Set "container" to your container name
--
define container = 'cdb1_pdb1'

connect / as sysdba
alter session set container = &container;
drop user if exists u1 cascade;
drop user if exists u2 cascade;

grant connect, resource, unlimited tablespace to u1 identified by "u1_Pass#";
grant connect, resource, unlimited tablespace to u2 identified by "u2_Pass#";

connect u1/"u1_Pass#"@&container
drop table if exists emp purge;
drop table if exists dept purge;

create table emp as 
select rownum empid, mod(rownum,1000) sal, 'CLERK' job, mod(rownum,10) deptno
from dual connect by rownum<=1000
;

create table dept as 
select mod(rownum,10) deptno, 'CLERK' job,  'DALLAS' loc
from dual connect by rownum<=10
;

create or replace view e_view as select * from emp where job = 'CLERK';
create or replace view d_view as select * from dept where loc = 'DALLAS';

grant select on emp to u2;
grant select on dept to u2;
grant select on e_view to u2;
grant select on d_view to u2;

connect u2/"u2_Pass#"@&container

create function f2 (x in number) return number
as
begin
   return (x);
end;
/

prompt ====
prompt ==== NO view merging is allowed by default
prompt ====
explain plan for
select ev.* from u1.e_view ev, u1.d_view dv
where ev.deptno=dv.deptno and f2(ev.sal)=1000 and f2(dv.loc)='DALLAS';

column plan_table_output format a100
set linesize 50
set tab off
set pagesize 1000

select * from table(dbms_xplan.display(format=>'basic'));

connect u1/"u1_Pass#"@&container
-- Granting merge view to E_VIEW
grant merge view on e_view to u2;
connect u2/"u2_Pass#"@&container

explain plan for
select ev.* from u1.e_view ev, u1.d_view dv
where ev.deptno=dv.deptno and f2(ev.sal)=1000 and f2(dv.loc)='DALLAS';

prompt ====
prompt ==== View merging priviledges on E_VIEW only
prompt ====
select * from table(dbms_xplan.display(format=>'basic'));

connect u1/"u1_Pass#"@&container
-- Granting merge view to D_VIEW
grant merge view on d_view to u2;
connect u2/"u2_Pass#"@&container

prompt ====
prompt ==== View merging priviledges on D_VIEW and E_VIEW
prompt ====
explain plan for
select ev.* from u1.e_view ev, u1.d_view dv
where ev.deptno=dv.deptno and f2(ev.sal)=1000 and f2(dv.loc)='DALLAS';

select * from table(dbms_xplan.display(format=>'basic'));

connect u1/"u1_Pass#"@&container
-- Revoke merge view
revoke merge view on d_view from u2;
revoke merge view on e_view from u2;
connect u2/"u2_Pass#"@&container

prompt ====
prompt ==== View merging priviledges revoked
prompt ====
explain plan for
select ev.* from u1.e_view ev, u1.d_view dv
where ev.deptno=dv.deptno and f2(ev.sal)=1000 and f2(dv.loc)='DALLAS';

select * from table(dbms_xplan.display(format=>'basic'));

prompt ====
prompt ==== View merging priviledges granted for any view
prompt ====
connect / as sysdba
alter session set container = &container;
-- Grant merge any view to U2
grant merge any view to u2;
connect u2/"u2_Pass#"@&container

explain plan for
select ev.* from u1.e_view ev, u1.d_view dv
where ev.deptno=dv.deptno and f2(ev.sal)=1000 and f2(dv.loc)='DALLAS';

select * from table(dbms_xplan.display(format=>'basic'));
