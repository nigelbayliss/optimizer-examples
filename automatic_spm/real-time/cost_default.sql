--
-- Switch back to the default and we'll get a better plan
--
alter session set optimizer_index_cost_adj = 100
/
