--
-- show quarantined statements and the execution plan hash value
-- you will see two entries: one that actually triggered the quarantine (the one
-- that was aborted by the resource manager), and one that shows the  avoided
-- executions after the statement was quarantined and not used.
--
set linesize 250 trim on tab off
column sql_text format a50
column sql_quarantine format a50
column plan_hash_value format 999999999999999
select sql_text, plan_hash_value, avoided_executions, sql_quarantine from v$sql where sql_quarantine is not null;
