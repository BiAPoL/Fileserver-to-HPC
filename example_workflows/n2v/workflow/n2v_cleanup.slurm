#!/bin/bash
#SBATCH --partition=romeo

date

if [ -e "$TARGET_DIR/workflow/after/" ]; then
    echo "running postprocessing scripts..."
    find "$TARGET_DIR/workflow/after/" -name "*.sh" -exec {} \;
fi

echo "copying results from $TARGET_DIR to $SOURCE_DIR"
dtrsync -rv "$TARGET_DIR" "$SOURCE_DIR" --blocking || (echo "failed to copy results to $SOURCE_DIR" leaving them in "$TARGET_DIR" && exit 1)
echo "removing $TARGET_DIR"
rm -rf "$TARGET_DIR"
echo "done"