--
-- Pick a non default value that will nevertheless give us a good plan
--
alter session set optimizer_index_cost_adj = 90
/
