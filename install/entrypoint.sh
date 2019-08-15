#!/bin/bash
echo "Starting Our Story Titan"

mongod &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mongod: $status"
  exit $status
fi

# Start the second process
redis-server --dir /redis --appendonly yes &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start redis-server: $status"
  exit $status
fi

# Start the second process
beanstalkd &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start beanstalkd: $status"
  exit $status
fi

sleep 5

# Start the second process
nginx -g "daemon off;" &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep mongod |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep redis-server |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep beanstalkd |grep -q -v grep
  PROCESS_3_STATUS=$?
  ps aux |grep nginx |grep -q -v grep
  PROCESS_4_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0  -o $PROCESS_3_STATUS -ne 0 -o $PROCESS_4_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done



# mongod &
# redis-server --dir /redis --appendonly yes &
# beanstalkd &

# sleep 2

cd /ourstory-worker && npm start &
cd /ourstory-server && npm start &

# nginx -g "daemon off;"