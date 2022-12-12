# OLTP Query Optimization Considerations

A RDBMS takes the declarative SQL text and creates a procedural execution plan which attempts to retrieve the data as efficiently as possible. The query optimizer is one of the most complex parts of the engine.

## Reading data
Typically the optimizer has two main options, scan the entire table (heap) or use an index (secondary data structure) to locate a pointer to the data in the heap.

If the index includes all the columns required to satisfy the query then the engine will be able to gather the data directly from the index without requiring the lookup to the heap.

### Table scans
Scanning is a simple look at each row in the table, fetch the blocks, apply any filter or condition to discard rows which don't match the filter or condition. Scanning a large table can be expensive and the cost is based on the number of rows in the table. 

There are cases where a table scan is more efficient than using an existing index, usually these situations involve a non-selective query which will fetch a large proportion of the table, in this case the optimizer may choose to scan the entire table rather than add the cost of reading the index and then completing the heap lookup. A similar situation is a small table where scanning the entire table is more cost effective. If you are seeing the optimizer choosing a full table scan you should consider why, does the query return a large proportion of the table (num_of_rows_returned / total_num_rows)? Does an index exist for the columns in the WHERE or JOIN clauses?

### Index scans
An index scan involves finding the pointer to the row(s) in the heap  by scanning through an index and find matching keys. Columns used in WHERE and JOIN conditions are good candidates for indexes if the column is regularly used for filtering or joining. Indexes are not free, they require increased storage since they contain a copy of data from the heap and they require resources to keep them up-to-date and maintain them. 

#### Index types

##### B-tree
These are the default and most-common types of indexes, the data in the index is ordered based on the indexed column which can make searching for a record faster. In a balanced tree, the root of the index should split the range of values that the index stores, this splitting continues on the sub-trees until reaching the bottom of the tree. B-tree indexes are best for columns with a high-cardinality (aka a large number of distinct values). A b-tree index can be rebalanced as the index is updated by changes to the table. A b-tree can be used for an equality condition, a non-equality condition or a range condition.

Ref: 
https://postgrespro.com/blog/pgsql/4161516
https://www.postgresql.org/docs/current/btree.html
https://github.com/postgres/postgres/tree/master/src/backend/access/nbtree
https://github.com/postgres/postgres/blob/d16773cdc86210493a2874cb0cf93f3883fcda73/src/backend/access/nbtree/nbtsearch.c#L73

##### Bitmap
Postgres doesn't support creating bitmap indexes but the optimizer will create bitmaps via bitmap scans automatically. Usually a bitmap index is useful when the column has a low cardinality and doing filters using AND, OR and NOT operations. The optimizer can switch to a bitmap scan to prevent having to read the same heap page multiple times, this can occur when the number of rows being retrieved increases so an index scan is not optimal while a table scan is also sub-optimal.  A bitmap scan will typically read the index and build a bitmap via a "Bitmap index scan", then the rows are read from the heap via a "Bitmap heap scan". 

A Bitmap scan can be "lossy" and require a "recheck" condition. This can occur when the bitmap is too large to fit in memory, if you are seeing "recheck" conditions you might be able to improve performance by increasing "work_mem" for the query. 

Ref:
https://pganalyze.com/docs/explain/scan-nodes/bitmap-index-scan
https://postgrespro.com/blog/pgsql/3994098
https://github.com/postgres/postgres/blob/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/executor/nodeBitmapIndexscan.c
https://github.com/postgres/postgres/blob/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/executor/nodeBitmapHeapscan.c


##### Hash 
A hash index is created using a hashing function to uniquely identify a record in the index. Hash indexes can only be used for equality operators and can be efficient for heavy SELECT and UPDATE workloads on large heaps. The reason for this is that as the heap becomes large a b-tree index will also be larger and take longer to scan through, a hash-index can be smaller and is especially efficient if the hash index can fit in memory. A high cardinality column is best for a hash index, if your index contains columns which are low cardinality you may be able to improve the efficiency by using partial indexes to improve the cardinality artificially in the index.

Ref:
https://www.postgresql.org/docs/current/hash-intro.html
https://postgrespro.com/blog/pgsql/4161321
https://github.com/postgres/postgres/tree/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/access/hash


##### GIN
A generalized inverted index is typically a good candidate for full-text searching. A GIN index can be larger than a GiST index and therefore take longer to build however the GIN index can work on multiple filter operators unlike b-tree or GiST. Since the build time for GIN can be high, you may want to increase the maintenance_work_mem for the session building the index. Updates on GIN indexes can also be slow, therefore GIN offers a "fastupdate" storage option, this allows updates to be stored unordered in special pages and the updates be applied as a bulk operation when vacuum runs or when the list is larger than the "gin_pending_list_limit". This can improve update performance, performing a single update for every change is expensive. The downside to "fastupdate" is that searching through the index can be slower since the unordered pages need to be scanned through in addition to the index.

Ref:
https://www.postgresql.org/docs/current/gin-tips.html
https://postgrespro.com/blog/pgsql/4261647
https://github.com/postgres/postgres/tree/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/access/gin

##### GiST
A generalized search tree index is a balanced search tree. It can be leveraged as a framework for building other indexes such as R-trees. 

Ref:
https://www.postgresql.org/docs/current/gist-intro.html
https://postgrespro.com/blog/pgsql/4175817
https://github.com/postgres/postgres/tree/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/access/gist

##### SP-GiST
A "space partitioned" GiST index is a non-balanced index to support searching partitioned tree searches. 

Ref:
https://www.postgresql.org/docs/current/spgist.html
https://postgrespro.com/blog/pgsql/4220639
https://github.com/postgres/postgres/tree/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/access/spgist

##### BRIN
A block range index is useful with very large heaps where the block range is a group of pages that are physically adjacent in the heap, they rely on bitmap scans and are therefore "lossy". A good candidate column could be a column where the data is naturally ordered and increasing or decreasing without the need to use ORDER BY or an ordered index. 

Ref: 
https://www.postgresql.org/docs/current/brin-intro.html
https://postgrespro.com/blog/pgsql/5967830
https://github.com/postgres/postgres/tree/c35ba141de1fa04373671ba24c73eb0fe4862415/src/backend/access/brin

## Joining data
Joins are required when two or more tables store related data but data that should be stored independently, for example customer vs orders. Typically a customer identifier will be a column in a customer table whilst the orders table can have a foreign key for customer_id which points to the customer_id column in the customer table. If we need to find all order for a particular customer we can join the customer and orders table using the shared customer_id column to find matches. The optimizer can satisfy a join using three methods, nested loops, hash joins and sort merge joins.

### Join types

#### Inner join
The inner join returns rows from both tables as long as they both have a matching key, this is also known simply as a JOIN. For example these two queries are the same. If possible an inner join is normally most-efficient.

``` SELECT customer_name, order_status FROM customer AS c INNER JOIN orders AS o on c.customer_id = o.customer_id```

``` SELECT customer_name, order_status FROM customer AS c JOIN orders AS o on c.customer_id = o.customer_id``` 

#### Left outer join
The left out join returns all rows from the left table (this is literally the left most table in the query) and also returns rows from the right table that have a matching key. Rows returned from the left table with no matching key in the right table will have null values in place of the missing values from the right table.

#### Right outer join
The right outer join returns all rows from the right table and also returns rows from the left table that have a matching key. Rows returned from the right table with no matching key in the left table will have null values in place of the missing values from the left table.

#### Full outer join
A full outer join returns all rows from both table, if there isn't a matching key in one of the tables the missing column returns a null value.

#### Join methods
 - Less efficient - Nested loops are good when the outer table is small, you can improve nested loop performance by indexing the join keys for the inner table
 - Medium efficiency - Hash joins - are good when the hash table is small enough to fit into work_mem
 - More efficient - Merge join - are good when both tables are large, improve efficiency by indexing joins columns on both tables

##### Nested loops
Nested loops work on any join that uses an equality, inequality or range operation. A nested loop runs two loops, an outer loop over the driver table and an inner loop over the other table. A nested loop scans through all the matching rows in the outer heap and then scans through the innner heap looking for a match. A nested loop is suitable when the number of rows on the outer heap is small and there is an index on the join column on the inner heap, this allows an index lookup for the small set from the outer table. As the number of rows in the outer table grows the nested loop can become quickly inefficient. 

##### Hash joins
A hash join hashes the values in the smaller table to create a hash table, this is known as the inner table, the outer table or the larger table is then scanned through looking for matches in the hash table. Hash joins can only work on equality operators. Hash joins can be efficient when none of the tables are smaller but the hash table is small enough to fit in "work_mem", therefore increassing the work_mem for the query can help. If the hash table is too large to fit in work_mem the hash table will spill to temp files on disk and therefore suffer decreased performance.

##### Merge joins
A merge join works on equility operations and then sorts the tables using the join keys. A merge join is usually the best options for joining two large tables where the hash table would be too large to fit into work_mem for a hash join. A merge then scans through both sorted lists to find a matching row. An index on the join columns for both tables may improve merge join performance if the optimizer can scan the index. 

## General tips for selecting data efficiently
 - Create indexes on columns used regularly in JOIN and WHERE clauses
 - Use of covering indexes can improve performance since all the data can be read from the index and avoiding the lookup in the heap
 - Avoid colA = NULL prefer colA IS NULL
 - Avoid functions in WHERE clauses unless you have created  a functional index
 - Frr range scans keep the range as small as possible
 - Avoid using wildcards at the start of the string in LIKE operations, LIKE '%TEST' cannot use an index but LIKE 'TEST%' can use an index.
 - If you are seeing an expensive SORT operation consider creating an index on the column used for ORDER BY as this will remove the SORT operation
 - Avoid casting data, use the correct data types in the column definition
 - Consider using meterialized views to pre-compute expensive select queries at the cost of having stale data between refreshes

### Partitioning
Partitioning can be beneficial to break very large tables up into smaller tables. A very large table can be difficult to efficiently query as a very large table will also typically lead to very large indexes. Maintenance on very large tables can also become complex. Vacuuming or reindexing one very large table with very large indexes can become very time consuming.

What makes a table too large? Well this depends but I'd start thinking about partitioning if I expect my table to grow beyond 100GB, if the database is expected to be in the TB range you might want to consider database sharding. Database ahrding is a very coomplex process.

#### Vertical partitioning
Vertical partitioning breaks a large table up by creating multiple tables with each table contains some of the columns of the original table. Its a good practice to keep frequently queried columns together so all the data can be read from the one table.

#### Horizontal partitioning
Horizontal partitioning takes one large tables and breaks it up into multiple smaller tables which mirror the columns of the virtual table but contain on parts of the data. There are three built-in methods to partition tables in Postgres.

##### Range 
In range partitioning the partition key is based on a range of data, for example a timestamp where you could place all the data for each month in its own partition. Since each partition is now its own table you can have different indexes on different partitions, for example you may ne doing single-row select, insert, update, deletes on the active months data whilst doing more complex reporting queries on the inactive months data, you could add additional indexes for reporting to the inactive partitions, since the data is not changing the cost of the additioinal indexes is only going to be for increased storage.

Range partitioning can work well for data where we query data within a single partition.

##### List
This uses a list of values as the partition key. List partitioning can be useful when data can be logically grouped into subgroups via the partition key and most queries are within the partition.

##### Hash
A hash function is executed on the partition key to indicate which partition the row should be stored in. Postgres uses a nodulo division to define the partitions. Hash partitioning can be useful when the data cannot be easily grouped by subgroup and we want to achieve a even distribution of data across the partitions. 


## Finding queries to optimize

The following query will find the TOP SQL by execution time, if the query has a low mean execution time but a high percentage_overall that means the query is taking most of the time but it likely cannot be improved, do you need to execute the query so many times? Can you get rid of the query? Cache the data?
```
select
  substr(query, 1, 50) AS query_snippet,
  round(total_exec_time :: numeric) AS total_exec_time_ms,
  calls,
  round(mean_exec_time :: numeric) AS mean_exec_time_ms,
  round (
    (
      100 * total_exec_time / sum(total_exec_time :: numeric) OVER ()
    ) :: numeric,
    2
  ) AS percentage_overall
from
  pg_stat_statements
ORDER BY
  total_exec_time desc
limit
  20;
```
Output:
```
                   query_snippet                    | total_exec_time_ms |  calls  | mean_exec_time_ms | percentage_overall
----------------------------------------------------+--------------------+---------+-------------------+--------------------
 SELECT * FROM p where i = (select floor(random()*( |              41429 | 4925897 |                 0 |              44.75
 select sum(numbackends) numbackends, sum(xact_comm |              18470 |    1890 |                10 |              19.95
 select pid, usename, client_addr, client_hostname, |              16980 |  113392 |                 0 |              18.34
 select count(distinct transactionid::varchar) acti |               3857 |    1890 |                 2 |               4.17
 select count(distinct pid) blocked_transactions fr |               3816 |    1890 |                 2 |               4.12
 MOVE ALL IN "query-cursor_1"                       |               3028 |    1890 |                 2 |               3.27
 SELECT pg_switch_wal()                             |                620 |      10 |                62 |               0.67
 select queryid, calls, (total_plan_time + total_ex |                596 |     818 |                 1 |               0.64
 select queryid, calls, (total_plan_time + total_ex |                545 |     694 |                 1 |               0.59
 DECLARE "query-cursor_1" SCROLL CURSOR FOR select  |                456 |    1890 |                 0 |               0.49
 select count(*) active_count from pg_stat_activity |                377 |    5670 |                 0 |               0.41
 SELECT count(*) FROM information_schema.tables WHE |                304 |    7941 |                 0 |               0.33
 select queryid, calls, (total_plan_time + total_ex |                297 |     365 |                 1 |               0.32
 SELECT count(*) FROM pg_show_all_settings() WHERE  |                276 |     189 |                 1 |               0.30
 select extract($1 from now() - min(xact_start)) lo |                230 |    1890 |                 0 |               0.25
 BEGIN                                              |                210 |  151204 |                 0 |               0.23
 SELECT $1                                          |                173 |   74715 |                 0 |               0.19
 FETCH 50 IN "query-cursor_1"                       |                126 |   38199 |                 0 |               0.14
 COMMIT                                             |                121 |  151204 |                 0 |               0.13
 select coalesce(extract($1 from max(now() - state_ |                109 |    1890 |                 0 |               0.12
(20 rows)
```

## Find missing indexes and fix many problems

If you are doing a large number of sequential scans and each sequentail scan is reading a large number of rows "avg_no_rows_read" this is likely a missing index, if the number of rows read is low this is likely ok.

```
SELECT schemaname, relname, seq_scan, seq_tup_read, idx_scan, 
seq_tup_read / seq_scan as avg_no_rows_read 
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC;
```
Output:
```
 schemaname |     relname     | seq_scan  | seq_tup_read | idx_scan | avg_no_rows_read
------------+-----------------+-----------+--------------+----------+------------------
 stats      | lock_monitor    |        15 |        50697 |          |             3379
 public     | pgss_simple     |         3 |          294 |          |               98
 public     | pgss_prepared   |         2 |          164 |          |               82
 public     | pgss_simple_2   |         1 |           98 |          |               98
 public     | pgss_prepared_2 |         1 |           91 |          |               91
 public     | p16             |        12 |            0 |        0 |                0
 public     | p7              |        12 |            0 |        0 |                0
 public     | p15             |        12 |            0 |        0 |                0
 public     | p27             |        12 |            0 |        0 |                0
 public     | p13             |        12 |            0 |        0 |                0
 public     | p1              |        12 |            0 |        0 |                0
 public     | p4              |        12 |            0 |        0 |                0
 public     | p14             |        12 |            0 |        0 |                0
 public     | p2              |        12 |            0 |        0 |                0
 public     | p24             |        12 |            0 |        0 |                0
 public     | p11             |        12 |            0 |        0 |                0
 public     | p25             |        12 |            0 |        0 |                0
 public     | p3              |        12 |            0 |        0 |                0
 public     | p0              | 155493621 |            0 |        0 |                0
 public     | p18             |        12 |            0 |        0 |                0
 public     | p5              |        12 |            0 |        0 |                0
 public     | p9              |        12 |            0 |        0 |                0
 public     | p10             |        12 |            0 |        0 |                0
 public     | p21             |        12 |            0 |        0 |                0
 public     | p12             |        12 |            0 |        0 |                0
 public     | p6              |        12 |            0 |        0 |                0
 public     | p17             |        12 |            0 |        0 |                0
 public     | p22             |        12 |            0 |        0 |                0
 public     | p19             |        12 |            0 |        0 |                0
 public     | p23             |        12 |            0 |        0 |                0
 public     | p20             |        12 |            0 |        0 |                0
 public     | p26             |        12 |            0 |        0 |                0
(32 rows)
```

## A deep dive into PostgreSQL query optimizations
https://github.com/postgres/postgres/blob/master/src/backend/optimizer/README
https://postgrespro.com/blog/pgsql/5968054
https://www.youtube.com/playlist?list=PLSE8ODhjZXjasmrEd2_Yi1deeE360zv5O
https://github.com/postgres-ai/joe



