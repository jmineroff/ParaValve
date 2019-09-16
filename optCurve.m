clear all
clc

%% Start Parallelization

par = 0; % 1; % Use parallel

if par
    if max(size(gcp)) == 0 % Parallel pool needed
        parpool(6) % Create the parallel pool
    end
    
    pool = gcp;
    poolSize = pool.NumWorkers;
else
    poolSize = 1;
end

%% Initialize Shared Folders

csvwrite('sync/current.dat',1);
csvwrite('results/results.txt',zeros(1,26));

%% Parameters and Options

LB = [-0.5, 0,-30,0,0.02];
UB = [ 0.3,40, 80,1,0.0386];

%options = gaoptimset('PopulationSize',40,'Generations',50,'Display','iter','TolFun',0.005,'StallGenLimit',10,'UseParallel',false);

%multiopt = gaoptimset(@gamultiobj);
%options = gaoptimset(multiopt,'TimeLimit',32000,'PopulationSize',40,'Generations',300,'Display','final','TolFun',0.001,'StallGenLimit',10,'UseParallel',false);

%% Optimization

[XminP,SminP] = patternsearch(@(x)funCurve(x,poolSize),[-0.269,0.331,6.735,0.615,0.0386],[],[],[],[],LB,UB);
save('curveResult.mat')
[XminG,SminG] = ga(@(x)funCurve(x,poolSize),5,[],[],[],[],LB,UB,[]);
save('curveResult.mat')
[XminGP,SminGP] = patternsearch(@(x)funCurve(x,poolSize),XminG,[],[],[],[],LB,UB);
save('curveResult.mat')
[Xpar,Fpar] = gamultiobj(@(x)funCurve(x,poolSize,1),3,[],[],[],[],LB,UB,[],option);
save('curveResult.mat')

if par
    delete(gcp)
end
