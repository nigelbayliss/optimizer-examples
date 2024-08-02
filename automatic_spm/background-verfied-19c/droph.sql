--
-- If we drop the histograms, our SQL statement will pick a bad plan
--
set echo on
exec dbms_stats.delete_column_stats(user,'sales_area1','sale_type',no_invalidate=>false,col_stat_type=>'HISTOGRAM');
exec dbms_stats.delete_column_stats(user,'sales_area2','sale_type',no_invalidate=>false,col_stat_type=>'HISTOGRAM');
