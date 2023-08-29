#!/bin/bash
function handle_error {
    echo "Error detected. Stopping all tasks."
    pkill -P $$
    exit 1
}
trap 'handle_error' ERR
echo "Installing Gulp Dependencies"
npm install -g gulp & 
npm install 
wait 
echo "Compressing all assets and other task"
# gulp deployment --env staging &
task1_pid=$!
gulp compress-new-images &
task2_pid=$!
gulp compress-new-images-png &
task3_pid=$!
# gulp generate-webroot &
# task4_pid=$!
# gulp minify &
# task5_pid=$!
wait $task1_pid
wait $task2_pid
wait $task3_pid
# wait $task4_pid
# wait $task5_pid
echo "All tasks completed successfully."
wait

# echo "adding NextJs Files"
# cd src-next
# npm i
# ENVIRONMENT=staging npm run export
# cd ..
# gulp next

wait
