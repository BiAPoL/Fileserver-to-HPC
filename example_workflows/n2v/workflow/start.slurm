#!/bin/bash

#SBATCH --job-name="n2v"
#SBATCH --time=08:00:00
#SBATCH --partition=romeo
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1972

# Setup computational environment, i.e, load desired modules
# module purge
# module load <module name>

date

# Allocate workspace for singularity images
SINGULARITY_FILE_DIR=$(ws_allocate -F beegfs -n "singularity" -d 30)
export SINGULARITY_FILE_DIR
echo "Workspace for singularity images: ${SINGULARITY_FILE_DIR}"
# Check allocation
[ -z "${SINGULARITY_FILE_DIR}" ] && echo "Error: Cannot allocate workspace $SINGULARITY_FILE_DIR" && exit 1

# Pull singularity image from registry
container_registry=oras://gitlab.mn.tu-dresden.de:8000/bia-pol/singularity-devbio-napari:n2v
singularity pull "${SINGULARITY_FILE_DIR}/devbio-napari_n2v.sif" "${container_registry}"
# check if image file is readable
[ -r "${SINGULARITY_FILE_DIR}/devbio-napari_n2v.sif" ] || (echo "failed to pull singularity image from registry to $SINGULARITY_FILE_DIR" && exit 1)

WORKSPACE_DIR=$(dirname "$(pwd)")

src_dir=$WORKSPACE_DIR/workflow

#start the cleanup batch job this will make sure cleanup also happens if the current job was cancelled it can also be used to restart jobs that have timed out
if [ -e "$src_dir/after/start.slurm" ]; then
    echo "running postprocessing scripts..."
    export data_path=$WORKSPACE_DIR
    CLEANUP_JOB_ID=$(sbatch --parsable -o "$WORKSPACE_DIR/log/after_n2v.out" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$src_dir/after/start.slurm")
else
    CLEANUP_JOB_ID=$(sbatch --parsable -o "${WORKSPACE_DIR}/log/cleanup_n2v.out" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$src_dir"/n2v_cleanup.slurm "$WORKSPACE_DIR")
fi
export CLEANUP_JOB_ID
echo "queued cleanup job: $CLEANUP_JOB_ID"

# Execute parallel application
echo "CLEANUP_JOB_ID: $CLEANUP_JOB_ID"
echo "HOME: $HOME"
echo "WORKSPACE_DIR: $WORKSPACE_DIR"
echo "src_dir: $src_dir"
if [ -e "$src_dir/before/" ]; then
    export data_path=$WORKSPACE_DIR
    echo "running preprocessing scripts..."
    find "$1/before/" -name "*.sh" -exec {} \;
fi

srun singularity exec -C --env "SINGULARITY_FILE_DIR=$SINGULARITY_FILE_DIR,CLEANUP_JOB_ID=$CLEANUP_JOB_ID" --writable-tmpfs --nv --pwd "$1" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$WORKSPACE_DIR" "${SINGULARITY_FILE_DIR}"/devbio-napari_n2v.sif python "$src_dir"/auto_n2v.py "$WORKSPACE_DIR"
