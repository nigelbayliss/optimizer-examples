-- information about the quarantined statement
--
column name format a50
select sql_text,name,last_executed,enabled,plan_hash_value from dba_sql_quarantine;
