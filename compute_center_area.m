function [Area, openRadius] = compute_center_area(pID,R,step)

openRadius = R;

if nargin < 3
    %step = 50;
    step = csvread(['setup-opt-' num2str(pID) '/step.dat']);
end

direct = ['setup-opt-' num2str(pID) '/'];
fName = [direct 'solution.' num2str(step) '.plt'];

[Nodes, IEN] = Read_Tec_File(fName);

close all
fig = figure('position', [350 100 800 800],'color','w');
set(gcf, 'PaperPositionMode', 'auto');

Plot_Mesh(Nodes(:,1:3), IEN);
axis vis3d equal;
hold on

nel = size(IEN, 1);
nshl = size(IEN, 2);

pinx = zeros(nshl, 2);
for i = 1:nshl-1
      pinx(i,:) = [i, i + 1];
end
pinx(nshl, :) = [nshl, 1];

N = 400; % Number of discrete intervals
da = 2*pi/N;

Area = 0;
for ia = 1: N
      t = (ia-1)*da;
      
      cost = cos(t);
      sint = sin(t);
      
      rmin = R;%1;
      for i = 1: nel
            
            for j = 1: nshl
                  ix1 = pinx(j, 1);
                  ix2 = pinx(j, 2);
                  
                  p1 = Nodes(IEN(i, ix1), 1:2);
                  p2 = Nodes(IEN(i, ix2), 1:2);
                  
                  % if rmin^2 < p1*p1' || rmin^2 < p2*p2'
                  %       continue
                  % end
                  
                  val1 = cost*p1(2) - sint*p1(1);
                  val2 = cost*p2(2) - sint*p2(1);
                  
                  % if val1 * val2 > 0 => no intersection
                  if val1 * val2 > 0
                        continue
                  end
                  
                  
                  
                  detX = p1(1) - p2(1);
                  detY = p1(2) - p2(2);
                  
                  r = (detX*p2(2) - detY*p2(1))/(detX*sint - detY*cost);
                  
                  %plot(r*cost, r*sint, 'b.', 'markersize', 20);
                  %drawnow;
                  
                  if r > 0 && r < rmin
                        rmin = r;
                        if r < openRadius
                            openRadius = r;
                        end
                  end
                  
            end
      end
      
      Area = Area + rmin^2 * pi/N;

      Plot_Area(rmin, t-da/2, t+da/2);
      
end

Circle(openRadius);
%Area

function Plot_Area(r, t1, t2)
n = 5;
t = linspace(t1, t2, n)';

X = [r.*cos(t), r.*sin(t)];
X = [0,0;X;0,0];

plot(X(:,1), X(:,2),'r');

function Circle(r)
ang=0:0.01:2*pi; 
xp=r*cos(ang);
yp=r*sin(ang);
plot(0+xp,0+yp);

function p = Plot_Mesh(Nodes, IEN)

p = patch('Vertices',Nodes,'Faces',IEN,'FaceColor','none','EdgeColor',[1 1 1]/2);

function [Nodes, IEN] = Read_Tec_File(FileName)

fileID = fopen(FileName,'r');
%"X" "Y" "Z" "dx" "dy" "dz" "|d|" "Smax" "Smin"

lin = fgets(fileID); % first line
nV = sum(lin=='"')/2; % # of variables

lin = fgets(fileID); % second line
ixN = strfind(lin, 'N=');
N = sscanf(lin(ixN+2:end), '%g', 1);

ixE = strfind(lin, 'E=');
E = sscanf(lin(ixE+2:end), '%g', 1);

fgets(fileID); % skip 3rd line

Nodes = fscanf(fileID,'%f',[nV, N]);
Nodes = Nodes';

IEN = fscanf(fileID,'%d',[4, E]);
IEN = IEN';

fclose(fileID);