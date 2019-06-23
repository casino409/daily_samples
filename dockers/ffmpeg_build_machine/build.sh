#!/bin/bash

name='ffmpeg_build'
bin_path=$(realpath build)

if [ -d "$bin_path" ]; then
  echo "Warning: $bin_path exists. It would be overrided."
  rm -rd "$bin_path"
fi

docker build -t $name -f Dockerfile data
mkdir -p "$bin_path"
docker run -it --rm -v "$bin_path":/result $name

