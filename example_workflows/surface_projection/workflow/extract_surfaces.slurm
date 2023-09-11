#!/bin/bash

#SBATCH --job-name="extract_surfaces"
#SBATCH --time=01:00:00
#SBATCH --partition=romeo
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1972

file=$1
denoised=$( dirname "$file" )
data_dir=$( dirname "$denoised" )
out_dir=$data_dir/projected
mkdir -p "$out_dir"

echo "file: $file"
echo "out_dir: $out_dir"

# shellcheck source=projection_config.sh
if [ -r "$TARGET_DIR/workflow/after/extract_surfaces.slurm" ]; then
    src_dir=$TARGET_DIR/workflow/after
else
    src_dir=$TARGET_DIR/workflow
fi

source "$src_dir"/projection_config.sh

 

vars="
   processType='current image'
   processFolder='$denoised'
   processFile='$file'
   useRoi=false
   saveOption=true
   outFolder='$out_dir'

   downsample_factor_xy=$downsample_factor_xy
   downsample_factor_z=$downsample_factor_z
   max_dz=$max_dz
   zMapBlurringRadius=$zMapBlurringRadius

   downsample_factor_xy_fine=$downsample_factor_xy_fine
   downsample_factor_z_fine=$downsample_factor_z_fine
   max_dz_fine=$max_dz_fine
   relativeWeight=$relativeWeight
   surfacesMinDistance=$surfacesMinDistance
   surfacesMaxDistance=$surfacesMaxDistance
"

"$src_dir"/Fiji.app/ImageJ-linux64 \
    --headless \
    --run "$src_dir"/Wing2SurfaceExtraction_ND_v1.4.py "$( echo "$vars" | grep '=' | tr '\012' ',' | sed 's/   //g' | sed 's/,$//' )"
