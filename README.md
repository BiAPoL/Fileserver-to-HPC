# Fileserver to HPC

Monitors a folder and automatically processes new subdirectories on an HPC cluster.

## Usage

1. Copy your data to the folder on the fileserver that is monitored by Fileserver to HPC. For example `//fileserver/process_on_hpc/my_data`
2. Copy the entire workflow folder into the same folder. For example `//fileserver/process_on_hpc/my_data/workflow`. The workflow folder **must contain a file called `start.slurm`**.
3. Once the data and the workflow are ready for processing, compress the workflow folder into a zip file. For example: `//fileserver/process_on_hpc/my_data/workflow.zip`
4. After ~ 1 min, the `zip` file will disappear. This means that processing on the cluster has started.
5. Once processing is done, the workflow will make sure that the results are transferred back to the fileserver (see [Creating your own workflow](#creating-your-own-workflow) below for how this can be implemented).

## Creating your own workflow

The `start.slurm` file should handle processing of your data and make sure that the results are synchronized back to the fileserver. In order to be able to do that, there are several environment variables set:

* `SOURCE_DIR` contains the path to the data on the fileserver from the perspective of the HPC cluster. For example: `/grp/g_biapol/process_on_cluster/`
* `TARGET_DIR` contains the path to the workspace on the cluster where the processing happens
* On the TUD cluser, only the `datamover` partition is able to access the `SOURCE_DIR`. Therefore, our workflows start a separate job that runs a small `cleanup.slurm` file after the start.slurm job is done like this:

     ```bash
     CLEANUP_JOB_ID=$(sbatch -o "${TARGET_DIR}/log/cleanup.out" --dependency=afterany:"$SLURM_JOB_ID" --export=ALL "$TARGET_DIR"/workflow/cleanup.slurm)
     ```

* `cleanup.slurm` looks like this:

     ```bash
     #!/bin/bash
     # SBATCH --partition=datamover

     echo "copying results from $TARGET_DIR to $SOURCE_DIR"
     rsync -rv "$TARGET_DIR" "$SOURCE_DIR" || (echo "failed to copy results to $SOURCE_DIR" leaving them in "$TARGET_DIR" && exit 1)
     echo "removing $TARGET_DIR"
     rm -rf "$TARGET_DIR"
     echo "done"
     ```

Check out [the example workflows](https://github.com/BiAPoL/Fileserver-to-HPC/tree/main/example_workflows) for templates.
