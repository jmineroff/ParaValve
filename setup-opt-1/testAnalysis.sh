#!/bin/bash

cd "$(dirname "$0")"

echo "./clean.sh"
./clean.sh

echo "mpirun-openmpi-mp -n 1 analysis.exe"
#/opt/local/bin/mpirun-openmpi-mp -n 1 analysis.exe
./run.sh

echo "./postpro_strain.exe 3"
./postpro_strain.exe 3

echo "./viz_shell.exe 3"
./viz_shell.exe 3