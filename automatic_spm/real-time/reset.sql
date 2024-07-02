DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN

  FOR REC IN (SELECT DISTINCT SQL_HANDLE FROM DBA_SQL_PLAN_BASELINES WHERE sql_text LIKE 'select /* SPM_TEST_QUERY_Q1 */%')
  LOOP
      L_PLANS_DROPPED := DBMS_SPM.DROP_SQL_PLAN_BASELINE (
        sql_handle => rec.sql_handle,
        PLAN_NAME  => NULL);
  END LOOP;

END;
/

exec dbms_sqltune.delete_sqlset(sqlset_name=>'SYS_AUTO_STS',basic_filter=>'sql_text LIKE ''select /* SPM_TEST_QUERY_Q1 */%''',sqlset_owner=>'SYS')

@@flush
