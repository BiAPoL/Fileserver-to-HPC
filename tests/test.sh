#!/bin/bash
# shellcheck source=../src/scripts/configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

tests_path=$(dirname "$0")

rsync -r --delete "$tests_path"/test_data "$WFJ_WORKDIR"

cd "$WFJ_WORKDIR"test_data/ || exit 1
zip -r workflow.zip workflow