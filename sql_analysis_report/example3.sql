--
-- Locate problem SQL statements in the cursor cache
--
column sql_text format a170

select distinct sql_id,child_number,sql_text 
from  v$sql a, 
      table(DBMS_XPLAN.DISPLAY_CURSOR(sql_id=>a.sql_id)) b 
where b.plan_table_output like '%use as keys in index range scan%'
and   sql_text like '%products%'
order by sql_id,child_number
/
