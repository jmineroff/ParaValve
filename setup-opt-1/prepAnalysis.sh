#!/bin/bash

cd "$(dirname "$0")"
#pwd

echo "./clean.sh"
./clean.sh

echo "cp ../geometry/smesh.*.dat ."
cp ../geometry/smesh.*.dat .

echo "cp ../geometry/thickness.dat ."
cp ../geometry/thickness.dat .
