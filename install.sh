#!/bin/bash
cd "$(dirname "$0")" || exit
scripts_dir=$(pwd)/fileserver_to_hpc
install_dir=~/.fileserver_to_hpc

# shellcheck source=fileserver_to_hpc/configuration.sh
source "${scripts_dir}/configuration.sh"

mkdir "$install_dir"

cp "${scripts_dir}/configuration.sh" "$install_dir"

# check if the workspace is writable
if [ ! -w "$WFJ_WORKDIR" ]; then
  echo "The workspace $WFJ_WORKDIR is not writable. Please make sure that you have write permissions."
  exit 1
fi

echo "installing crontab"
echo "* * * * * ${scripts_dir}/watch_for_jobs.sh >> $WFJ_LOG 2>&1" | crontab - 

echo "Installation successful."
