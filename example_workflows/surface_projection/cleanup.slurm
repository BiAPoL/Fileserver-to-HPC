#!/bin/bash
#SBATCH --partition=datamover

date

echo "copying results from $TARGET_DIR to $SOURCE_DIR"
rsync -rv "$TARGET_DIR" "$SOURCE_DIR" || (echo "failed to copy results to $SOURCE_DIR" leaving them in "$TARGET_DIR" && exit 1)
echo "removing $TARGET_DIR"
rm -rf "$TARGET_DIR"
echo "done"