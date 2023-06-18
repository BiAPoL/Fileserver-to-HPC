#!/bin/bash

#SBATCH --job-name="n2v_predict"
#SBATCH --time=08:00:00
#SBATCH --partition=alpha
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=10312M

# Setup computational environment, i.e, load desired modules
# module purge
# module load <module name>

#start the cleanup batch job this will make sure cleanup also happens if the current job was cancelled it can also be used to restart jobs that have timed out
#sbatch -t "00:10:00" -o "n2v-$SLURM_JOB_ID-cleanup.log" --dependency=afterany:$SLURM_JOB_ID n2v_cleanup.slurm "$@"

data_dir=$(dirname "$1")
src_dir=$data_dir/workflow
SIFDIR=$2

# Execute parallel application
echo "HOME: $HOME"
echo "target_file: $1"
echo "data_dir: $data_dir"
echo "src_dir: $src_dir"
echo "SIFDIR: $SIFDIR"
srun singularity exec -C --writable-tmpfs --nv --pwd "$data_dir" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$data_dir" "$SIFDIR"/devbio-napari_n2v.sif python "$src_dir"/auto_n2v_predict.py "$1"
