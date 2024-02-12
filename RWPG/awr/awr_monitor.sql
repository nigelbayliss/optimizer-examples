--
--
-- Export AWR repository and SQL Monitor data to import into another database for analysis
--
--
create or replace PACKAGE ADW_MONITOR AS
/* This script will export the awr data and associated sqlmonitor reports to a RWP cloud object store 
You can invoke it in three ways:
    a. Export_AWRDump(from_snap number,to_snap number) - export data between two snapshots
    b. Export_AWRDump_days(numdays number); - export data for the last numdays
    c. Export_AWRDump_dates(from_date date,to_date date); - export data between two dates
    
    So as an example to export all data for the last 8 days:
    From sqlplus
    
    set serveroutput on
    begin
             adw_monitor.Export_AWRDump_days(8);
    end;
    


It works by calculating the to and from snapshots and then
   1. export the awrdump data produced between two snapshots
   3. Copy the sqlmonitor data produced between the two snaps to a set of temporary tables
   4. export the temporary tables - to DATA_PUMP_DIR
   5. Transfer the dump files produced to the object store identified in the procedure (g_uri - url must be modified accordingly)
   6. Remove the files from the DATA_PUMP_DIR directory
   */
/* CHANGE HISTORY 
        25/10/2023 - version 15
	   */

     function Get_Dbid return number;
     function get_pdb_name return varchar2;
     Procedure Export_AWRDump_days(numdays number);
     Procedure Export_AWRDump_dates(from_date date,to_date date);
     -- Takes and end snapshot and produced export dmp files
     PROCEDURE Export_AWRDump(from_snap number,to_snap number);                    -- If required we can run the export AWRdump manually
     PROCEDURE Export_SQLMon(from_snap number,to_snap number);                     -- Similarly we can run the export of sqlmonitors manually
     PROCEDURE  delete_all_files;                                                   -- This will delete ALL files from the DATA_PUMP_DIR directory
     type varchar_array is table of varchar2(255);
     file_list varchar_array:=varchar_array();
	 sqlid_list varchar_array:=varchar_array();
	 PROCEDURE Add_sqlid(p_sqlid varchar2,init boolean default false);
     g_project varchar2(10):='TX';
     PROCEDURE transfer_files ;  
     PROCEDURE put_object(p_file_name varchar2);
	 procedure add_file (p_file_name varchar2);
     -- Replace this URI with a suitable pre-authenticated writeable directory
	 g_uri varchar2(32767):='https://{server}.com/p/.../n/.../b/trace_bucket/o/AWR/';
	 
     g_dbid number;
     g_pdb_name varchar2(128);
     g_file_prefix varchar2(255);
     -- transfers the files in the file_list array to the object store
	 g_version number:=15;
       g_export_sqlmon boolean:=true;
	   g_export_awrdump boolean:=true;
	   g_delete_files boolean:=true;
	   g_proc varchar2(32);
	   g_directory varchar2(32):='DATA_PUMP_DIR';
	   g_use_awrextr boolean:=true;
END ADW_MONITOR;
/
create or replace PACKAGE BODY ADW_MONITOR AS
	   /* LOGGER - stores message in logger table within a new transaction */
     
PROCEDURE LOGGER(p_error_number number, p_error_message varchar2) AS
    Pragma Autonomous_Transaction;
  begin
--  insert into error_log (error_number,error_message,time)
--  values (p_error_number,p_error_message,current_date);
--  commit;
    null;
END LOGGER;
PROCEDURE OUTPUT_LINE (p_line varchar2) AS
begin
    dbms_output.put_line(g_proc||' '||to_char(sysdate,'yyyymmdd:hh24miss')||' version=>'||g_version||' '||p_line);
end;  
PROCEDURE Setup AS
BEGIN
                      /* Generates file prefix based on pdb_name, timestamp and the dbid */
     select name,DBID into g_pdb_name,G_DBID from v$pdbs;
     G_FILE_PREFIX:=g_project||'_'||G_PDB_NAME||'_'||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
     OUTPUT_LINE('INFO: Getting data pdb name=>'||g_pdb_name||' from dbid=>'||G_DBID||' file prefix=>'||G_FILE_PREFIX||' script version=>'||g_version);
	 file_list.trim(file_list.count);
--	 	 sqlid_list.trim(file_list.count);
END Setup;  
PROCEDURE Add_SQLID (p_sqlid varchar2,init boolean default false) IS
BEGIN
       g_proc:='Add_SQLID';
       IF init THEN
	       sqlid_list.trim(sqlid_list.count);
	   end if;
	   sqlid_list.extend(1);
	   sqlid_list(sqlid_list.count):=p_sqlid;
END Add_SQLID;
function get_dbid return number as
begin
      return g_dbid;
end get_dbid;  
function get_pdb_name return varchar2 as
begin
      return g_pdb_name;
end get_pdb_name; 
             /* PUT_OBJECT - copies the file name passed from the g_directory into the Object store bucket */
procedure put_object(p_file_name varchar2) as
begin   
			g_proc:='put_object';
         output_line('INFO: Copying file '||p_file_name||' to '||g_uri||p_file_name);
                 DBMS_CLOUD.PUT_OBJECT (
                credential_name => null
                ,object_uri =>g_uri
				--||p_file_name
                ,directory_name =>g_directory
                ,file_name =>p_file_name);
end put_object;
              /* ADD_FILE - simply adds the file name passed into the file_list array */
procedure add_file (p_file_name varchar2) as
begin
		g_proc:='add_file';
       file_list.extend;
       file_list(file_list.last):=p_file_name;
       output_line('INFO:added file '||p_file_name||' no_files=>'||file_list.count);
end;
              /* DELETE_ALL_FILES - clears out all files in DATA_PUMP_DIR not used in normal processing */
procedure delete_all_files as
     cursor c1 is SELECT * FROM table(dbms_cloud.list_files(g_directory)) ;
begin
 		g_proc:='delete_all_files';
  
     for cur in c1 loop
            dbms_cloud.delete_file(g_directory,cur.object_name);
    end loop;
end;
              /* TRANSFER_FILES - walks through the file_list array and calls put_object to transfer file to block storage
			                      then the file name is deleted by a call to DBMS_CLOUD.DELETE_FILE */
procedure Transfer_files as
        file_name varchar2(255);
begin
       g_proc:='Transfer_files';
       for i in 1..file_list.count loop
                  output_line('INFO: transferring file '||file_list(i));
                put_object(file_list(i));
             begin
			    if g_delete_files then
                   output_line('INFO: deleting file '||file_list(i));
                   dbms_cloud.delete_file(g_directory,file_list(i));
				ELSE
                   	output_line('INFO: NOT deleting file '||file_list(i));			
				end if;   
             exception
                    when others then
                           output_line('WARNING: cannot delete file '||file_list(i));
             end;              
       end loop;
end Transfer_files;

Procedure Export_AWRDump_days(numdays number)
AS
     v_from_snap number;
     v_to_snap number;
begin
    setup;
       g_proc:='Export_AWRDump_days';
    select min(snap_id),max(snap_id)
    into v_from_snap,v_to_snap
    from dba_hist_snapshot
    where trunc(end_interval_time) between trunc(sysdate)-numdays and sysdate
    and dbid=g_dbid;
	
	dbms_output.put_line('INFO: Export_AWRDUMP_DAYS - DBID'||g_dbid||' snapshots selected=>'||nvl(v_from_snap,-1)||' to '||nvl(v_to_snap,-2));
	If v_from_snap is null or v_to_snap is null THEN
	    dbms_output.put_line('ERROR: Export_AWRDUMP_days - No snapshots detected for the last '||numdays||' days please retry');
		RAISE_APPLICATION_ERROR(-20000,'ERROR: Export_AWRDUMP_days - No snapshots detected for the last '||numdays||' days please retry');
	end if;	
	
        Export_AwrDump(v_from_snap,v_to_snap);

end Export_AWRDump_days;
Procedure Export_AWRDump_dates(from_date date,to_date date)
AS
     v_from_snap number;
     v_to_snap number;
begin
       g_proc:='Export_AWRDump_dates';

    setup;
    select min(snap_id),max(snap_id)
    into v_from_snap,v_to_snap
    from dba_hist_snapshot
    where end_interval_time between from_date and to_date
    and dbid=g_dbid;
	
	If v_from_snap is null or v_to_snap is null THEN
	    dbms_output.put_line('ERROR: Export_AWRDUMP_dates - No snapshots detected between '||from_date||' and '||to_date||' please retry');
		RAISE_APPLICATION_ERROR(-20001,'ERROR: Export_AWRDUMP_dates - No snapshots detected between '||from_date||' and '||to_date||' please retry');
	end if;	
	
    Export_AwrDump(v_from_snap,v_to_snap);

end Export_AWRDump_dates;

PROCEDURE Export_AWRDump(from_snap number,to_snap number) AS
        l_filename varchar2(255):=G_FILE_PREFIX||'_awrdump_'||from_snap||'_'||to_snap;
BEGIN
       g_proc:='Export_AWRDump';
    setup;
    If from_snap is null or to_snap is null THEN
	    dbms_output.put_line('ERROR: Export_AWRDUMP - To and from snapshot cannot be null please retry');
		RAISE_APPLICATION_ERROR(-20002,'ERROR: Export_AWRDUMP - To and from snapshot cannot be null please retry');
	end if;	

         setup;
		          file_list.delete;
		 if g_export_awrdump THEN
		            
		     if g_use_awrextr then
			 l_filename:=l_filename||'_extract';
				 output_line('INFO: Exporting awrdump using awrextr from snap=>'||from_snap||' to snap=>'||to_snap||' to_file=>'||l_filename);
				DBMS_WORKLOAD_REPOSITORY.EXTRACT(DMPFILE=>l_filename
							,BID=>FROM_SNAP
							,EID=>TO_SNAP
							,DBID=>G_DBID);
			else				
				l_filename:=l_filename||'_awrexp';
				output_line('INFO: Exporting awrdump using awr_exp from snap=>'||from_snap||' to snap=>'||to_snap||' to_file=>'||l_filename);
				DBMS_WORKLOAD_REPOSITORY.AWR_EXP(DMPFILE=>l_filename
						,BID=>FROM_SNAP
						,EID=>TO_SNAP
						,DMPDIR=>g_directory
						,DBID=>G_DBID);
			end if;			
					add_file(l_filename||'.dmp');
		ELSE
                 output_line('INFO: Not exporting awrdump due to setting');
		END IF;		 
		if g_export_sqlmon then
			Export_SQLMon(from_snap,to_snap);
		end if;
        transfer_files;

END Export_AWRDump;

PROCEDURE Export_SQLMon(from_snap number,to_snap number) AS
   l_dp_handle       NUMBER;
  l_last_job_state  VARCHAR2(30) := 'UNDEFINED';
  l_job_state       VARCHAR2(30) := 'UNDEFINED';
  l_sts             KU$_STATUS;
  l_result          VARCHAR2(30);
  l_is_cdb          NUMBER := 0;
  l_tab_prefix      VARCHAR2(10) := 'DBA';
  l_filename         varchar2(255);
  l_inclause         varchar2(32767);
  l_comma varchar2(1):=' ';
BEGIN
       g_proc:='Export_SQLMon';
	   
	   if sqlid_list.count > 0 THEN
	           l_inclause:=l_inclause||' AND key1 in (';
			for i in 1..sqlid_list.count LOOP
		        l_inclause:=l_inclause||l_comma||''''||sqlid_list(i)||'''';
				l_comma:=',';
			END LOOP;
				l_inclause:=l_inclause||') ';
		end if;		

             output_line('INFO: Exporting sqlmonitor from snap=>'||from_snap||' to snap=>'||to_snap||' to_file=>'||l_filename);
             output_line('INFO: IN Clause '||l_inclause);

  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS PURGE';
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS_DETAILS PURGE';
   EXCEPTION WHEN OTHERS THEN
      NULL;
  END;
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_SQLMON PURGE';
     EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

  BEGIN
    SELECT CASE CDB WHEN 'YES' THEN 1 ELSE 0 END INTO l_is_cdb FROM V$DATABASE;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

    IF l_is_cdb = 1 THEN l_tab_prefix := 'CDB'; END IF;

    EXECUTE IMMEDIATE 'CREATE TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS AS SELECT * FROM '
    ||l_tab_prefix||'_HIST_REPORTS WHERE COMPONENT_NAME = ''sqlmonitor'' '||' and con_dbid = '||g_dbid||l_inclause||
            ' and generation_time between (select min(begin_interval_time) from dba_hist_snapshot where snap_id='||from_snap||')'||
                 '   and (select max(end_interval_time) from dba_hist_snapshot where snap_id='||to_snap||') ';   
	EXECUTE IMMEDIATE 'CREATE TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS_DETAILS AS SELECT * FROM '
		||l_tab_prefix||'_HIST_REPORTS_DETAILS WHERE REPORT_ID IN (SELECT REPORT_ID FROM ADMIN.RWP_AWRDATA_HIST_REPORTS)';
    EXECUTE IMMEDIATE 'create table rwp_sqlmon as '
			||'select sql_id,sid,session_serial#,sql_exec_id,username,SQL_EXEC_START '
			||',dbms_sqltune.report_sql_monitor(sql_id=>sql_id'
                        ||',session_id=>sid,session_serial=>session_serial#,sql_exec_id=>sql_exec_id'
                        ||',type=>''ACTIVE'') sqlmon_report'
                        ||' from V$SQL_monitor where '
                        ||' status like ''DONE%'' '
                        ||' and username is not null and username not like ''SYS%'' '
                        ||' and sql_id is not null';
  l_dp_handle := DBMS_DATAPUMP.open(
    operation   => 'EXPORT',
    job_mode    => 'TABLE',
    remote_link => NULL,
    job_name    => 'RWP_AWRDATA_HIST_REPORTS_01',
    version     => 'LATEST');

   l_filename:=G_FILE_PREFIX||'_RWP_HIST_REPORTS.log';
  DBMS_DATAPUMP.add_file(
    handle    => l_dp_handle,
    filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE,
    filename  => l_filename,
    directory => g_directory);
   add_file(l_filename);

    l_filename:=G_FILE_PREFIX||'_RWP_HIST_REPORTS.dmp';
  DBMS_DATAPUMP.add_file(
    handle    => l_dp_handle,
    filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE,
    filename  => l_filename,
    directory => g_directory);
    add_file(l_filename);


  DBMS_DATAPUMP.metadata_filter(
    handle => l_dp_handle,
    name   => 'SCHEMA_EXPR',
    value  => 'IN (''ADMIN'')');

  DBMS_DATAPUMP.metadata_filter(
    handle => l_dp_handle,
    name   => 'NAME_LIST',
    value  => '''RWP_AWRDATA_HIST_REPORTS'',''RWP_AWRDATA_HIST_REPORTS_DETAILS'',''RWP_SQLMON''');

  DBMS_DATAPUMP.start_job(l_dp_handle);
  DBMS_DATAPUMP.wait_for_job(l_dp_handle, l_result);

  EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS PURGE';
  EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_AWRDATA_HIST_REPORTS_DETAILS PURGE';
  EXECUTE IMMEDIATE 'DROP TABLE ADMIN.RWP_SQLMON PURGE';

END Export_SQLMon;
begin
        setup;
        dbms_output.enable(40000);
		

END ADW_MONITOR;
/
