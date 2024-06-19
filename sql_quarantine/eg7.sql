select name from dba_sql_quarantine;

--
-- Clean-up
--
begin
  for quarantineObj in (select name from dba_sql_quarantine) loop
    sys.dbms_sqlq.drop_quarantine(quarantineObj.name);
  end loop;
end;
/

select name from dba_sql_quarantine;
