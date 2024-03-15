--
--
-- Procedure to load a specific SQL_ID, PLAN_HASH_VALUE into the SQL plan baseline
-- 
-- Usage:
--   set serveroutput on
--   exec load_spm (sql_id,phv)
--
-- Create the procedure in a DBA account with access granted to DBA_HIST_SNAPSHOT and DBA_SQLSET
--
--
create or replace procedure load_spm (sqlid varchar, phv number) as
   n number;
   cursor snp is
      select min(snap_id) mi,max(snap_id) mx
      from dba_hist_snapshot 
      where instance_number = sys_context('USERENV','INSTANCE');
   cursor ts is
      select name,owner from dba_sqlset;
begin
   n := dbms_spm.load_plans_from_cursor_cache(sqlid,phv);
   if n = 0
   then
      for rec in snp
      loop
          n := dbms_spm.load_plans_from_awr(rec.mi,rec.mx,'sql_id = '''||sqlid||''' and plan_hash_value = '||phv);
      end loop;
      if n = 0
      then
         for rec in ts
         loop
            n := dbms_spm.load_plans_from_sqlset(rec.name,rec.owner,'sql_id = '''||sqlid||''' and plan_hash_value = '||phv);
            if n != 0
            then
               dbms_output.put_line('Plan loaded from sqlset '||rec.name); 
               exit;
            end if;
         end loop;
         if n = 0
         then
            dbms_output.put_line('Plan not found');
         end if;
      else
         dbms_output.put_line('Plan loaded from AWR');
      end if;
   else
      dbms_output.put_line('Plan loaded from cursor cache');
   end if;
end;
/

show errors
