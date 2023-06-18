#!/bin/bash

#SBATCH --job-name="n2v"
#SBATCH --time=08:00:00
#SBATCH --partition=alpha
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=10312M

# Setup computational environment, i.e, load desired modules
# module purge
# module load <module name>


# Allocate workspace as working directory
WSNAME=cache_${SLURM_JOB_ID}
WSDIR=$(ws_allocate -F scratch -n "${WSNAME}" -d 10)
export WSDIR
echo "Workspace: ${WSDIR}"
# Check allocation
[ -z "${WSDIR}" ] && echo "Error: Cannot allocate workspace {$WSNAME}" && exit 1


src_dir=$(dirname "$(dirname "$WFJ_JOB")")

#start the cleanup batch job this will make sure cleanup also happens if the current job was cancelled it can also be used to restart jobs that have timed out
CLEANUP_JOB_ID=$(sbatch -o "${1}/log/cleanup_n2v.out" --dependency=afterany:$SLURM_JOB_ID "$src_dir"/scripts/n2v_cleanup.slurm "$WSDIR" "$1")
CLEANUP_JOB_ID=${CLEANUP_JOB_ID##* }
export CLEANUP_JOB_ID
echo "queued cleanup job: $CLEANUP_JOB_ID"

# Execute parallel application
echo "CLEANUP_JOB_ID: $CLEANUP_JOB_ID"
echo "HOME: $HOME"
echo "WSDIR: $WSDIR"
echo "data path: $1"
echo "src_dir: $src_dir"
if [ -e "$1/before/" ]; then
    export data_path=$1
    echo "running preprocessing scripts..."
    find "$1/before/" -name "*.sh" -exec {} \;
fi

srun singularity exec -C --env "WSDIR=$WSDIR,CLEANUP_JOB_ID=$CLEANUP_JOB_ID" --writable-tmpfs --nv --pwd "$1" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$1" -B "$WSDIR" -B "$src_dir" ~/singularity-images/devbio-napari_n2v.sif python "$src_dir"/auto_n2v.py "$1"
