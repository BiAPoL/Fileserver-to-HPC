#!/bin/bash

#SBATCH --job-name="n2v_predict"
#SBATCH --time=01:00:00
#SBATCH --partition=alpha
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=10312M

date

data_dir=$(dirname "$1")
src_dir=$data_dir/workflow
SINGULARITY_FILE_DIR=$2

# Execute parallel application
echo "HOME: $HOME"
echo "target_file: $1"
echo "data_dir: $data_dir"
echo "src_dir: $src_dir"
echo "SINGULARITY_FILE_DIR: $SINGULARITY_FILE_DIR"
srun singularity exec -C --writable-tmpfs --nv --pwd "$data_dir" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$data_dir" "$SINGULARITY_FILE_DIR"/devbio-napari_n2v.sif python "$src_dir"/auto_n2v_predict.py "$1"
