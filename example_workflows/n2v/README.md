# Noise 2 Void Workflow

Workflow for Fileserver to HPC that applies [Noise2Void](https://github.com/juglab/n2v) to your data.

(1) Krull, A.; Buchholz, T.-O.; Jug, F. Noise2Void - Learning Denoising from Single Noisy Images. arXiv.org. <https://arxiv.org/abs/1811.10980v2> (accessed 2023-06-19).

## Usage

1. Copy your data to the folder on the fileserver that is monitored by Fileserver to HPC. For example `//fileserver/process_on_hpc/my_data`
2. Copy the entire workflow folder into the same folder. For example `//fileserver/process_on_hpc/my_data/workflow`
3. Make sure that the configuration file `//fileserver/process_on_hpc/my_data/workflow/config.json` is correct. See the [Configuration section](#configuration) below for details.
4. You need a trained n2v model. There are two options of how to get one:
   * If you already have a trained n2v model, copy it into a folder called `models`. For example `//fileserver/process_on_hpc/my_data/models/my_n2v_model`
   * If you do not have a trained n2v model, copy some files that are typical for your data into a subfolder called `training`. It is recommended to copy ~ 1GB of data into the `training` folder if your data is larger, crop it. If it is smaller, increase the number of epochs accordingly (e.g. if you only have 0.5 GB, then use 60 Epochs)
5. Once all your data is transferred and the configuration is correct, compress the workflow folder into a zip file. For example: `//fileserver/process_on_hpc/my_data/workflow.zip`
6. After ~ 1 min, the zip file should disappear. This means that the processing on the cluster has started.
7. Some time later, a folder called `denoised`, containing your denoised data, will appear. For example:`//fileserver/process_on_hpc/my_data/workflow.zip`

   The time may range from minutes to many hours, depending on whether or not you need to train a new n2v model, the total amount of data to be denoised and how busy the cluster is.
8. If you want the same data to be processed again, (e.g. if you want to train longer):
   * delete the files you want to be processed again from the `denoised` folder
   * if you want to re-train, delete the `model` folder (and increase the number of epochs in `config.json`)
   * rename your data folder. For example from `//fileserver/process_on_hpc/my_data` to `//fileserver/process_on_hpc/my_data1`

## Troubleshooting

If something is not working, try to look through the log files in the `log` folder. For example `//fileserver/process_on_hpc/my_data/log`. The most common issue are out of memory errors, which may be fixed by reducing the size of individual files. For example by splitting into separate files for each time point or by tiling your images.

If that does not help, please do not hesitate to [open a new issue](https://github.com/BiAPoL/Fileserver-to-HPC/issues/new?&template=bug_report.md), detailing the path to your data on the fileserver, what actually happened and what you expected to happen.

## Configuration

the `config.json` file is read as a dictionary and passed to N2VConfig as arguments, so all the configuration arguments for N2VConfig are valid. If a variable is left out, the n2v default value is used, with some small exceptions:

Default `train_batch_size` = 128
Default `axes` = 'TCZYX'
Default `train_steps_per_epoch` = number of patches / `train_batch_size` (so that each patch is used for training exactly once per epoch)

Make sure to configure the `axes` variable in the config file correctly. In order to identify, which order your axes are loaded, open the file in Python with [aicsimageio](https://github.com/AllenCellModeling/aicsimageio) and check the property `image.dims.order`

```python
from aicsimageio import AICSImage

image = AICSImage("my_file.tiff")

image.dims.order
```

TCZYX

Note that by default, AICSImageIO re-orders (and adds) axes if necessary so that the axes are `[Time, Channel, Z, Y, X]`   so `"axes": "TCZYX"` is likely correct, even though your raw data may have a different axes layout. The default config looks like this:

   ```yaml
   {
    "axes": "TCZYX",
    "train_epochs": 30,
    "n2v_patch_shape": [
        16,
        64,
        64
    ]
   }
   ```

Depending on the amount of training data you have, it might also be sensible to set the `train_epochs` variable to something other than the default 100. By default, `auto-n2v` uses all your training data exactly once per epoch, so if you have 1GB training data, you probably only need ~30 epochs, while with only 50 MB data, you may need 200.
