import sys
import os
from pathlib import Path
import numpy as np
from utils import MyDataGenerator
from n2v.models import N2V
import csbdeep.io
# from biapol_taurus import ProjectFileTransfer
from utils import load_config

if __name__ == "__main__":
    print(f"Arguments count: {len(sys.argv)}")
    for i, arg in enumerate(sys.argv):
        print(f"Argument {i:>6}: {arg}")

    # define paths
    source_file = Path(sys.argv[1])
    data_dir = source_file.parent
    model_dir = data_dir / 'model'
    target_dir = data_dir / "denoised"
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # load config
    config = load_config(data_dir / 'workflow' / 'config.json')

    # load model
    assert model_dir.exists(), 'No "model" directory containing a trained model found in {}'.format(str(model_dir))
    models = model_dir.glob("*")
    model_name = next(models).name
    model = N2V(config=None, name=model_name, basedir=str(model_dir))

    # load data
    datagen = MyDataGenerator()
    imgs = datagen.load_imgs([source_file], dims=config['axes'])
    image = imgs[0].squeeze()
    print("Image shape: ", image.shape)

    # calculate tiling so that the tiles fit into the GPU memory
    # on the A100 GPUs (48GB memory), the maximum tile size is approximately 3 MB
    n_tiles = image.size / (3 * 2**20)
    tiles = (1, np.ceil(np.sqrt(n_tiles)), np.ceil(np.sqrt(n_tiles)))
    print("Tiling image: ", tiles)

    # predict
    pred = model.predict(image, axes='ZYX', n_tiles=tiles)
    print("Prediction shape: ", pred.shape)

    # save prediction
    target_path = target_dir / (source_file.name + '_N2V.tif')
    print("Saving: ", str(target_path))
    csbdeep.io.save_tiff_imagej_compatible(target_path, pred.astype(np.float32), 'ZYX')
    print('Done')


    