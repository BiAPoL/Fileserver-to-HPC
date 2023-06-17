#!/bin/bash
cd "$(dirname "$0")" || exit
scripts_dir=$(pwd)/src/watch_for_jobs

# shellcheck source=src/watch_for_jobs/configuration.sh
source "${scripts_dir}/configuration.sh"

mkdir ~/.watch_for_jobs

cp "${scripts_dir}/configuration.sh" ~/.watch_for_jobs/
cp "${scripts_dir}/start_job.sh" ~/.watch_for_jobs/

# check if the workspace is writable
if [ ! -w "$WFJ_WORKDIR" ]; then
  echo "The workspace $WFJ_WORKDIR is not writable. Please make sure that you have write permissions."
  exit 1
fi

echo "installing crontab"
echo "* * * * * ${scripts_dir}/watch_for_jobs.sh >> $WFJ_LOG 2>&1" | crontab - 

echo "Installation successful."
