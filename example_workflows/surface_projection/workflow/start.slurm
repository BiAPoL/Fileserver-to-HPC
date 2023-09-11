#!/bin/bash
#SBATCH --job-name="surface-projection"
#SBATCH --partition=romeo

if [ -r "$TARGET_DIR/workflow/after/extract_surfaces.slurm" ]; then
    src_dir=$TARGET_DIR/workflow/after
else
    src_dir=$TARGET_DIR/workflow
fi

echo "src_dir: $src_dir"
echo "TARGET_DIR: $TARGET_DIR"

CLEANUP_JOB_ID=$(sbatch --parsable -o "${TARGET_DIR}/log/cleanup_projection.out" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$src_dir"/cleanup.slurm)

# shellcheck source=projection_config.sh
source "$src_dir/projection_config.sh"

dependencies=""
while IFS= read -r -d '' file; do
    file_name=$( basename "$file" )
    if [ -e "${TARGET_DIR}/projected/${file_name%.tif}_projection0.tif" ]; then
        echo "Output ${TARGET_DIR}/projected/${file_name%.tif}_projection0.tif already exists. Skipping $file_name"
    else
        echo "submitting surface-projection job for $file_name"
        job_id=$(sbatch --parsable -o "$TARGET_DIR/log/extract_surfaces-$file_name.out" "$src_dir/extract_surfaces.slurm" "$file")
        dependencies="$dependencies,$job_id"
    fi
done < <(find "${TARGET_DIR}"/denoised/ -name "*.tif" -print0)
if [ -n "$dependencies" ]; then
    # remove leading comma
    dependencies=${dependencies#,}

    echo "update cleanup job dependencies to $dependencies"
    scontrol update job="$CLEANUP_JOB_ID" dependency=afterany:"${dependencies}"
fi