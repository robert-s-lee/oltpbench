Suggested way to test CockroachDB 

## single node local laptop unit test

Single node on a laptop is a good way to unit test configuration and make sure everything works.  The steps are as follows:

- a single node CockroachDB in an insecure node
- create database
- create TPCC tables and load data
- run terminals count of 1,2,4,8,16

CPU will be a typical bottlenect of a small local system.

```
cockroach start --insecure --port=26257 --http-port=26258 --store=cockroach-data/1 --cache=256MiB --background
cockroach sql --insecure -e "drop database if exists tpcc cascade; create database tpcc"
time ./oltpbenchmark -b tpcc -c config/tpcc_config_cockroachdb.xml --create=true --load=true -s 5 -v -o outputfile
for t in 1 2 4 8 16; do
  sed -i bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|" config/tpcc_config_cockroachdb.xml
  time ./oltpbenchmark -b tpcc -c config/tpcc_config_cockroachdb.xml --execute=true -s 5 -v -o outputfile
done
```

## Roachprod cluster

CockroachDB has roachprod that allows testing in cloud.  


f=robert-oltpbenchmark
n=4
(( lastnode = $n - 1 ))
roachprod create $f -n $n --local-ssd
roachprod run $f -- 'sudo umount /mnt/data1; sudo mount -o discard,defaults,nobarrier /dev/disk/by-id/google-local-ssd-0 /mnt/data1/; mount | grep /mnt/data1'
roachprod run $f -- 'wget -qO- https://binaries.cockroachdb.com/cockroach-v2.1.0-beta.20180917.linux-amd64.tgz | tar  xvz; cp cockroach-v2.1.0-beta.20180917.linux-amd64/cockroach ./'
roachprod start $f:1-$lastnode

# get necessary 3rd party software to run YCSB such as JRE
roachprod run $f:$n -- 'sudo apt-get -y update; sudo apt-get -y install openjdk-8-jdk maven'  # required
roachprod run $f:$n -- 'sudo apt-get -y install htop sysstat nethogs'                   # optional for monitoring
roachprod run $f:$n -- 'sudo apt-get -y install haproxy;  systemctl stop haproxy'       # software based load balance

# setup haproxy
roachprod run $f:1 -- './cockroach node status --insecure --format tsv' | tail -n +2 > /tmp/oltpbenchmark_nodestatus.$$
crdbnode=`head -n 1 /tmp/oltpbenchmark_nodestatus.$$ | cut -f 2,2`
roachprod run $f:$n -- "./cockroach gen haproxy --insecure --host $crdbnode"
roachprod run $f:$n -- 'nohup haproxy -f haproxy.cfg'

# download the simulator
roachprod run $f:$n -- 'git clone https://github.com/robert-s-lee/oltpbench.git --branch cockroachdb --single-branch oltpbenchmark; cd oltpbenchmark; ant'

# run the workload
roachprod run $f:$n -- "./cockroach sql --insecure --host $crdbnode -e 'drop database if exists tpcc cascade; create database tpcc'"
roachprod run $f:$n -- "cd oltpbenchmark; time ./oltpbenchmark -b tpcc -c config/tpcc_config_cockroachdb.xml --create=true --load=true -s 5 -v -o outputfile"
roachprod run $f:$n -- "./cockroach sql --insecure --database tpcc --host $crdbnode -e 'ALTER TABLE warehouse SPLIT AT select generate_series(1,10, 10); ALTER TABLE district SPLIT AT select generate_series(1,10, 10), 0; ALTER TABLE item SPLIT AT select generate_series(1, 100000, 100); ALTER TABLE history split at select gen_random_uuid() from generate_series(1, 1000);'"

for t in 1 2 4 8 16; do 
roachprod run $f:$n -- "cd oltpbenchmark; sed -i.bak -e 's|<terminals>.*</terminals>|<terminals>$t</terminals>|' config/tpcc_config_cockroachdb.xml; time ./oltpbenchmark -b tpcc -c config/tpcc_config_cockroachdb.xml --execute=true -s 5 -v -o outputfile"
done



