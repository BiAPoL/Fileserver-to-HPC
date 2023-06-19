#!/bin/bash
#SBATCH --job-name=start_test
#SBATCH --partition=romeo

echo "working directory: $(pwd)"

mkdir ../results

echo "copy job id: $COPY_JOB_ID"
echo "source dir: $SOURCE_DIR"
echo "target dir: $TARGET_DIR"

mkdir -p "${TARGET_DIR}results"

dependencies=()
for file in "$TARGET_DIR"*.txt; do
    echo "submitting job for $file"
    filename=$(basename "$file")
    outputfile="${TARGET_DIR}log/${filename%.*}.out"
    dependencies+=("$( sbatch --parsable --output="$outputfile" process.slurm "$file" )")
done
cleanup_dependencies=$(IFS=,; echo "${dependencies[*]}")
echo "submitting cleanup job dependent on jobs with ids: $cleanup_dependencies"
sbatch --job-name=cleanup_process_test --dependency=afterany:"$cleanup_dependencies" --export=SOURCE_DIR,TARGET_DIR --output="$TARGET_DIR/log/cleanup.out" cleanup.slurm
