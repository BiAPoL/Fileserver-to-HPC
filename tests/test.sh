#!/bin/bash
# shellcheck source=../src/scripts/configuration.sh
source "$HOME"/.process_on_hpc/configuration.sh

test_data=/projects/p_bioimage/auto_n2v/till/test_data

rm "$HOME"/.process_on_hpc/watch_for_jobs_done_test.list

echo "cleanup old test data"
rm -r "${WFJ_WORKDIR}test"

echo "set up test denoising only"
mkdir -p "${WFJ_WORKDIR}test/pretrained"
cp "$test_data/config.json" "${WFJ_WORKDIR}test/pretrained/"
cp "$test_data/"*.nd2 "${WFJ_WORKDIR}test/pretrained/"
cp -r "$test_data/model" "${WFJ_WORKDIR}test/pretrained/"

echo "set up test training and prediction"
mkdir -p "${WFJ_WORKDIR}test/training"
cp "$test_data/config.json" "${WFJ_WORKDIR}test/training/"
cp "$test_data/"*.nd2 "${WFJ_WORKDIR}test/training/"
mkdir "${WFJ_WORKDIR}test/training/training/"
cp "${WFJ_WORKDIR}test/training/Time00003_Point0000_Channel488_Seq0003.nd2" "${WFJ_WORKDIR}test/training/training/"

echo "set up test denoising only of one missing result"
mkdir -p "${WFJ_WORKDIR}test/missing_results"
cp -r "$test_data/"* "${WFJ_WORKDIR}test/missing_results"

echo "trigger processing with watch_for_jobs"
touch "${WFJ_WORKDIR}test/go"

echo "waiting for all three test jobs to start"
while [ "$( squeue -u "$USER" --format %j | grep -c cleanup_n2v )" -lt 3 ]; do
    sleep 2
done

echo "detected n2v cleanup jobs:"
squeue -u "$USER"

echo "starting job that evaluates test results after all running jobs are done"
# shellcheck disable=SC2207
job_ids=($(squeue -u "$USER" --format %i))
unset "job_ids[0]"
job_id_string=$(IFS=, ; echo "${job_ids[*]}")
echo "cleanup job dependencies: $job_id_string"
sbatch "--dependency=afterany:$job_id_string" evaluate_test.slurm