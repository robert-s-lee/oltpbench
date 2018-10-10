To speed up repeated testing, generated data is saved so that it can be reloaded.

For CockroachDB, 

COCKROACH_DEV_LICENSE="SET CLUSTER SETTING cluster.organization = 'Cockroach Labs - Production Testing'; SET CLUSTER SETTING enterprise.license = '...';"
export COCKROACH_DEV_LICENSE

in oltpbench.sh change the below to where the backup data shold be stored.
extern=/Users/rslee/data/cockroach-data/1/extern



