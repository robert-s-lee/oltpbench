
# defaults
multirow=true
host=""
dburl=localhost
workload="ycsb"
dbtype="cockroachdb"
username="root"
password=""
isolation="TRANSACTION_SERIALIZABLE"
terminal="32 16 8 4 2 1"
scalefactor=1
loaddata=""

# options
while getopts "d:i:lp:u:s:t:w:" opt; do
  case "${opt}" in
    d)
      dbtype="${OPTARG}"
      ;;
    i)
      host="${OPTARG}"
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
    port="3306"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="com.mysql.jdbc.Driver"
    dburl="jdbc:mysql://${hostport}/${workload}?reWriteBatchedStatement=${multirow}\&amp;autoReconnect=true\&amp;useSSL=false"
    if [ ! -z "$loaddata" ]; then
      mysql -h ${host} -P ${port} -u $username -e "drop database if exists ${workload}; create database ${workload}"
    fi
    ;;
  postgres)
    port="5432"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
    if [ ! -z "$loaddata" ]; then
      psql -h $host -p $port -U $username -c " drop database if exists ${workload}"
      psql -h $host -p $port -U $username -c " create database ${workload};"
    fi

    if [[ ("${workload}" == "linkbench") &&  ("${dbtype}" == "postgres") ]]; then
      psql -h $host -p $port -U $username -d ${workload} <<'EOF'
CREATE OR REPLACE FUNCTION if(boolean, anyelement, anyelement)
   RETURNS anyelement AS $$
BEGIN
    CASE WHEN ($1) THEN
    RETURN ($2);
    ELSE
    RETURN ($3);
    END CASE;
    EXCEPTION WHEN division_by_zero THEN
    RETURN ($3);
END;
$$ LANGUAGE plpgsql;
EOF
    fi
    ;;
  cockroachdb)
    port="26257"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
    if [ ! -z "$loaddata" ]; then
      cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000; SET CLUSTER SETTING kv.allocator.load_based_rebalancing = 'leases and replicas'; drop database if exists ${workload} cascade; create database ${workload}"
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
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
fi

# run at various concurrency
for t in ${terminal}; do

  if [[ ("${workload}" == "epinions") &&  ("${dbtype}" == "postgres") && ($t -gt 1) ]]; then
    echo "${dbtype} cannot run ${workload} at concurrency $t:  could not serialize access due to read/write dependencies among transactions"
    continue
  fi

  sed -i.bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|" config/${dbtype}_${workload}_config.xml
  time ./oltpbenchmark -b ${workload} -c config/${dbtype}_${workload}_config.xml --execute=true -s 5 -v -o ${dbtype}.${workload}.run.${t}.${scalefactor}.${host}
  # don't re-run workloads that cannot return once run
  case $workload in 
    auctionmark)
      break
      ;;
  esac 
done

