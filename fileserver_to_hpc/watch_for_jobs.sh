#!/bin/bash
# shellcheck source=configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh
source_dir="$(dirname "$0")"

if test "$(find "$WFJ_LOCKFILE" -mtime -2 2>/dev/null)"; then
  echo "Another instance of $0 is running wait till it finishes or delete $WFJ_LOCKFILE."
else
  touch "$WFJ_LOCKFILE"
  #firstly we search for workflow.zip files in the working directory
  find "$WFJ_WORKDIR" -name workflow.zip | while read -r job; do
    if grep -q 'ignore\|example_workflows' <<< "$job"; then
      #if the directory contains "ignore" or "example_workflows", we ignore it
      echo "Ignoring: ${job%%workflow.zip}"
    else
        #check the size of the logfile and clear it if it gets too big
        if [ "$(du -m "$WFJ_LOG" | awk '{print $1}')" -gt 2 ]; then #if the log file is bigger than 2 megs delete it.
          rm "$WFJ_LOG"
        fi
        echo "enqueuing jobs"
        date
        #we store the directories that have already been processed in this file in the .fileserver_to_hpc directory
        done="${HOME}/.fileserver_to_hpc/watch_for_jobs_done.list"
        # $done.new stores the new directory list. we clear it before we use it
        if [ -f "${done}.new" ]; then rm "${done}.new"; fi
        if grep -q "^$job\$" "$done"; then
          #if the directory is in our $done list, we ignore it
          echo "Directory has already been queued before. Ignoring: $job"
          echo "$job" >> "${done}.new"
        else
          if unzip -t "$job" >/dev/null 2>&1; then
              #if the zip file is valid, we submit the job
              echo "submitting $job"
              echo "$job" >> "${done}.new"
              absolute_path=${job%workflow.zip}
              relative_path=${absolute_path##"$WFJ_WORKDIR"}
              echo "relative path: $relative_path"
              "${source_dir%%/}/submit_job.sh" "$relative_path" && rm -f "$job"
          fi
        fi
        #now we are done and can clean up
        mv "${done}.new" "$done"
      fi
  done
  rm -f "$WFJ_LOCKFILE"
fi
