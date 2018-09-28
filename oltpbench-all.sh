# createdb
# createuser root
# createdb -O root root
# psql -c "ALTER USER root CREATEDB"
# sed -i.bak 's/^bind-address/#bind-address/' /usr/local/etc/my.cnf
# mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;
# cockroachDB 
# required for auctionmark
# SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;
# SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000;
# cockroach gen haproxy --insecure --host mbdlan
# haproxy 


dbtype="cockroachdb mysql postgres" #
workload="auctionmark linkbench seats tpcc tatp twitter voter epinions sibench smallbank ycsb wikipedia resourcestresser"   
for d in $dbtype; do
for w in $workload; do
./oltpbench.sh -i mbdlan -d $d -w $w -l 
done
done
