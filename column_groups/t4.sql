--
-- We need to gather statistcs on the column groups for them
-- to be useful. 
--
spool t4
set echo on

--
-- One way of gathering extended stats
--
@@gather_ext
--
-- Alternatively you can do this
--
--exec dbms_stats.gather_table_stats(user,'tab_corr1',no_invalidate=>false);
--exec dbms_stats.gather_table_stats(user,'tab_corr2',no_invalidate=>false);

--
-- Expose the next query to the column group statistics
-- and the cardinality estimate will be correct (1000)
--

select /* MY_TEST_QUERY */ /*+ GATHER_PLAN_STATISTICS */ sum(b.n0),count(*)
from  tab_corr1 a, tab_corr2 b
where a.n1 = 1
and   a.n2 = 1
and   a.n1 = b.n1
and   a.n2 = b.n2;

@@plan

spool off
