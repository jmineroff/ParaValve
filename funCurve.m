function y = funCurve(x,poolSize,forceRepeat,multi)

tic

%% Input tests

if nargin < 2 || poolSize < 1
    poolSize = 1;
end

if nargin < 3
    forceRepeat = 0;
end

if nargin < 4
    multi = 0;
end

t = getCurrentTask();

if isempty(t) % First evaluation is always performed in serial
    pID = 1;
else
    pID = t.ID;
end


%% Calculate parameters
                            %    Defaults
geoInput(1:12) = [1.115;... %  1 bottomRad          1.115
    0.072;...               %  2 openingRad         0.072
    1.018;...               %  3 topRad             1.018
    1.109;...               %  4 cornerHeight       1.109
   -0.269;...               %  5 freeHeightOffset  -0.269
    0;...                   %  6 commisureDeg       0
    7;...                   %  7 sinusDeg           7
    0.331;...               %  8 freeDeg            0.331
    6.735;...               %  9 fixedDeg           6.735
    0.471;...               % 10 fixedBlend         0.471
    0.615;...               % 11 centerBlend        0.615
    0.818];                 % 12 interiorBlend      0.818

thickness = 0.0386;

if ~isempty(x)
    geoInput([5,8,9,11]) = x(1:(end-1));
    thickness = x(end);
else
    x(1:4) = geoInput([5,8,9,11]);
    x(5) = thickness;
end


%% Check if repeat parameters

[repeat,output] = RepeatCheck(x);

if forceRepeat
   repeat = 0; 
end

%% Evaluate

if ~repeat % Continue with analysis
    
    csvwrite(['sync/ready.' num2str(pID) '.dat'],1); % pID: "Hey, I'm ready for geometry!"
     
    currentID = 0;
    testID = currentID; % To track if currentID is updated
    
    tWait = toc;
    
    while pID ~= currentID % Wait for turn
        
        if(toc - tWait > 10) % Increment if no change for 10 seconds
            
            currentID = IncrementID(poolSize);
            
            if isempty(currentID) % Appoint current pID if problem
               currentID = pID;
            elseif currentID == 0
               currentID = pID;
            end
                
            csvwrite('sync/current.dat', currentID); % Write new ID
            AnnounceID(currentID)
            
            tWait = toc;
        end
        
        pause(0.1)
        
        try % Attempt currentID update
            currentID = csvread('sync/current.dat');
        catch
        end
        
        if testID ~= currentID % Restart timer if currentID is changed
            testID = currentID;
            tWait = toc;
        end
    end
    
    GHflag = GenerateGeometry(geoInput,thickness,pID);
    
    delete(['sync/ready.' num2str(pID) '.dat'])
    
    currentID = IncrementID(poolSize);
    
    if isempty(currentID) || currentID == 0
        currentID = mod(pID+1,poolSize); 
    end
    
    csvwrite('sync/current.dat', currentID);
    AnnounceID(currentID)
    
    if GHflag == 1
        RunAnalysis(pID)
        
        if ~exist(['setup-opt-' num2str(pID) '/step.dat'], 'file')
            GHflag = 2;
        end
    end
    
    output(1:13) = [-Inf,Inf,Inf,Inf,Inf,0,0,Inf,Inf,Inf,Inf,Inf,Inf];
    
    if GHflag == 1
        output(1:13) = ReadResults(output(1:13),pID,geoInput);
    end
    
    output(6) = GHflag;
end

output(5) = toc;
output(7) = repeat;

y = CalculateObjectives(output,thickness,multi);

%% Log results

LogResults(geoInput,thickness,output,pID);

end


%% Subfunctions

function [repeat,output] = RepeatCheck(x)

repeat = 0;
output = [];

results = [];

while isempty(results) % Try until the file can be read
    try
        results = csvread('results/results.txt'); % Read results file
    catch
        pause(0.01); % Delay before retry
    end
end

resNorm = 0.0001;

for i = 1:size(results,1) % Parse results
    if sqrt(sum( ( results(i,[5,8,9,11,13]) - x ).^2 )) <= resNorm
        
        output = results(i,14:26);
        
        repeat = 1;
        
        break
    end
end

end


function GHflag = GenerateGeometry(geoInput,thickness,pID)

ClearOldResults(); % Clear results files

WriteInputs(geoInput,thickness);

pause(0.1); % Let data transfer to Windows

SetGeoFlag();

pause(0.5);

GHflag = csvread('geometry/GHflag.txt');

if GHflag == 1
    MoveGeoFiles(pID);
end

end


function nextID = IncrementID(poolSize)

nextID = [];

for i = 1:poolSize % Increment processor
    if exist(['sync/ready.' num2str(i) '.dat'],'file')
        nextID = i;
        break
    end
end

end


function AnnounceID(currentID)
    disp(currentID)
end


function RunAnalysis(pID)

while exist(['setup-opt-' num2str(pID) '/bashComplete.txt'],'file')
    try
        delete(['setup-opt-' num2str(pID) '/bashComplete.txt'])
    catch
    end
end

system(['./setup-opt-' num2str(pID) '/prepAnalysis.sh &']);

bashTry = 1;
bashComplete = 0;

while bashComplete ~= 1 && bashTry <= 2 % Max number of analysis attempts
    system(['./setup-opt-' num2str(pID) '/runAnalysis.sh &']);
    bashStart = toc;
    
    while bashComplete ~= 1 && toc - bashStart < 60*20  % Max allowable time for analysis
        pause(0.1)
        
        if exist(['setup-opt-' num2str(pID) '/bashComplete.txt'],'file')
            bashComplete = 1;
            break
        end
    end
    
    if bashComplete ~= 1 % Get bash PID and kill process
        bashPID = csvread(['setup-opt-' num2str(pID) '/bashPID.txt']);
        
        if ~isempty(bashPID)
            system(['kill -9 ' num2str(bashPID) ' &']);
        end
        
        bashTry = bashTry + 1;
    end
end

while exist(['setup-opt-' num2str(pID) '/bashComplete.txt'],'file')
    try
        delete(['setup-opt-' num2str(pID) '/bashComplete.txt'])
    catch
    end
end

end


function output = ReadResults(output,pID,geoInput)

try
    results = csvread(['setup-opt-' num2str(pID) '/results.dat']);
catch
    results = [];
end

if length(results) >= 8
    output(8) = results(end-7); % Total Area
    output(1) = results(end-6); % Contact Area
    output(2) = results(end-5); % Strain
    output(9) = results(end-4); % Strain Area
    
    output(10) = results(end-3); % Bending
    output(11) = results(end-2); % Bending Area
    output(12) = results(end-1); % Tensile
    output(13) = results(end);   % Tensile Area
end

try
    [output(3), output(4)] = compute_center_area(pID, max(geoInput([3,3]))); % Open Area, Max Radius
catch
end

end


function y = CalculateObjectives(output,thickness,multi)

y = output(11)/output(8); % Bending Area Ratio
%y = output(9)/output(8); % Strain Area Ratio

%y = output(2); % Strain
%y = -output(1); % Coaptation Area
%y = output(3); % Open Area

%y = [output(2),-output(1)]; % Multi-objective

% CONSTRAINTS

flexFactor = 1.01; % How much more can the best solution have?

if output(2) > 0.613*flexFactor % Peak Green Strain
    y = Inf;
end
if output(12) > 0.168*flexFactor % Peak Tensile Strain
    y = Inf;
end
if output(11) > 10.11*flexFactor % Peak Bending (delta_K)
    y = Inf;
end
if output(3) > 0.05*flexFactor % Regurgitation EOA
    y = Inf;
end
if (output(1)/output(8) < 0.1/flexFactor) || (output(1)/output(8) > 0.25*flexFactor) % Coaptation Ratio
    y = Inf;
end

if multi
   if y ~= Inf
        y(2) = thickness;
   else
        y(2) = Inf;
   end
end

end


function LogResults(geoInput,thickness,output,pID)

while exist('results/writing.dat','file')
    pause(0.01)
end

csvwrite('results/writing.dat',1);

resultsLOG = csvread('results/results.txt');

if resultsLOG(1,1) == 0
    resultsLOG(1,1:26) = [geoInput,thickness,output];
else
    resultsLOG(end+1,1:26) = [geoInput,thickness,output];
end

csvwrite('results/results.txt',resultsLOG);

delete('results/writing.dat');

if exist(['setup-opt-' num2str(pID) '/output.txt'],'file')
    % Move output log
    try
        outString = ['results/output-' num2str(size(resultsLOG,1)) '.txt'];
        movefile(['setup-opt-' num2str(pID) '/output.txt'], outString)
    catch
    end
end

end

%% Geometry Subfunctions

function ClearOldResults()

if exist('geometry/smesh.1.dat','file')
    try
        delete('geometry/smesh.1.dat')
    catch
    end
end

if exist('geometry/smesh.2.dat','file')
    try
        delete('geometry/smesh.2.dat')
    catch
    end
end

if exist('geometry/smesh.3.dat','file')
    try
        delete('geometry/smesh.3.dat')
    catch
    end
end

if exist('geometry/thickness.dat','file')
    try
        delete('geometry/thickness.dat')
    catch
    end
end

if exist('geometry/GHflag.txt','file')
    try
        delete('geometry/GHflag.txt')
    catch
    end
end

ReadyFlag = 0;

while ReadyFlag == 0 % Wait for geometry to be deleted on Windows
    if exist('geometry/input.geo.dat','file')
    try
        delete('geometry/input.geo.dat')
    catch
    end
    end
    
    pause(0.1);
    
    try
        ReadyFlag = csvread('geometry/ReadyFlag.txt');
    catch
        ReadyFlag = 0;
    end
end

end


function WriteInputs(geoInput,thickness)

csvwrite('geometry/thickness.dat',thickness);

ReadyFlag = 1;

while ReadyFlag == 1 % Wait for geometry to be deleted on Windows
    try
        csvwrite('geometry/input.geo.dat',geoInput');
    catch
    end
    
    pause(0.1);
    
    try
        ReadyFlag = csvread('geometry/ReadyFlag.txt');
    catch
        ReadyFlag = 1;
    end
end

end


function SetGeoFlag()

csvwrite('geometry/GeoGenFlag.txt',1);

GeoGenFlag = 1;

while GeoGenFlag == 1
    
    pause(0.1);
    
    try
        GeoGenFlag = csvread('geometry/GeoGenFlag.txt');
    catch
        GeoGenFlag = 1;
    end
end

end


function MoveGeoFiles(pID)

smeshFlag = [0,0,0];

while min(smeshFlag) == 0
    if exist('geometry/smesh.1.dat','file') % Wait for results files to be written
        smeshFlag(1) = 1;
    end
    if exist('geometry/smesh.2.dat','file')
        smeshFlag(2) = 1;
    end
    if exist('geometry/smesh.3.dat','file')
        smeshFlag(3) = 1;
    end
end

pause(0.1) % Extra time for files to be released

system(['./setup-opt-' num2str(pID) '/prepAnalysis.sh']); % Copy files, etc.

end
