column index_name format a30

drop table t1;

create table t1
(
  group_id  number       not null,
  bucket_no number       not null,
  row_no    number       not null,
  index_key number       not null,
  pad       varchar2(4000) not null,
  constraint t1_pk primary key (group_id, bucket_no, row_no)
)
pctfree 0;

declare
  l_block_size integer;
  l_pad_length integer;
  l_unused     varchar2(4000);
  l_return     integer;
begin
  -- Roughly five rows per data block on ordinary block sizes.  The cap keeps
  -- the table compatible with databases using MAX_STRING_SIZE=STANDARD.
  l_return := dbms_utility.get_parameter_value('db_block_size', l_block_size, l_unused);
  l_pad_length := least(3500, greatest(200, floor(l_block_size * .18)));

  -- Keep this serial, nested-loop insert: its order is intentional.
  for g in 1 .. 16 loop
    for b in 1 .. 16 loop
      for r in 1 .. 8 loop
        insert into t1
          (group_id, bucket_no, row_no, index_key, pad)
        values
          (g, b, r, ((b - 1) * 8 + r) * 100 + g,
           rpad('x', l_pad_length, 'x'));
      end loop;
    end loop;
  end loop;
  commit;
  dbms_output.put_line('DB_BLOCK_SIZE=' || l_block_size ||
                       ', pad length=' || l_pad_length ||
                       ', rows=2048');
end;
/

create index t1_ix on t1(index_key);

select blocks from user_segments where segment_name = 'T1';
select 2048/blocks rows_per_block from user_segments where segment_name = 'T1';

select count(distinct rownum) from t1 where index_key = 9001;

exec dbms_stats.set_table_prefs(user, 'T1', 'TABLE_CACHED_BLOCKS', '32')
exec dbms_stats.gather_table_stats(user, 'T1', method_opt=>'FOR ALL COLUMNS SIZE 1', cascade=>true)

select index_name, num_rows, clustering_factor,
       round(clustering_factor / nullif(num_rows,0), 3) cf_per_index_row
from   user_indexes
where  table_name = 'T1'
order  by index_name;

exec dbms_stats.set_table_prefs(user, 'T1', 'TABLE_CACHED_BLOCKS', '1')
exec dbms_stats.gather_table_stats(user, 'T1', method_opt=>'FOR ALL COLUMNS SIZE 1', cascade=>true)

select index_name, num_rows, clustering_factor,
       round(clustering_factor / nullif(num_rows,0), 3) cf_per_index_row
from   user_indexes
where  table_name = 'T1'
order  by index_name;
