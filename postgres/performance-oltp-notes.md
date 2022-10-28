# OLTP Qury Optimization Considerations

A RDBMS takes the declarative SQL text and creates a procedural execution plan which attempts to retrieve the data as efficiently as possible. The query optimizer is one of the most complex parts of the engine.

## Finding data
Typically the optimizer has two main options, scan the entire table (heap) or use an index (secondary data structure) to locate a pointer to the data in the heap.

If the index includes all the columns required to satisfy the query then the engine will be able to gather the data directly from the index without requiring the lookup to the heap.

### Table scans
Scanning is a simple look at each row in the table, fetch the blocks, apply any filter or condition to discard rows which don't match the filter or condition. Scanning a large table can be expensive and the cost is based on the number of rows in the table. 

There are cases where a table scan is more efficient than using an existing index, usually these situations involve a non-selective query which will fetch a large proportion of the table, in this case the optimizer may choose to scan the entire table rather than add the cost of reading the index and then completing the heap lookup. A similar situation is a small table where scanning the entire table is more cost effictive. If you are seeing the optimizer choosing a full table scan you should consider why, does the query return a large proprtion of the table (num_of_rows_returned / total_num_rows)? Does an index exist for the columns in the WHERE or JOIN clauses?

### Index scans
An index scan involves finding the pointer to the row(s) in the heap  by scanning through an index and find matching keys. Columns used in WHERE and JOIN conditions are good candidates for indexes if the column is regularly used for filtering or joining. Indexes are not free, they require increased storage since they contain a copy of data from the heap and they require resources to keep them up-to-date and maintain them. 

#### Index types

##### B-tree


##### Bitmap


##### Hash 


##### GIN

##### GiST

##### SP-GiST

##### BRIN

## Joining data
Joins are required when two or more tables store related data but data that should be stored independently, for example customer_details vs orders. Typically a customer identifier will be a column in a customer table whilst the orders table can have a foreign key for customer_id which points to the customer_id column in the customer table. If we need to find all order for a particular customer we can join the customer and orders table using the shared customer_id column to find matches. The optimizer can satisfy a join using three methods, nested loops, hash joins and sort merge joins.

### Join types

#### Inner join
The inner join returns rows from both tables as long as they both have a matching key, this is also known simply as a JOIN. For example these two queries are the same. If possible an inner join is normally most-eficient.

``` SELECT customer_name, order_status FROM customer AS c INNER JOIN orders AS o on c.customer_id = o.customer_id```

``` SELECT customer_name, order_status FROM customer AS c JOIN orders AS o on c.customer_id = o.customer_id``` 

#### Left outer join
The left out join returns all rows from the left table (this is litterally the left most table in the query) and also returns rows from the right table that have a matching key. Rows returned from the left table with no matching key in the right table will have null values in place of the missing values from the right table.

#### Right outer join
The right outer join returns all rows from the right table and also returns rows from the left table that have a matching key. Rows returned from the right table with no matching key in the left table will have null values in place of the missing values from the left table.

#### Full outer join
A full outer join returns all rows from both table, if there isn't a matching key in one of the tables the missing column returns a null value.

#### Join methods

##### Nested loops


##### Hash joins


##### Merge joins


