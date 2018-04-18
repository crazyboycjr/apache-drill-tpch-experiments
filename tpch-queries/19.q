use dfs.tmp;
select
  sum(l.l_extendedprice* (1 - l.l_discount)) as revenue
from
  lineitem l,
  part p
where
-- Impala requires requires at least one conjunctive equality predicate. 
-- Impala suggestion was to perform a Cartesian product between two tables, use a CROSS JOIN
-- DRILL: Matching with Impala
    p.p_partkey = l.l_partkey
    and
  (
   (  
--    p.p_partkey = l.l_partkey
--    and 
    p.p_brand = 'Brand#41'
    and p.p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    and l.l_quantity >= 2 and l.l_quantity <= 2 + 10
    and p.p_size between 1 and 5
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
  )
  or
  (
--    p.p_partkey = l.l_partkey
--    and 
    p.p_brand = 'Brand#13'
    and p.p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
    and l.l_quantity >= 14 and l.l_quantity <= 14 + 10
    and p.p_size between 1 and 10
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
  )
  or
  (
--    p.p_partkey = l.l_partkey
--    and 
    p.p_brand = 'Brand#55'
    and p.p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
    and l.l_quantity >= 23 and l.l_quantity <= 23 + 10
    and p.p_size between 1 and 15
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
    )
  );