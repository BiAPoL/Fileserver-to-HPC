#!/bin/bash

#SBATCH --job-name="n2v"
#SBATCH --time=08:00:00
#SBATCH --partition=alpha
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=10312M

# Setup computational environment, i.e, load desired modules
# module purge
# module load <module name>

date

# Allocate workspace for singularity images
SIFDIR=$(ws_allocate -F beegfs -n "singularity" -d 30)
export SIFDIR
echo "Workspace for singularity images: ${SIFDIR}"
# Check allocation
[ -z "${SIFDIR}" ] && echo "Error: Cannot allocate workspace $SIFDIR" && exit 1

# Pull singularity image from registry
container_registry=oras://gitlab.mn.tu-dresden.de:8000/bia-pol/singularity-devbio-napari:n2v
singularity pull "${SIFDIR}/devbio-napari_n2v.sif" "${container_registry}"
# check if image file is readable
[ -r "${SIFDIR}/devbio-napari_n2v.sif" ] && echo "failed to pull singularity image from registry to $SIFDIR" && exit 1

WSDIR=$(dirname "$(pwd)")

src_dir=$WSDIR/workflow

#start the cleanup batch job this will make sure cleanup also happens if the current job was cancelled it can also be used to restart jobs that have timed out
if [ -e "$src_dir/after/start.slurm" ]; then
    echo "running postprocessing scripts..."
    export data_path=$WSDIR
    CLEANUP_JOB_ID=$(sbatch --parsable -o "$WSDIR/log/after_n2v.log" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$src_dir/after/start.slurm")
else
    CLEANUP_JOB_ID=$(sbatch --parsable -o "${WSDIR}/log/cleanup_n2v.out" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$src_dir"/n2v_cleanup.slurm "$WSDIR")
fi
export CLEANUP_JOB_ID
echo "queued cleanup job: $CLEANUP_JOB_ID"

# Execute parallel application
echo "CLEANUP_JOB_ID: $CLEANUP_JOB_ID"
echo "HOME: $HOME"
echo "WSDIR: $WSDIR"
echo "src_dir: $src_dir"
if [ -e "$src_dir/before/" ]; then
    export data_path=$WSDIR
    echo "running preprocessing scripts..."
    find "$1/before/" -name "*.sh" -exec {} \;
fi

srun singularity exec -C --env "SIFDIR=$SIFDIR,CLEANUP_JOB_ID=$CLEANUP_JOB_ID" --writable-tmpfs --nv --pwd "$1" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$WSDIR" "${SIFDIR}"/devbio-napari_n2v.sif python "$src_dir"/auto_n2v.py "$WSDIR"
