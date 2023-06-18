#!/bin/bash
# shellcheck source=../src/scripts/configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

tests_path=$(dirname "$0")

rsync -r --delete "$tests_path"/test_data "$WFJ_WORKDIR"

zip -r "$WFJ_WORKDIR"test_data/workflow.zip "$WFJ_WORKDIR"test_data/workflow