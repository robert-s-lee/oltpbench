
# defaults
backupurl="http://127.0.0.1:2015"     # assume using caddy method
multirow=true
host=""
dburl=localhost
workload="ycsb"
dbtype="cockroachdb"
username="root"
password=""
isolation="TRANSACTION_SERIALIZABLE"
terminal="8 4 2 1"
scalefactor=1
loaddata=""
rate=9999
time=60
memo=""
extern=/Users/rslee/data/cockroach-data/1/extern
crdb_dev_org="SET CLUSTER SETTING cluster.organization = 'Cockroach Labs - Production Testing';"
crdb_dev_lic=${COCKROACH_DEV_LICENSE}

# options
while getopts "b:d:i:lL:m:M:O:p:r:u:s:t:w:" opt; do
  case "${opt}" in
    b)
      backupurl="${OPTARG}"
      ;;
    d)
      dbtype="${OPTARG}"
      ;;
    i)
      host="${OPTARG}"
      ;;
    l)
      loaddata="1"
      ;;
    L)
      crdb_dev_lic="${OPTARG}"
      ;;
    m)
      time="${OPTARG}"
      ;;
    M)
      memo=".${OPTARG}"
      ;;
    O)
      crdb_dev_org="${OPTARG}"
      ;;
    p)
      password="${OPTARG}"
      ;;
    r)
      rate="${OPTARG}"
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

#
#if [ `which caddy` ]; then
#  caddy -root $extern "upload / {" "to \"$extern\"" "yes_without_tls" "}" &
#fi
  
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
      cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000; SET CLUSTER SETTING kv.allocator.load_based_rebalancing = 'leases and replicas';drop database if exists ${workload} cascade;"
      if [ ! -z "$crdb_dev_lic" ]; then
        cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "${crdb_dev_org};${crdb_dev_lic}"
      fi
    fi
    ;;
  *)
    echo "unknown dbtype ${dbtype}"
  ;;
esac

backupfile=${dbtype}.${workload}.${scalefactor}${memo}
cfgfile=${dbtype}_${workload}_config.xml

# prepare config
sed  \
  -e  "s|<dbtype>.*</dbtype>|<dbtype>${dbtype}</dbtype>|" \
  -e  "s|<driver>.*</driver>|<driver>${driver}</driver>|" \
  -e  "s|<DBUrl>.*</DBUrl>|<DBUrl>${dburl}</DBUrl>|" \
  -e  "s|<username>.*</username>|<username>${username}</username>|" \
  -e  "s|<password>.*</password>|<password>${password}</password>|" \
  -e  "s|<isolation>.*</isolation>|<isolation>${isolation}</isolation>|" \
  -e  "s|<scalefactor>.*</scalefactor>|<scalefactor>${scalefactor}</scalefactor>|" \
  -e  "s|<time>.*</time>|<time>${time}</time>|" \
  -e  "s|<rate>.*</rate>|<rate>${rate}</rate>|" \
  config/sample_${workload}_config.xml > /tmp/$cfgfile

# create results dir
if [ ! -d results ]; then
  mkdir results
fi

# create and load data
if [ ! -z "$loaddata" ]; then
  case $dbtype in 
    mysql)
        if [ -d $extern/$backupfile ]; then
          echo "Loading $extern/$backupfile/$backupfile.sql"
          mysql -h ${host} -P ${port} -u $username -B ${workload} < $extern/$backupfile/$backupfile.sql
        else
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          mkdir $extern/$backupfile
          mysqldump -h ${host} -P ${port} -u $username  -e ${workload} >  $extern/$backupfile/$backupfile.sql
        fi
      ;;
    postgres)
        if [ -d $extern/$backupfile ]; then
          echo "Loading $extern/$backupfile/$backupfile"
          pg_restore -d ${workload}  -h $host -p $port -U $username $extern/$backupfile 
        else
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          pg_dump -Fd -f $extern/$backupfile -h $host -p $port -U $username ${workload}
        fi
      ;;
    cockroachdb)
        if [ -d $extern/$backupfile ]; then
          echo "Loading $extern/$backupfile/$backupfile"
          cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "restore database ${workload} from '${backupurl}:/$backupfile';"
          sleep 5
        else
          cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "create database ${workload};"
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          cockroach sql --insecure --url "postgresql://$username@$host:$port" -e "BACKUP database ${workload} TO '${backupurl}:/$backupfile';"
          sleep 5
        fi
      ;;
    *)
      echo "unknown dbtype ${dbtype}"
    ;;
  esac
fi

# run at various concurrency
for t in ${terminal}; do

  logfile=${dbtype}.${workload}.run.${t}.${scalefactor}.${host}.${rate}${memo}

  if [[ ("${workload}" == "epinions") &&  ("${dbtype}" == "postgres") && ($t -gt 1) ]]; then
    echo "${dbtype} cannot run ${workload} at concurrency $t:  could not serialize access due to read/write dependencies among transactions"
    continue
  fi

  sed -i.bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|"  /tmp/$cfgfile

  rm results/$logfile.res 2>/dev/null
  rm results/$logfile.csv 2>/dev/null
  rm results/$logfile.hist 2>/dev/null

  ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --execute=true --dialects-export $logfile.sql -s 5 -v --histograms -im 5000 -o $logfile | tee -a results/$logfile.hist

  # don't re-run workloads that cannot return once run
  case $workload in 
    auctionmark)
      break
      ;;
  esac 
done

#rm /tmp/$cfgfile /tmp/$cfgfile.bak 
