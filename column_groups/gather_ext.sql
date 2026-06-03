--
-- Gathers statistics on
-- extended statistics that don't yet have stats
--
set serveroutput on
declare
   cursor ext is
      select a.table_name,a.extension
      from   user_stat_extensions a,
             user_tab_col_statistics b
      where  a.table_name = b.table_name (+)
      and    a.extension_name = b.column_name (+)
      and    b.last_analyzed is null
      order by table_name;
   cmd varchar2(4096);
begin
   for rec in ext
   loop
      cmd := 'begin  dbms_stats.gather_table_stats(user,'''||rec.table_name||''',method_opt=>''for columns '||rec.extension||''',no_invalidate=>false); end;';
      dbms_output.put_line(cmd);
      execute immediate cmd;
   end loop;
end;
/
set serveroutput off
