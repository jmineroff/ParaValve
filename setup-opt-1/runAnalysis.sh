#!/bin/bash

cd "$(dirname "$0")"
#pwd

echo $$ > bashPID.txt

echo "mpirun-openmpi-mp -n 1 analysis.exe"
mpirun-openmpi-mp -n 1 ../code-press-nonlin-80mmHg/bin/analysis.exe > output.txt

echo "./postpro_strain.exe 3"
./postpro_strain.exe 3

echo "./viz_shell.exe 3"
./viz_shell.exe 3

printf 1 > bashComplete.txt