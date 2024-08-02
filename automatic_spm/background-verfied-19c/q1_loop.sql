--
-- Execute the test query multiple times so it gets into AWR
--
set timing on

declare
   n1 number;
   n2 number;
begin
   for i in 1..&1
   loop
     execute immediate 'select /* SPM_TEST_QUERY_Q1 */ /*+ NO_ADAPTIVE_PLAN */ sum(t1.amount), sum(t2.amount) from sales_area1 t1, sales_area2 t2 where t1.sale_code = t2.sale_code and t1.sale_type  = 10' into n1,n2;
   end loop;
end;
/
