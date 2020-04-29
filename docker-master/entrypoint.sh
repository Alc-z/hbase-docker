#!/bin/bash

logs_dir=$HBASE_HOME/logs

habse master start > $logs_dir/hbase-master-$HOST_NAME.log 2>&1 &