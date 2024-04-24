#!/bin/env bash

cd ..
mkdir build
cd build

cmake -DCMAKE_PREFIX_PATH=/opt/remus/lib/cmake -DCMAKE_MODULE_PATH=/opt/remus/lib/cmake ..
make -j
