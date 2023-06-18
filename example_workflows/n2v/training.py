from pathlib import Path
from warnings import warn


def train_model(training_data_dir: Path, model_dir: Path, config: dict):
    from utils import MyDataGenerator, supported_filetypes
    from n2v.models import N2VConfig, N2V
    assert model_dir.exists(), "Model dir does not exist: {}".format(str(model_dir))
    datagen = MyDataGenerator()
    print("training")
    print("Model dir: ", str(model_dir))

    # set some default values for config
    if 'train_batch_size' not in config.keys():
        config['train_batch_size'] = 128
    if 'axes' not in config.keys():
        config['axes'] = 'ZYXC'
        warn(f"Axes not configured, using default: {config['axes']}")

    files = []
    for ext in supported_filetypes:
        files += list(training_data_dir.glob('*' + ext))
    img_list = datagen.load_imgs(files, dims=config['axes'])
    patches = datagen.generate_patches_from_list(img_list, shape=config['n2v_patch_shape'])
    print("Patch shape: ", patches.shape)

    # The patches are non-overlapping, so we can split them into train and validation data.
    frac = int((patches.shape[0]) * 5.0 / 100.0)
    X = patches[frac:]
    X_val = patches[:frac]

    # calculate steps per epoch so that all data is used for training each epoch
    if 'train_steps_per_epoch' not in config.keys():
        config['train_steps_per_epoch'] = int(X.shape[0] / config['train_batch_size'])

    print(
        f"total no. of patches: {patches.shape[0]} \ttraining patches: {X.shape[0]} \tvalidation patches: {X_val.shape[0]}")
    config['axes'] = 'ZYXC'
    n2v_config = N2VConfig(X, **config)
    print("config vars: ", vars(n2v_config))
    model_name = "auto_n2v"
    if (model_dir / model_name / 'weights_best.h5').exists():
        n2v_config = None  # this causes N2V to load the existing model rather than overwrite the old one
    model = N2V(config=n2v_config, name=model_name, basedir=str(model_dir))
    print("begin training")
    history = model.train(X, X_val)
    print('training done')
