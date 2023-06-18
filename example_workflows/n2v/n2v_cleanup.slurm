#!/bin/bash
#SBATCH --partition=datamover

rsync -rv "$TARGET_DIR" "$SOURCE_DIR" || (echo "failed to copy results to $SOURCE_DIR" leaving them in "$TARGET_DIR" && exit 1)
rm -rf "$TARGET_DIR"