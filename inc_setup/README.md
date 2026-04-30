<h2>Converting a Table to Use Incremental Statstics</h2>

This demonstrates how you can migrate a partitioned table that isn't using incremental statistics management to one that does, without using a "big bang" approach. You can change DBMS_STATS preferences for the relevant table, gather partition-level statistics over a period of time and, finally, gather global-level statistics efficiently using the newly-created synopses.

See example.lst for an example of output from the scripts (when you run then in order i1.sql .. i5.sql).

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

