# Introduction

Experimental procedure demonstrating the effect of increasing the TABLE_CACHED_BLOCKS preference in DBMS_STATS

The procedure estimates clustering factor for the indexes on a given table. It logically increases 'cached blocks', printing the clustering factor for each value tested. When the clustering factor value bottoms out, there is (arguably) no point increasing the value of cached blocks above that.

# Demo

Run the demo in SQL Plus like this:
<pre>
    SQL> @tab
    SQL> @procedure
    SQL> @test
</pre>

Calling the procedure (see test.sql):
<pre>
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
</pre>

# Disclaimer

   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.


