#!/bin/bash

#SBATCH --job-name="evaluate_n2v_test"
#SBATCH --time=01:00:00

# shellcheck source=../src/scripts/configuration.sh
source "$HOME"/.watch_for_jobs/configuration.sh

if [ "$( find "$WFJ_WORKDIR/test/pretrained/denoised/" -name "*_N2V.tif" | wc -l )" -eq 3 ]; then
    echo "pretrained successful"
else
    echo "error with pretrained model"
fi
if [ "$( find "$WFJ_WORKDIR/test/training/denoised/" -name "*_N2V.tif" | wc -l )" -eq 3 ] && [ "$( grep -c "training done" "$WFJ_WORKDIR/test/training/logs/n2v.out"  )" -eq 1 ]; then
    echo "training + denoising successful"
else
    echo "error with training + denoising"
fi
if [ "$( find "$WFJ_WORKDIR/test/missing_results/denoised/" -name "*_N2V.tif" | wc -l )" -eq 3 ] && [ "$( grep -c "Submitted batch job" "$WFJ_WORKDIR/test/missing_results/logs/n2v.out" )" -eq 1 ]; then
    echo "fixing missing results successful"
else
    echo "error fixing missing result"
fi
