#!/bin/bash
# shellcheck source=../fileserver_to_hpc/configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

# delete the line containing test_data from watch_for_jobs_done.list
sed -i '/for_testing/d' "$HOME"/.fileserver_to_hpc/watch_for_jobs_done.list

tests_path=$(dirname "$0")

rsync -rv --delete "$tests_path"/../example_workflows/for_testing "$WFJ_WORKDIR"

cd "$WFJ_WORKDIR"for_testing/ || exit 1
echo "creating workflow.zip"
zip -r workflow.zip workflow