#!/bin/bash
#----------------Parameters---------------
MEMCACHED_PATH="/home/ubuntu/git_repos/bmc-cache/memcached-sr"
USER='ubuntu'
# PORT=11211
WORKER_NUM=1        # all worker thread will located in one core, haven't address
#----------------Parameters END---------------
cd $MEMCACHED_PATH
# start server
./memcached -u $USER -P $WORKER_NUM