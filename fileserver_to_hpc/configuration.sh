#!/bin/bash
# shellcheck disable=SC2034
#WFJ_WORKDIR is where we look for the 'workflow.zip' file and where the folders containing the data are
WFJ_WORKDIR="/mnt/fileserver/process_on_taurus/"

#HPC_WORKDIR is where the workspace is mounted on the HPC cluster
HPC_WORKDIR="/grp/p_biapol/process_on_taurus/"

#WFJ_LOCKFILE prevents the script from being run multiple times. In order to prevent permanent lockup in case of a crash the lockfile is ignored if it is older than two days
WFJ_LOCKFILE="/tmp/watch_for_jobs.lock"

#WFJ_LOG keeps track of the output when we run as a cron job
WFJ_LOG="${HOME}/.process_on_hpc/watch_for_jobs.log"

#WFJ_JOB the name of the slurm file that is to be executed via sbatch
SUBMIT_JOB="${HOME}/.process_on_hpc/submit_job.sh"

#define the ssh command that is used to connect to the HPC cluster, set to empty string "" if watch_for_jobs is run on the HPC cluster
SSH_COMMAND="ssh taurus"

#prefix for the command used for copying data to the workspace of the HPC cluster
COPY_PREFIX="dt"