# Postgres
# su - postgres
# createdb
# createuser root
# createdb -O root root
# psql -c "ALTER USER root CREATEDB"
# /usr/local/var/postgres/
# osx does not write to disk with the default method
# sed -i.bak -e 's/^\(wal_sync_method\)/#\1/' /usr/local/var/postgres/postgresql.conf
# echo "wal_sync_method = fsync_writethrough" >> /usr/local/var/postgres/postgresql.conf
# fsync_writethrough 
# mysql
# sed -i.bak 's/^bind-address/#bind-address/' /usr/local/etc/my.cnf
# mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;
# cockroachDB 
# required for auctionmark
# SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;
# SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000;
# cockroach gen haproxy --insecure --host mbdlan
# haproxy 
# SEATS
#   Hint: You might need to increase max_pred_locks_per_transaction.

setconfig() {

os=`uname`
case $os in
  Darwin)
    pgconf=/usr/local/var/postgres/postgresql.conf
    pghba=/usr/local/var/postgres/main/pg_hba.conf
    ;;
  Linux) 
    pgconf=/etc/postgresql/10/main/postgresql.conf
    pghba=/etc/postgresql/10/main/pg_hba.conf
    ;;
  *)
    echo "unknown os ${os}"
    ;;
esac

psql -c "ALTER USER root CREATEDB"

sed -i.bak \
-e 's/^\(listen_addresses\)/#\1/' \
-e 's/^\(synchronous_commit\)/#\1/' \
-e 's/^\(logging_collector\)/#\1/' \
-e 's/^\(wal_compression\)/#\1/' \
-e 's/^\(log_checkpoints\)/#\1/' \
-e 's/^\(archive_mode\)/#\1/' \
-e 's/^\(full_page_writes\)/#\1/' \
-e 's/^\(fsync\)/#\1/' $pgconf

cat <<EOF >> $pgconf
listen_addresses = '*'      # OLTPBENCH ADD
synchronous_commit = 'ON'   # OLTPBENCH ADD
logging_collector = 'ON'    # OLTPBENCH ADD
wal_compression = 'ON'      # OLTPBENCH ADD
log_checkpoints = 'ON'      # OLTPBENCH ADD
archive_mode = 'ON'         # OLTPBENCH ADD
full_page_writes = 'ON'     # OLTPBENCH ADD
fsync = 'ON'                # OLTPBENCH ADD
EOF


echo "host	all             all             192.168.0.0/24            trust" >> $pghba
}

isolation="1 2 4 8"
dbtype="postgres"
workload="ycsb"   
for i in $isolation; do
for d in $dbtype; do
for w in $workload; do
./oltpbench.sh -i localhost -d $d -w $w -I $i -t "32 64 128"
done
done
done
