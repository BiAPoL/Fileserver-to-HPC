#!/bin/bash

#SBATCH --job-name="cleanup_n2v"
#SBATCH --time=01:00:00

# Setup computational environment, i.e, load desired modules
# module purge
# module load <module name>

WSDIR=$1

WSNAME=$(basename "$WSDIR")
WSNAME=${WSNAME#"${USER}"-}
WSPART=${WSDIR#/}
WSPART=${WSPART%%/*}

target_dir=$2

# Execute parallel application
echo "WSDIR: $WSDIR"
echo "WSPART: $WSPART"
echo "WSNAME: $WSNAME"
echo "target dir: $target_dir"
echo "moving model"
rsync -av "$WSDIR"/model "$target_dir"/
echo "moving denoised data"
mkdir -p "$target_dir"/denoised
mv "$WSDIR"/*.tif "$target_dir"/denoised/
echo "releasing cache workspace"
ws_release -F "$WSPART" "$WSNAME"
if [ -e "$target_dir/after/" ]; then
    echo "running postprocessing scripts..."
    find "$target_dir/after/" -name "*.sh" -exec {} \;
fi
