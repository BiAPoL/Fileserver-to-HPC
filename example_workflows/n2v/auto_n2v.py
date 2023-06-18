import sys
import os
from pathlib import Path
from shutil import copytree
from warnings import warn
# from biapol_taurus import ProjectFileTransfer
from training import train_model
from utils import load_config, supported_filetypes

def submit_slurm_job(args):
    import subprocess
    process = subprocess.run(args, capture_output=True)
    print('err: ', process.stderr)
    print('out: ', process.stdout)
    jobnum = process.stdout.strip().decode('utf-8').split(' ')[-1]
    return jobnum


def predict(data_dir: Path, model_dir: Path, target_dir: Path):
    files = []
    for type in supported_filetypes:
        files.extend(data_dir.glob('*' + type))
    print("predicting: ", files)
    jobs = []
    src_dir = Path(__file__).parent
    slurmfile = src_dir / 'n2v_predict.slurm'
    for file in files:
        if not (data_dir / "denoised" / (file.name + "_N2V.tif")).exists():
            args = ['sbatch', '-o', str(data_dir / 'log' / (file.name + '_n2v.out')), str(slurmfile), str(file), os.environ.get('SIFDIR')]
            jobnum = submit_slurm_job(args)
            jobs.append(jobnum)
        else:
            print("skipping already denoised file: ", str(file))
    print("submitted jobs:", jobs)
    cleanup_job_id = os.environ.get('CLEANUP_JOB_ID')
    args = ['scontrol', 'update', 'job=' + cleanup_job_id, 'dependency="afterany:' + ','.join(jobs) + '"']
    submit_slurm_job(args)
    print("updated cleanup job dependencies")


if __name__ == "__main__":
    print(f"Arguments count: {len(sys.argv)}")
    for i, arg in enumerate(sys.argv):
        print(f"Argument {i:>6}: {arg}")
    data_dir = Path(sys.argv[1])
    target_dir = data_dir / "denoised"
    target_dir.mkdir(parents=True, exist_ok=True)
    model_dir = data_dir / 'model'
    if not (data_dir / 'training').exists():
        # if there is no training data, we try to apply an already trained model
        assert model_dir.exists(), 'Need either a subdirectory called "training" containing training data for a new model or a subdirectory called "model" containing a trained model.'
        predict(data_dir=data_dir, model_dir=model_dir, target_dir=target_dir)
    else:
        training_data_dir = (data_dir / 'training')
        if model_dir.exists():
            if (training_data_dir / 'continue_training').exists():
                # if there is training data, and model data
                models = model_dir.glob("*")
                if len(models) > 0:
                    config = load_config(models[0] / 'config.json')
                    if len(models) > 1:
                        warn(f"found several models. Using the first model: {str(models[0])}")
                elif (training_data_dir / 'config.json').exists():
                    config = load_config(training_data_dir / 'config.json')
                else:
                    config = load_config(data_dir / 'workflow' / 'config.json')
            else:
                predict(data_dir=data_dir, model_dir=model_dir, target_dir=target_dir)
                exit()
        else:
            model_dir.mkdir(parents=True)
            config_file = training_data_dir / 'config.json'
            if not (config_file).exists():
                config_file = data_dir / 'workflow' / 'config.json'
            config = load_config(config_file)
        train_model(training_data_dir, model_dir, config)
        predict(data_dir=data_dir, model_dir=model_dir, target_dir=target_dir)
    
