# ParaValve

ParaValve is the automation pipeline for geometric generation and optimization of a bioprosthetic heart valve. ParaValve does not include an analysis tool for valve optimization, but is easily adapted to work with one of your choice.The framework was originally developed to work with an isogeometric analysis (IGA) software developed by [CFSI Lab](https://web.me.iastate.edu/jmchsu/) at Iowa State University.

## Features
* The Grasshopper files have a large number of parameters for a wide range of possible geometries
* Since geometry was generated by running Rhino/Grasshopper in a Windows VM, there are a number of flags and checks that validate proper data transfer
* Models are evaluated in parallel during the optimization 
* Results are logged and queried to prevent duplicate model evaluations

## Dependencies
It uses [Rhino/Grasshopper](https://www.rhino3d.com/6/new/grasshopper) to generate the geometry.

This program also uses solvers from the [Matlab Optimization Toolbox](https://www.mathworks.com/products/optimization.html).

## Installation
1. Clone the ParaValve repository
2. Create a 'matlabAnalysis' view in Rhino (white surfaces on black)
3. Compile 'brep_...' and import the plugin to Rhino to create the smesh files for analysis
3. Manually modify funCurve.m to work with your analysis tool

## Using CircOpt
1. Run 'geometry/geoExport...rvb' in Rhino to prime the geometry pipeline
2. Run 'optCurve.m' in Matlab to begin the optimization

## File Organization
* 'optCurve.m': Matlab optimization manager
* 'funCurve.m': Manager for each function evaluation. Coordinates with Rhino queue to create geometry based on input parameters
* 'geometry/': Folder containing all files for geometry generation in Windows VM
* 'geometry/geoExport...rvb': Rhinoscript file that generates geometry and sets/reads flags to coordinate with Matlab evaluators
* 'setup-opt-.../': Work folder for a specific Matlab process worker
* 'sync/': Folder with global worker process information
* 'samples/': Representative samples of the range of possible geometries

## Publications
1. Ming-Chen Hsu, David Kamensky, Fei Xu, Josef Kiendl, Chenglong Wang, Michael CH Wu, Joshua Mineroff, Alessandro Reali, Yuri Bazilevs, and Michael S Sacks (2015). Dynamic and Fluid–Structure Interaction Simulations of Bioprosthetic Heart Valves Using Parametric Design with T-splines and Fung-type Material Models. _Computational Mechanics_
2. Joshua Mineroff, Ming-Chen Hsu, and Baskar Ganapathysubramanian (2013). Optimization of the Parametric Design of a Bioprosthetic Heart Valve Using Isogeometric Analysis. _US National Congress on Computational Mechanics_

## Licensing
This code is licensed under MIT license.
