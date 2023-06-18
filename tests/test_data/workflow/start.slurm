#!/bin/bash
#SBATCH --job-name=process_test

echo "working directory: $(pwd)"

mkdir ../results

echo "copy job id: $COPY_JOB_ID"

dependencies=()
for file in ../*.txt; do
    echo "submitting job for $file"
    dependencies+=("$( sbatch --parsable --dependency=afterok:"$COPY_JOB_ID" --output="$TARGET_DIR/log/${file}.out" process.slurm "$file" )")
done
cleanup_dependencies=$(IFS=,; echo "${dependencies[*]}")
echo "submitting cleanup job dependent on jobs with ids: $cleanup_dependencies"
sbatch --job-name=cleanup_process_test --dependency=afterany:"$cleanup_dependencies" --export=SOURCE_DIR,TARGET_DIR --output="$TARGET_DIR/log/cleanup.out" cleanup.slurm
