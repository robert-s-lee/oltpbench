
# defaults
multirow=true
hostport=""
dburl=localhost
workload="voter"
dbtype="cockroachdb"
username="root"
password=""
isolation="TRANSACTION_SERIALIZABLE"
terminal="1 2"
scalefactor=1
loaddata=""

# options
while getopts "d:lp:u:s:t:w:" opt; do
  case "${opt}" in
    d)
      dbtype="${OPTARG}"
      ;;
    i)
      hostport="${OPTARG}"
      ;;
    l)
      loaddata="1"
      ;;
    p)
      password="${OPTARG}"
      ;;
    s)
      scalefactor="${OPTARG}"
      ;;
    t)
      terminal="${OPTARG}"
      ;;
    u)
      username="${OPTARG}"
      ;;
    w)
      workload="${OPTARG}"
      ;;
    esac
done
shift $((OPTIND-1))

# setup dtabase locally
case $dbtype in 
  mysql)
    if [ -z "${hostport}" ]; then 
      hostport="localhost:3306"
    fi
    driver="com.mysql.jdbc.Driver"
    dburl="jdbc:mysql://${hostport}/${workload}?reWriteBatchedStatement=${multirow}"
    if [ ! -z "$loaddata" ]; then
      mysql -u $username -e "drop database if exists ${workload}; create database ${workload}"
    fi
    ;;
  postgres)
    if [ -z "${hostport}" ]; then 
      hostport="localhost:5432"
    fi
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
    if [ ! -z "$loaddata" ]; then
      psql -U $username -c " drop database if exists ${workload}"
      psql -U $username -c " create database ${workload};"
    fi
    ;;
  cockroachdb)
    if [ -z "${hostport}" ]; then 
      hostport="localhost:26257"
    fi
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
    if [ ! -z "$loaddata" ]; then
      cockroach sql --insecure -u $username -e "SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000;drop database if exists ${workload} cascade; create database ${workload}"
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

# crate and load data
if [ ! -z "$loaddata" ]; then
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load
fi

# run at various concurrency
for t in ${terminal}; do
  sed -i.bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|" config/${dbtype}_${workload}_config.xml
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --execute=true -s 5 -v -o ${dbtype}.${workload}.run.$t
done

