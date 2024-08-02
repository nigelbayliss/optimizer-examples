set timing on
--
-- For the purposes if this test, we don't want adaptive plans rescuing the performance
-- regression we induce
--
set echo on
select /* SPM_TEST_QUERY_Q1 */ /*+ NO_ADAPTIVE_PLAN */ sum(t1.amount), sum(t2.amount)
from   sales_area1 t1, 
       sales_area2 t2
where  t1.sale_code = t2.sale_code
and    t1.sale_type  = 10;
set echo off

@plan
