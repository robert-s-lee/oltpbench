
# defaults
workload="voter"
dbtype="cockroachdb"
username="root"
password=""
isolation="TRANSACTION_SERIALIZABLE"
terminal="1 2"
scalefactor=1
loaddata="1"

# options
while getopts "d:lw:t:" opt; do
  case "${opt}" in
    d)
      dbtype="${OPTARG}"
      ;;
    l)
      loaddata=""
      ;;
    w)
      workload="${OPTARG}"
      ;;
    t)
      terminal="${OPTARG}"
      ;;
    esac
done
shift $((OPTIND-1))

# disable multirow for some workloads
case ${workload} in 
  smallbank)
    multirow=false
    ;;
  *)
    multirow=true
    ;;
esac
multirow=true

# setup dtabase locally
case $dbtype in 
  mysql)
    driver="com.mysql.jdbc.Driver"
    dburl="jdbc:mysql://localhost:3306/${workload}?reWriteBatchedStatement=${multirow}"
    if [ -z "$loaddata" ]; then
      mysql -u root -e "drop database if exists ${workload}; create database ${workload}"
    fi
    ;;
  postgres)
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://127.0.0.1/${workload}?reWriteBatchedInserts=${multirow}"
    if [ -z "$loaddata" ]; then
      psql -c " drop database if exists ${workload}"
      psql -c " create database ${workload};"
    fi
    username=rslee
    ;;
  cockroachdb)
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://127.0.0.1:26257/${workload}?reWriteBatchedInserts=${multirow}"
    if [ -z "$loaddata" ]; then
      cockroach sql --insecure -e "drop database if exists ${workload} cascade; create database ${workload}"
    fi
    ;;
  *)
    echo "unknown dbtype ${dbtype}"
  ;;
esac

# prepare config
sed  \
  -e  "s|<dbtype>.*</dbtype>|<dbtype>${dbtype}</dbtype>|" \
  -e  "s|<driver>.*</driver>|<driver>${driver}</driver>|" \
  -e  "s|<DBUrl>.*</DBUrl>|<DBUrl>${dburl}</DBUrl>|" \
  -e  "s|<username>.*</username>|<username>${username}</username>|" \
  -e  "s|<password>.*</password>|<password>${password}</password>|" \
  -e  "s|<isolation>.*</isolation>|<isolation>${isolation}</isolation>|" \
  -e  "s|<scalefactor>.*</scalefactor>|<scalefactor>${scalefactor}</scalefactor>|" \
  config/sample_${workload}_config.xml  > config/${dbtype}_${workload}_config.xml

if [ -z "$loaddata" ]; then
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --create=true --load=true -s 5 -v -o outputfile
fi

for t in ${terminal}; do
  sed -i.bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|" config/${dbtype}_${workload}_config.xml
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --execute=true -s 5 -v -o outputfile
done

