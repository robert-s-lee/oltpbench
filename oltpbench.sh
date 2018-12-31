
# defaults
backupurl="http://127.0.0.1:2015"     # assume using caddy method
certsdir=""                           # crdb only
multirow=true
host=""
dburl=localhost
workload="ycsb"
dbtype="cockroachdb"
username="root"
password=""
isolation_level="8"  
terminal="2"
scalefactor=1
loaddata=""
rate=9999
time=60
memo=""
extern=/Users/rslee/data/cockroach-data/1/extern
crdb_dev_org="Cockroach Labs - Production Testing"
crdb_dev_lic=${COCKROACH_DEV_LICENSE}

# options
while getopts "b:c:d:I:i:l:L:m:M:O:p:r:u:s:t:w:" opt; do
  case "${opt}" in
    b)
      backupurl="${OPTARG}"
      ;;
    c)
      certsdir=`find ${OPTARG} -prune`
      ;;
    d)
      dbtype="${OPTARG}"
      ;;
    i)
      host="${OPTARG}"
      ;;
    I)
      isolation_level="${OPTARG}"
      ;;
    l)
      loaddata="${OPTARG}"
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
    ;;
  postgres)
    port="5432"
    if [ -z "${host}" ]; then 
      host="localhost"
    fi
    hostport="${host}:${port}"
    driver="org.postgresql.Driver"
    dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
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
    if [ -z "${certsdir}" ]; then
      dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}"
      crdburl="postgres://$username@$host:$port/?application_name=${workload}&sslmode=disable"
    else
      dburl="jdbc:postgresql://${hostport}/${workload}?reWriteBatchedInserts=${multirow}\&amp;ApplicationName=${workload}\&amp;sslmode=require\&amp;sslrootcert=${certsdir}/ca.crt \&amp;sslkey=${certsdir}/client.${username}.pk8\&amp;sslcert=${certsdir}/client.${username}.crt"
      crdburl="postgres://$username@$host:$port/?application_name=${workload}&sslmode=verify-full&sslrootcert=${certsdir}/ca.crt&sslcert=${certsdir}/client.${username}.crt&sslkey=path/client.${username}.key"
    fi
    ;;
  *)
    echo "unknown dbtype ${dbtype}"
  ;;
esac

backupfile=${dbtype}.${workload}.${scalefactor}${memo}
cfgfile=${dbtype}_${workload}_config.xml

# prepare isolation level
# 1: READ UNCOMMITTED
# 2: READ COMMITTED
# 4: REPEATABLE READ
# 8: SERIALIZABLE
case "${isolation_level}" in 
 1) isolation="TRANSACTION_READ_UNCOMMITTED"
  ;;
 2) isolation="TRANSACTION_READ_COMMITTED"
  ;;
 4) isolation="TRANSACTION_REPEATABLE_READ"
  ;;
 *) isolation="TRANSACTION_SERIALIZABLE"
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
  -e  "s|<time>.*</time>|<time>${time}</time>|" \
  -e  "s|<rate>.*</rate>|<rate>${rate}</rate>|" \
  config/sample_${workload}_config.xml > /tmp/$cfgfile

# create results dir
if [ ! -d results ]; then
  mkdir results
fi

# create and load data
if [ ! -z "$loaddata" ]; then
  mkdir -p $extern
  case $dbtype in 
    mysql)
        mysql -h ${host} -P ${port} -u $username -e "drop database if exists ${workload}; create database ${workload}"
        backupfilefqdn=$extern/$backupfile.mysql.gz
        if [ -f ${backupfilefqdn} ]; then
          echo "Loading ${backupfilefqdn}"
          gzip -dc ${backupfilefqdn} | mysql -h ${host} -P ${port} -u $username -B ${workload} 
        else
          echo "Generating data ${workload}"
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          echo "Generating data ${workload}"
          mysqldump -h ${host} -P ${port} -u $username  -e ${workload} | gzip > ${backupfilefqdn}
        fi
      ;;
    postgres)
        psql -h $host -p $port -U $username -c " drop database if exists ${workload}"
        psql -h $host -p $port -U $username -c " create database ${workload};"
        backupfilefqdn=$extern/$backupfile.pg.gz
        if [ -f ${backupfilefqdn} ]; then
          echo "Loading ${backupfilefqdn}"
          gzip -dc ${backupfilefqdn} | psql -d ${workload}  -h $host -p $port -U $username 
        else
          echo "Generating data ${workload}"
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          echo "Backing ${backupfilefqdn}"
          pg_dump -h $host -p $port -U $username ${workload} | gzip > ${backupfilefqdn}
        fi
      ;;
    cockroachdb)
      cockroach sql --url "${crdburl}" -e "SET CLUSTER SETTING kv.transaction.max_intents_bytes = 1256000;SET CLUSTER SETTING kv.transaction.max_refresh_spans_bytes = 1256000; SET CLUSTER SETTING kv.allocator.load_based_rebalancing = 'leases and replicas';drop database if exists ${workload} cascade;"
      if [ ! -z "$crdb_dev_lic" ]; then
        cockroach sql --url "${crdburl}" -e "SET CLUSTER SETTING cluster.organization='${crdb_dev_org}';SET CLUSTER SETTING enterprise.license='${crdb_dev_lic}'"
      fi
        if [[ -d $extern/$backupfile.crdb && ! -z ${crdb_dev_lic} ]]; then
          echo "Loading $extern/$backupfile/$backupfile.crdb"
          cockroach sql --url "${crdburl}" -e "restore database ${workload} from '${backupurl}:/$backupfile.crdb';"
          sleep 5
        else
          cockroach sql --url "${crdburl}" -e "create database ${workload};"
          time ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --create=true --load=true -s 5 -v -o ${dbtype}.${workload}.load.${host}
          if [ ! -z ${crdb_dev_lic} ]; then
            cockroach sql --url "${crdburl}" -e "BACKUP database ${workload} TO '${backupurl}:/$backupfile.crdb';"
          fi
        fi
      ;;
    *)
      echo "unknown dbtype ${dbtype}"
    ;;
  esac
fi

sleep 5

# run at various concurrency
for t in ${terminal}; do

  logfile=${dbtype}.${workload}.run.${t}.${scalefactor}.${host}.${rate}.${isolation_level}${memo}

  if [[ ("${workload}" == "epinions") &&  ("${dbtype}" == "postgres") && ($t -gt 1) ]]; then
    echo "${dbtype} cannot run ${workload} at concurrency $t:  could not serialize access due to read/write dependencies among transactions"
    continue
  fi

  sed -i.bak "s|<terminals>.*</terminals>|<terminals>$t</terminals>|"  /tmp/$cfgfile

  rm results/$logfile.res 2>/dev/null
  rm results/$logfile.csv 2>/dev/null
  rm results/$logfile.hist 2>/dev/null

  ./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --execute=true -s 5 -v --histograms -im 5000 -o $logfile | tee -a results/$logfile.hist
  #./oltpbenchmark -b ${workload} -c /tmp/$cfgfile --dialects-export=true --tracescript=true -s 5 -v --histograms -im 5000 -o $logfile | tee -a results/$logfile.hist

  # don't re-run workloads that cannot return once run
  case $workload in 
    auctionmark)
      break
      ;;
  esac 
done

#rm /tmp/$cfgfile /tmp/$cfgfile.bak 
