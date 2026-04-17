#!/bin/bash

DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"

data=$(mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS $DB_NAME -Nse \
"SELECT id, message FROM logs WHERE status='pending';" 2>/dev/null)

echo "$data" | while read -r id cmd; do
    echo "Running $cmd"

    output=$(bash -c "$cmd" 2>&1)
    result=$?

    # escape single quotes for MySQL safety
    cmd_esc=$(echo "$cmd" | sed "s/'/''/g")
    output_esc=$(echo "$output" | sed "s/'/''/g")

    mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS $DB_NAME -e \
    "UPDATE logs SET status=IF($result=0,'done','error') WHERE id=$id;" 2>/dev/null

    mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS $DB_NAME -e \
    "INSERT INTO execution_log (log_id, command, output, exit_code)
     VALUES ($id, '$cmd_esc', '$output_esc', $result);" 2>/dev/null

    echo "[$result] $cmd -> $output" >> execution.log
done
