#!/bin/sh

# get target host and port. Default is 'vote:5000'
host=${TARGET_HOST='vote'}
port=${TARGET_PORT=5000}

echo "Generating vote for ${host}:${port}"

# create 300 votes (200 for option a, 100 for option b)
ab -n 100 -c 50 -p posta -T "application/x-www-form-urlencoded" http://${TARGET_HOST}:${TARGET_PORT}/
ab -n 100 -c 50 -p postb -T "application/x-www-form-urlencoded" http://${TARGET_HOST}:${TARGET_PORT}/
ab -n 100 -c 50 -p posta -T "application/x-www-form-urlencoded" http://${TARGET_HOST}:${TARGET_PORT}/
