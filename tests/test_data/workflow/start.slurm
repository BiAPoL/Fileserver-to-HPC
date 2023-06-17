#!/bin/bash
#SBATCH --job-name=process_test

mkdir ../results
dependencies=()
for file in ../*.txt; do
    dependencies+=("$( sbatch --parsable --dependency=afterok:"$COPY_JOB_ID" --output="$TARGET_DIR/log/${file}.out" process.slurm "$file" )")
done
cleanup_dependencies=$(IFS=,; echo "${dependencies[*]}")
sbatch --job-name=cleanup_process_test --dependency=afterany:"$cleanup_dependencies" --export=SOURCE_DIR,TARGET_DIR --output="$TARGET_DIR/log/cleanup.out" cleanup.slurm
