--
-- Create a simple package containing three functions
-- fnum returns the value passed in as a parameter
-- fnum2 returns twice the value passed in as a parameter
-- ftab returns a table with N rows (where N is a parameter)
-- fpipe returns a pipelined table with N rows (where N is a parameter)
--
drop package ds_test;
drop type num_tab;
drop type num_row;

create type num_row as object (
  n number);
/

create type num_tab as table of num_row;
/


create or replace package ds_test as
  function fnum (p_n in number) return number deterministic;
  function fnum2 (p_n in number) return number deterministic;
  function ftab (p_rows in number) return num_tab deterministic;
  function fpipe (p_rows in number) return num_tab pipelined deterministic;
end ds_test;
/

show errors


create or replace package body ds_test as

  function fnum (p_n in number) return number  deterministic is
  begin
     return p_n;
  end;

  function fnum2 (p_n in number) return number  deterministic is
  begin
     return p_n*2;
  end;

  function ftab (p_rows in number) return num_tab deterministic is
     t num_tab := num_tab();
  begin
     for i in 1..p_rows
     loop
         t.extend;
         t(t.last) := num_row(i);
     end loop;
     return t; 
  end;

  function fpipe (p_rows in number) return num_tab pipelined deterministic is
     t num_tab := num_tab();
  begin
     for i in 1..p_rows
     loop
        pipe row(num_row(i));
     end loop;
     return;
  end;

end ds_test;
/

show errors

create or replace function top_level(p_n number)  return number deterministic as
begin
   return p_n;
end;
/
show errors

select ds_test.fnum(20) from dual;
select ds_test.fnum2(20) from dual;
select * from table(ds_test.ftab(5));
select * from table(ds_test.fpipe(5));
