set serveroutput on
set linesize 200

begin
  estimate_clustering_factor  
  (
    p_table_name => 'T1',
    p_owner      => user,
    p_sample_pct => 100
  );
end;
/

begin
  estimate_clustering_factor
  (
    p_table_name => 'T1',
    p_owner      => user,
    p_sample_pct => 50
  );
end;
/

