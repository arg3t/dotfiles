#!/bin/bash

for d in */ ; do
  echo "Building in $d..."
  cd $d
  sudo make clean install
  if [ $? -ne 0 ]; then
    echo "An error occured..."
    exit 1
  cd ..
  echo "Done..."
done

echo "All builds done, you might want to check whether any errors has occures
