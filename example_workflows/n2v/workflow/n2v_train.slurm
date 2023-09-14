#!/bin/bash

#SBATCH --job-name="n2v_train"
#SBATCH --time=08:00:00
#SBATCH --partition=alpha
#SBATCH --cpus-per-task=24
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=10312M

date

data_dir=$(dirname "$1")
src_dir=$data_dir/workflow
SIFDIR=$4

# Print out variables
echo "HOME: $HOME"
echo "data_dir: $data_dir"
echo "src_dir: $src_dir"
echo "taining_data_dir: $1"
echo "model_dir: $2"
echo "config_file: $3"

# Execute trining in singularity container
srun singularity exec -C --writable-tmpfs --nv --pwd "$data_dir" -B "$HOME/.ssh:/.ssh" -B "/etc/OpenCL" -B "$data_dir" "$SIFDIR"/devbio-napari_n2v.sif python "$src_dir"/auto_n2v_train.py "$1" "$2" "$3"
