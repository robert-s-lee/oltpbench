
# get number of procedures and steps per procedure
grep "public.*SQLStmt" */procedures/*.java | awk -F: '{a[$1]++} END {for (i in a) {split(i, b, "[/.]"); print b[1] " " b[3] " " a[i]}}'

# get number of fore references
grep -i "references" */ddls/*cock*.sql | awk -F: '{a[$1]++} END {for (i in a) {split(i, b, "[/.]"); print b[1] " " b[3] " " a[i]}}'

# get overall TPS
# db.workload.run.terminal.sf.host
# cockroachdb.epinions.run.4.1.mbdlan.csv
# db.workload.run.terminal. [sf.host] not present assume sf=1 localhost
# cockroachdb.wikipedia.run.2.res

gawk -F, '{sum["total"]+=$2;cnt["total"]++;} ENDFILE {n=split(FILENAME,f,"."); printf f[1] " " f[2] " " f[3] " " f[4] " "; if (n==5) {printf "1 localhost";} else {printf f[5] " " f[6];}; print " " sum["total"]/cnt["total"] " " cnt["total"]; delete sum; delete cnt; }' *.res

# get individual Txn performance
# Transaction Type Index,Transaction Name,Start Time (microseconds),Latency (microseconds),Worker Id (start number),Phase Id (index in config file)
# 4,GetPageAnonymous,1537666721.141450,105422,0,0
gawk -F, '{sum[$2]+=$4;cnt[$2]++;} ENDFILE {n=split(FILENAME,f,"."); for (i in sum) {printf f[1] "," f[2] "," f[3] "," f[4] ","; if (n==5) {printf "1,localhost";} else {printf f[5] "," f[6];}; print "," i "," sum[i] "," cnt[i];} delete sum; delete cnt; }' *.csv > procedure.csv

# $ARGV contains the name of the file currently opened by the Diamond Operator
perl -e 'while (<>){print if (/public.+new.+SQLStmt.*\(/../\)\;/);}' */procedures/*.java
perl -e 'while (<>){if ($line =~ /public.+new.+SQLStmt.*\(/../\)\;/) {print $ARGV $line;}}' */procedures/*.java
perl -e 'while (<>){print $ARGV}' */procedures/*.java


