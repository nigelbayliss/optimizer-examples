create or replace procedure estimate_clustering_factor (
    p_table_name in varchar2,
    p_owner      in varchar2 default user,
    p_sample_pct in number   default 100
) authid current_user
is
    type vc_list is table of varchar2(100) index by pls_integer;
    type num_list is table of number index by pls_integer;
    type int_list is table of pls_integer index by pls_integer;

    l_owner        varchar2(128) := upper(dbms_assert.simple_sql_name(p_owner));
    l_table_name   varchar2(128) := upper(dbms_assert.simple_sql_name(p_table_name));
    l_levels       int_list;
    l_cf           num_list;
    l_lru          vc_list;
    l_order_by     varchar2(32767);
    l_not_all_null varchar2(32767);
    l_sql          varchar2(32767);
    l_col          varchar2(300);
    l_limit        number;
    l_rows_seen    number;
    l_lru_count    pls_integer;
    l_position     pls_integer;
    l_found        boolean;
    l_rid          rowid;
    l_block        varchar2(100);
    l_rc           sys_refcursor;
    l_scaled_cf    number;
begin
    if p_sample_pct <= 0 or p_sample_pct > 100 then
        raise_application_error(-20001, 'p_sample_pct must be in the range 0 < pct <= 100');
    end if;

    l_levels(1) := 1;
    l_levels(2) := 2;
    l_levels(3) := 4;
    l_levels(4) := 8;
    l_levels(5) := 16;
    l_levels(6) := 32;
    l_levels(7) := 64;
    l_levels(8) := 128;
    l_levels(9) := 255;

    dbms_output.put_line(
        'Table: ' || l_owner || '.' || l_table_name ||
        '; sample: ' || p_sample_pct || '%'
    );

    dbms_output.put_line(
        rpad('INDEX', 32) ||
        lpad('CACHE', 8) ||
        lpad('ROWS MEASURED', 16) ||
        lpad('STORED CF', 14) ||
        lpad('MEASURED CF', 16) ||
        lpad('SCALED CF', 16)
    );

    for idx in (
        select i.index_name, i.num_rows, i.clustering_factor
        from all_indexes i
        where i.table_owner = l_owner
          and i.table_name = l_table_name
          and i.index_type = 'NORMAL'
          and i.status = 'VALID'
          and not exists (
              select 1
              from all_ind_columns c
              where c.index_owner = i.owner
                and c.index_name = i.index_name
                and c.column_name like 'SYS_NC%'
          )
        order by i.index_name
    ) loop
        if idx.num_rows is null or idx.num_rows = 0 then
            dbms_output.put_line(
                rpad(idx.index_name, 32) || ' skipped: no index statistics'
            );
            continue;
        end if;

        l_order_by     := null;
        l_not_all_null := null;

        for col in (
            select column_name, descend
            from all_ind_columns
            where index_owner = l_owner
              and index_name = idx.index_name
            order by column_position
        ) loop
            l_col := 't.' || dbms_assert.enquote_name(col.column_name, false);

            l_order_by :=
                case when l_order_by is null then l_col
                     else l_order_by || ', ' || l_col
                end ||
                case when col.descend = 'DESC' then ' desc' else ' asc' end;

            -- A conventional B-tree has no entry if every key column is NULL.
            l_not_all_null :=
                case when l_not_all_null is null then l_col || ' is not null'
                     else l_not_all_null || ' or ' || l_col || ' is not null'
                end;
        end loop;

        l_limit := greatest(1, ceil(idx.num_rows * p_sample_pct / 100));

        /*
          The result is ordered in index-key order. The outer ROWNUM stops
          after the requested percentage of index entries.
        */
        l_sql :=
            'select rid from (' ||
            '  select /*+ index(t "' || idx.index_name ||
            '") no_index_ffs(t "' || idx.index_name || '") */ ' ||
            '         t.rowid rid ' ||
            '  from "' || l_owner || '"."' || l_table_name || '" t ' ||
            '  where (' || l_not_all_null || ') ' ||
            '  order by ' || l_order_by || ', t.rowid' ||
            ') where rownum <= :n';

        l_rows_seen := 0;
        l_lru_count := 0;
        l_lru.delete;

        for n in 1 .. l_levels.count loop
            l_cf(n) := 0;
        end loop;

        open l_rc for l_sql using l_limit;

        loop
            fetch l_rc into l_rid;
            exit when l_rc%notfound;

            l_rows_seen := l_rows_seen + 1;

            l_block :=
                dbms_rowid.rowid_relative_fno(l_rid) || ':' ||
                dbms_rowid.rowid_block_number(l_rid);

            l_found := false;
            l_position := null;

            for n in 1 .. l_lru_count loop
                if l_lru(n) = l_block then
                    l_found := true;
                    l_position := n;
                    exit;
                end if;
            end loop;

            /*
              A miss for a cache size N occurs when the block is absent from
              the LRU, or occurs farther back than position N.
            */
            for n in 1 .. l_levels.count loop
                if not l_found or l_position > l_levels(n) then
                    l_cf(n) := l_cf(n) + 1;
                end if;
            end loop;

            -- Update the 255-entry LRU cache.
            if not l_found then
                if l_lru_count < 255 then
                    l_lru_count := l_lru_count + 1;
                end if;

                for n in reverse 2 .. l_lru_count loop
                    l_lru(n) := l_lru(n - 1);
                end loop;
            else
                for n in reverse 2 .. l_position loop
                    l_lru(n) := l_lru(n - 1);
                end loop;
            end if;

            l_lru(1) := l_block;
        end loop;

        close l_rc;

        for n in 1 .. l_levels.count loop
            if p_sample_pct = 100 then
                l_scaled_cf := l_cf(n);
            else
                l_scaled_cf := l_cf(n) * idx.num_rows / l_rows_seen;
            end if;

            dbms_output.put_line(
                rpad(idx.index_name, 32) ||
                lpad(to_char(l_levels(n)), 8) ||
                lpad(to_char(l_rows_seen), 16) ||
                lpad(to_char(idx.clustering_factor), 14) ||
                lpad(to_char(l_cf(n)), 16) ||
                lpad(to_char(round(l_scaled_cf)), 16)
            );
        end loop;
    end loop;
exception
    when others then
        if l_rc%isopen then
            close l_rc;
        end if;
        raise;
end;
/
