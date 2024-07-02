set timing on

set echo on
select /* SPM_TEST_QUERY_Q1 */ sum(t2.amount)
from   sales_area1 t1, 
       sales_area2 t2
where  t1.sale_code = t2.sale_code
and    t1.sale_type  = 1;
set echo off

@plan
