--
-- For a given SQL ID, parse and create column groups
-- Parameters:
--    SQL ID
--    Y/N - where Y - create column groups immediately
--                N - spool a reation script to verify and run later
--
set long 100000

var create_now varchar2(1)

exec select decode(nvl(upper('&2'),'N'),'N','N','Y') into :create_now from dual;
--
-- This assumes that the parse will complete within 10-1 seconds
--
exec dbms_stats.seed_col_usage(null,null,10)
exec dbms_lock.sleep(1)

DECLARE
  l_sql   CLOB;
  l_cur   INTEGER;
BEGIN
  SELECT sql_fulltext
  INTO   l_sql
  FROM   sys.GV_$SQLAREA
  WHERE  sql_id = '&1'
  AND    ROWNUM = 1;

  l_cur := dbms_sql.open_cursor;

  BEGIN
    dbms_sql.parse(l_cur, l_sql, dbms_sql.native);
    dbms_output.put_line('Parse succeeded');
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Parse failed: ' || SQLERRM);
  END;

  dbms_sql.close_cursor(l_cur);
END;
/

--
-- Create the column groups
--
exec dbms_stats.flush_database_monitoring_info;
exec dbms_lock.sleep(2)

set serveroutput on
declare
  r clob;
  cursor c1 is
    select distinct object_name,object_owner
    from   sys.GV_$SQL_PLAN
    where  object_type = 'TABLE'
    and    sql_id = '&1'
    order by object_name;
begin
  for rec in c1
  loop
     r := dbms_stats.report_col_usage(rec.object_owner,rec.object_name) ;
     dbms_output.put_line('-- ===========================================================');
     dbms_output.put_line('--     Table Name  : '||rec.object_name);
     dbms_output.put_line('/*');
     dbms_output.put_line(r);
     dbms_output.put_line('*/');
     if :create_now = 'Y'
     then
        select dbms_stats.create_extended_stats(rec.object_owner,rec.object_name) into r from dual;
        dbms_output.put_line(r);
     else
        dbms_output.put_line('select dbms_stats.create_extended_stats('''||rec.object_owner||''','''||rec.object_name||''') es from dual;');
     end if;
  end loop;
  dbms_output.put_line('-- === Stats need to be regathered on the following tables');
  for rec in c1
  loop
     -- In theory, we could go ahead and gather stats here rather than just reporting the need.
     dbms_output.put_line('exec dbms_stats.gather_table_stats('''||rec.object_owner||''','''||rec.object_name||''',no_invalidate=>false)');
  end loop;
end;
/
set serveroutput off

