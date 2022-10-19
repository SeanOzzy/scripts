-- This function can drive a high-cpu load you your PostgreSQL compatible database.
-- SELECT pg_cpu_chaos(100000);

CREATE OR REPLACE FUNCTION pg_cpu_chaos (n INTEGER)
  RETURNS integer
AS $$
DECLARE
  foo integer;
  counter INTEGER := 0 ;
BEGIN
 WHILE counter <= n LOOP
    foo := sqrt(random());
    counter := counter + 1 ;
  END LOOP;
  RETURN 1;
END;
$$
LANGUAGE plpgsql;
