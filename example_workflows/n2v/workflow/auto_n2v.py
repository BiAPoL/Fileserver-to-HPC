import sys
import os
from pathlib import Path
from shutil import copytree
from warnings import warn
from utils import load_config, supported_filetypes


def submit_slurm_job(args):
    import subprocess
    process = subprocess.run(args, capture_output=True)
    err = process.stderr.strip().decode('utf-8')
    out = process.stdout.strip().decode('utf-8')
    if len(err) > 0:
        print(f'Job {args} failed with error: {process.stderr}')
    print('out: ', process.stdout)
    jobnum = process.stdout.strip().decode('utf-8').split(' ')[-1]
    return jobnum


def train_model(training_data_dir: Path, model_dir: Path, config_file: Path):
    data_dir = training_data_dir.parent
    args = [
        'sbatch',
        '-o',
        f'"{data_dir / "log" / "n2v_training.out"}"',
        f'"{training_data_dir / "n2v_train.slurm"}"',
        f'"{training_data_dir}"',
        f'"{model_dir}"',
        f'"{config_file}"',
        f'"{os.environ.get("SIFDIR")}"']
    jobnum = submit_slurm_job(args)
    cleanup_job_id = os.environ.get('CLEANUP_JOB_ID')
    args = ['scontrol', 'update', f'job={cleanup_job_id}', f'dependency="afterany:{jobnum}"']
    submit_slurm_job(args)
    return jobnum


def predict(data_dir: Path, model_dir: Path, target_dir: Path, dependency_job_id: str = None):
    files = []
    for type in supported_filetypes:
        files.extend(data_dir.glob('*' + type))
    print("predicting: ", files)
    jobs = []
    src_dir = Path(__file__).parent
    slurmfile = src_dir / 'n2v_predict.slurm'
    for file in files:
        if not (data_dir / "denoised" / (file.name + "_N2V.tif")).exists():
            args = ['sbatch',
                    '-o', f'"{data_dir / "log" / f"{file.name}_n2v.out"}"',
                    f'"{slurmfile}"',
                    f'"{file}"',
                    f'"{os.environ.get("SIFDIR")}"']
            if dependency_job_id is not None:
                new_args = args[:3] + [f'--dependency=afterok:{dependency_job_id}'] + args[3:]
                args = new_args
            jobnum = submit_slurm_job(args)
            jobs.append(jobnum)
        else:
            print("skipping already denoised file: ", str(file))
    jobs = [job for job in jobs if job != '']
    if len(jobs) > 0:
        print("submitted jobs:", jobs)
        cleanup_job_id = os.environ.get('CLEANUP_JOB_ID')
        args = ['scontrol', 'update', f'job={cleanup_job_id}', f'dependency="afterany:{",".join(jobs)}"']
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
        config_file = data_dir / 'workflow' / 'config.json'
        if model_dir.exists():
            models = list(model_dir.glob("*"))
            if len(models) > 0:
                if (training_data_dir / 'continue_training').exists():
                    # if there is training data, and model data
                    if len(models) > 0:
                        if (models[0] / 'config.json').exists():
                            config_file = models[0] / 'config.json'
                        if len(models) > 1:
                            warn(f"found several models. Using the first model: {str(models[0])}")
                else:
                    predict(data_dir=data_dir, model_dir=model_dir, target_dir=target_dir)
                    exit()
        else:
            model_dir.mkdir(parents=True)
        config = load_config(config_file)
        train_model(training_data_dir, model_dir, config_file)
        predict(data_dir=data_dir, model_dir=model_dir, target_dir=target_dir)
