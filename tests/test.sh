#!/bin/bash
# shellcheck source=../src/scripts/configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

rsync -r --delete test_data "$WFJ_WORKDIR"

zip -r "$WFJ_WORKDIR"test_data/workflow.zip "$WFJ_WORKDIR"test_data/workflow