# Fileserver2HPC

Monitors a folder and automatically processes new subdirectories on an HPC cluster.

## Usage

1. Copy a n2v configuration file called `config.json` to the same folder as your data

   ```bash
   cp config.json /path/to/data/
   ```

2. Copy your files to the cluster's project space via rsync or scp into the folder

   ```bash
   scp -r /path/to/data <ZIH-username>@taurus.hrsk.tu-dresden.de:<path given by the install script>/<username>/<experiment>`
   ```

   note that the path given by the install script starts looks something like this: `/scratch/ws/0/<zih username>-auto-n2v/`. If you forgot to note it down, the user who installed auto-n2v can find it on the cluster command line by typing `ws_list`.
3.
   * Alternative 1: if you already have a trained model that was trained on data acquired with the same imaging settings and a very similar sample, copy that model into the data folder.

     ```bash
     scp -r /path/to/data/model <ZIH-username>@taurus.hrsk.tu-dresden.de:<path given by the install script>/<username>/<experiment>/
     ```

   * Alternative 2: copy some of your data as training data into a subfolder called `training`

     ```bash
     scp -r /path/to/data/training_subset <ZIH-username>@taurus.hrsk.tu-dresden.de:<path given by the install script>/<username>/<experiment>/training
     ```

4. Once the data transfer has finished, create a file called `go` in your *user folder* (e.g. the parent folder of your experiment)

    ```bash
    ssh <ZIH-username>@taurus.hrsk.tu-dresden.de touch <path given by the install script>/<username>/go
    ```

5. After ~ 5 min, the go file should disappear and then some time later, log files will appear in your user folder on the cluster (`/home/<username>/n2v*.log`). You can inspect the log files to track the progress like (replace 123456 with the job number encoded in the log file)

   ```bash
   ssh <ZIH-username>@taurus.hrsk.tu-dresden.de tail -f /home/<username>/n2v-123456.log
   ```

6. After all networks are trained and all files are denoised, the denoised tiff files will appear in `<path given by the install script>/<username>/<experiment>/denoised`. You can transfer them back as follows

   ```bash
   scp -r <ZIH-username>@taurus.hrsk.tu-dresden.de<path given by the install script>/<username>/<experiment>/denoised /path/to/data/
   ```

## Configuration

the `config.json` file is read as a dictionary and passed to N2VConfig as arguments, so all the configuration arguments for N2VConfig are valid. If a variable is left out, the n2v default value is used, with some small exceptions:

Default `train_batch_size` = 128
Default `axes` = 'ZYXC'
Default `train_steps_per_epoch` = number of patches / `train_batch_size` (so that each patch is used for training exactly once per epoch)

Make sure to configure the `axes` variable in the config file correctly. In order to identify, which order your axes are loaded, open the file in Python with [aicsimageio](https://github.com/AllenCellModeling/aicsimageio) and check the property `image.dims.order`

```python
from aicsimageio import AICSImage

image = AICSImage("my_file.tiff")

image.dims.order
```

TCZYX

Depending on the amount of training data you have, it might also be sensible to set the `train_epochs` variable to something other than the default 100. By default, `auto-n2v` uses all your training data exactly once per epoch, so if you have 1GB training data, you probably only need ~10 epochs, while with only 50 MB data, you may need 200.

## Installation

1. If you are not already in the TUD network, open a [VPN connection](https://tu-dresden.de/zih/dienste/service-katalog/arbeitsumgebung/zugang_datennetz/vpn/openvpn)
2. ssh into the cluster: `ssh <ZIH-username>@taurus.hrsk.tu-dresden.de`
3. create a folder for the github repositories:

   ```bash
   mkdir -p workspace
   cd workspace
   ```

4. install the n2v singularity image:

   ```bash
   git clone https://gitlab.mn.tu-dresden.de/bia-pol/singularity-devbio-napari.git
   cd singularity-devbio-napari
   ./install.sh n2v
   ```

5. Clone this github repository

   ```bash
   cd ~/workspace
   git clone https://gitlab.mn.tu-dresden.de/bia-pol/taurus-n2v.git
   ```

6. Call the install script. This will install a cron job in the current login node (e.g. `tauruslogin3`). Make sure you note down which login node that was, in case you need to debug or change the cron job later. Make sure you install the cron job **only on one login node**.

   ```bash
   cd taurus-n2v
   ./install.sh
   ```

7. The install script will create a workspace for the data. Note down that path. This is where you need to put the data to be denoised as [explained above](#usage).
