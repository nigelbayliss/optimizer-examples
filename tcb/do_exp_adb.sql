
whenever sqlerror exit

--
-- The relevant SQL_ID here
-- In this case, the statement must be in cursor cache
--
var sqlid varchar2(50)
exec :sqlid := '&1';
--
-- Drop preexisting SPM staging table
--
begin
  execute immediate 'drop table my_spm_staging_tab';
exception 
  when others then null;
end;
/
--
-- TCB bug means we have to export SQL plan baselines manually
-- The bug is identified by the followin error message in the TCB 
-- export log:
--    ORA-39166: Object TCBSTAGE was not found or could not be exported or imported.
--
-- Note! This table is used to export SQL profiles too so they will
--       not be included in the test case export.
--
-- A workaround for the bug is used the SQL statement's parsing 
-- schema to export the test case. I'm assuming that this will
-- not be possible in a production system because the account will
-- not have the required privs.
--     
--
set serveroutput on
declare
  sig_exact number;
  handle varchar2(30);
  n number;
  cursor c1 is 
     select sql_handle
     into   handle
     from   dba_sql_plan_baselines
     where  signature = sig_exact
     and    rownum < 2;
begin
  select dbms_sqltune.sqltext_to_signature(sql_fulltext)
  into   sig_exact
  from   v$sqlarea
  where  sql_id = :sqlid;

  for rec in c1
  loop
     dbms_spm.create_stgtab_baseline('my_spm_staging_tab',null,'SYSAUX');
     n := dbms_spm.pack_stgtab_baseline('my_spm_staging_tab',sql_handle=>handle);
     dbms_output.put_line('Exported '||n||' SQL plan baselines');
  end loop;
end;
/
set serveroutput off
--
-- Now export the test case
--
declare
  tc clob;
begin
-- Directory name must be in upper case
-- We'll export into a ZIP file for ease of use
  dbms_sqldiag.export_sql_testcase(directory=>'SQL_TCB_DIR'      
                                  ,sql_id=>:sqlid
                                  ,testcase=>tc
                                  ,preserveSchemaMapping=>true
                                  ,testcase_name=>'mytestcase'
                                  ,ctrlOptions=>'<parameter name="compress">yes</parameter>');

end;
/
--
-- Manually export the SQL plan baseline data
--
declare
  h1 number;
  job_state varchar2(100);
  sts ku$_Status;
begin
   h1 := DBMS_DATAPUMP.OPEN('EXPORT','TABLE');
   DBMS_DATAPUMP.ADD_FILE(h1,'spm_pack.dmp','SQL_TCB_DIR');
   DBMS_DATAPUMP.START_JOB(h1);

   job_state := 'UNDEFINED';
   while (job_state != 'COMPLETED') and (job_state != 'STOPPED') 
   loop
     dbms_datapump.get_status(h1,
           dbms_datapump.ku$_status_job_error +
           dbms_datapump.ku$_status_job_status +
           dbms_datapump.ku$_status_wip,-1,job_state,sts);
   end loop;
end;
/ 

--
-- Drop SPM staging table
--
begin
  execute immediate 'drop table my_spm_staging_tab';
exception
  when others then null;
end;
/