#!/bin/bash
# shellcheck source=../fileserver_to_hpc/configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

tests_path=$(dirname "$0")

rsync -rv --delete "$tests_path"/test_data "$WFJ_WORKDIR"

cd "$WFJ_WORKDIR"test_data/ || exit 1
echo "creating workflow.zip"
zip -r workflow.zip workflow