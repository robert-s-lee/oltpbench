# createuser root
# createdb -O root root
# psql -c "ALTER USER root CREATEDB"
# cockroachDB 
# required for auctionmark
# SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;
# SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000;


dbtype="cockroachdb mysql postgres"
workload="seats tpcc tatp twitter voter epinions sibench smallbank"   # ycsb
for d in $dbtype; do
for w in $workload; do
./oltpbench.sh -d $d -w $w -l 
done
done
