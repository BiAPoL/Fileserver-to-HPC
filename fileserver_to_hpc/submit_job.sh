#!/bin/bash

relative_path=${1%%/}

# shellcheck source=configuration.sh
source "$HOME"/.fileserver_to_hpc/configuration.sh

# allocate a workspace
workspace_dir=$($SSH_COMMAND ws_allocate -F scratch -n fileserver_to_hpc -d 10)

# create a directory for the job
export TARGET_DIR=$workspace_dir/$relative_path/
export SOURCE_DIR=${HPC_WORKDIR%%/}/$relative_path/
$SSH_COMMAND "mkdir -p \"$TARGET_DIR\"" || (echo "failed to create directory $TARGET_DIR" && exit 1)

# test if SSH_COMMAND is empty
if [ -z "$SSH_COMMAND" ]; then
    hostname=""
else
    hostname=${SSH_COMMAND##ssh }:
fi

# make sure that the workflow files are availabel on the workspace
scp $WFJ_WORKDIR/"${relative_path}/workflow.zip" "${hostname}$TARGET_DIR" || (echo "failed to copy workflow files to $TARGET_DIR" && exit 1)
$SSH_COMMAND "unzip -o \"$TARGET_DIR\"workflow.zip -d \"$TARGET_DIR\"" || (echo "failed to unzip workflow files in $TARGET_DIR" && exit 1)
$SSH_COMMAND "rm \"$TARGET_DIR\"workflow.zip"

# copy the job to the workspace
echo "starting copy job from $SOURCE_DIR to $TARGET_DIR"
COPY_JOB_ID=$( $SSH_COMMAND "${COPY_PREFIX}rsync -r \"$SOURCE_DIR\" \"$TARGET_DIR\"" ) || (echo "failed to start copy job" && exit 1)
export COPY_JOB_ID=${COPY_JOB_ID##* }
echo "copy job id: $COPY_JOB_ID"

$SSH_COMMAND "mkdir -p \"$TARGET_DIR/log\""

# submit the job
job_id=$( $SSH_COMMAND "export SOURCE_DIR=$SOURCE_DIR; export TARGET_DIR=$TARGET_DIR; export COPY_JOB_ID=$COPY_JOB_ID; sbatch --dependency=\"$COPY_JOB_ID\" --export=SOURCE_DIR,TARGET_DIR,COPY_JOB_ID --parsable --output=\"$TARGET_DIR/log/start.out\" --chdir=\"$TARGET_DIR/workflow/\" \"$TARGET_DIR/workflow/start.slurm\"" ) || (echo "failed to start main workflow job" && exit 1)
job_id=${job_id##* }
echo "submitted start job with id: $job_id"
