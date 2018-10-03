
# defaults
multirow=true
host=""
dburl=localhost
workload="auctionmark linkbench seats tpcc tatp twitter voter epinions sibench smallbank wikipedia resourcestresser"
dbtype="cockroachdb"
username="root"
password=""
isolation="TRANSACTION_SERIALIZABLE"
terminal="32 16 8 4 2 1"
scalefactor="1 4 16"
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

for w in $workload; do
for s in $scalefactor; do

# setup dtabase locally
case $dbtype in 
  mysql)
    port="3306"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="com.mysql.jdbc.Driver"
    dburl="jdbc:mysql://${hostport}/${w}?reWriteBatchedStatement=${multirow}\&amp;autoReconnect=true\&amp;useSSL=false"
    if [ ! -z "$loaddata" ]; then
      mysql -h ${host} -P ${port} -u $username -e "drop database if exists ${w}; create database ${w}"
    fi
    ;;
  postgres)
    port="5432"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${w}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${w}"
    if [ ! -z "$loaddata" ]; then
      psql -h $host -p $port -U $username -c " drop database if exists ${w}"
      psql -h $host -p $port -U $username -c " create database ${w};"
    fi

    if [[ ("${w}" == "linkbench") &&  ("${dbtype}" == "postgres") ]]; then
      psql -h $host -p $port -U $username -d ${w} <<'EOF'
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
    dburl="jdbc:postgresql://${hostport}/${w}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${w}"
    if [ ! -z "$loaddata" ]; then
      cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000; SET CLUSTER SETTING kv.allocator.load_based_rebalancing = 'leases and replicas'; $COCKROACH_DEV_LICENSE; drop database if exists ${w} cascade; create database ${w}"
    fi
    ;;
  *)
    echo "unknown dbtype ${dbtype}"
  ;;
esac


backupfile=${dbtype}.${w}.${s}
logfile=${dbtype}.${w}.run.${t}.${s}.${host}
cfgfile=${dbtype}_${w}_config.xml

# prepare config
sed  \
  -e  "s|<dbtype>.*</dbtype>|<dbtype>${dbtype}</dbtype>|" \
  -e  "s|<driver>.*</driver>|<driver>${driver}</driver>|" \
  -e  "s|<DBUrl>.*</DBUrl>|<DBUrl>${dburl}</DBUrl>|" \
  -e  "s|<username>.*</username>|<username>${username}</username>|" \
  -e  "s|<password>.*</password>|<password>${password}</password>|" \
  -e  "s|<isolation>.*</isolation>|<isolation>${isolation}</isolation>|" \
  -e  "s|<scalefactor>.*</scalefactor>|<scalefactor>${s}</scalefactor>|" \
  config/sample_${w}_config.xml  > /tmp/$cfgfile.$$

# crate and load data
if [ ! -z "$loaddata" ]; then
  time ./oltpbenchmark -b ${w} -c /tmp/$cfgfile.$$ --create=true --load=true -s 5 -v -o ${dbtype}.${w}.load.${host}
  case $dbtype in 
    mysql)
      ;;
    postgres)
      ;;
    cockroachdb)
        # wait for load to settle down
        sleep 10
        cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "BACKUP database ${w} TO 'nodelocal:/$backupfile';"
      ;;
    *)
      echo "unknown dbtype ${dbtype}"
    ;;
  esac
fi
done
done
