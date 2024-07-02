--
-- We are going to manipulate parameters to induce SQL performance issues
-- In this case, we'll induce a poor plan by adjusting the index cost
--
alter session set optimizer_index_cost_adj = 10000
/
