%{
    1.2 Modeling a fishing scenario 

    DEPENDENCIES:
    - matlab2tikz package (see "http://www.mathworks.com/matlabcentral/fileexchange/22022-matlab2tikz-matlab2tikz")
      in "MATLAB\R2021a\toolbox\matlab\plottools" folder
    - stoplight package (see "https://www.mathworks.com/matlabcentral/fileexchange/63277-stoplight-colormap")
      in "MATLAB\R2021a\toolbox\matlab" folder
%}

close all;
clear all;
clc;

%% Add path to "matlab2tikz" package
paths = split(path,';');
expr = 'plottools$';
for i=1:numel(paths)
    if ~isempty(regexp(paths{i},expr,'once'))
        matlab2tikz_path = paths{i};
        break
    end
end

if exist('matlab2tikz_path','var')
    matlab2tikz_path = strcat(matlab2tikz_path,'\matlab2tikz\src');
    addpath(matlab2tikz_path,'-end')
end

%% Add path to "stoplight" colormap package
paths = split(path,';');
expr = 'scribe$';
for i=1:numel(paths)
    if ~isempty(regexp(paths{i},expr,'once'))
        stoplight_path = paths{i};
        break
    end
end

if exist('stoplight_path','var')
    stoplight_path = strcat(stoplight_path,'\stoplight');
    addpath(stoplight_path,'-end')
end

%% a) Regeneration of Fish
x = linspace(0,100,100);
y = x.^2.*(100-x);

fr_max = 550/max(y);
y = 550/max(y)*y;

%{
figure(1)
plot(x,y)
xlabel('Percent of Maximum Fish Population')
ylabel('New Fish per Year')
title('Regeneration of Fish')
pbaspect([1.5 1 1])
grid on

if exist('matlab2tikz_path','var')
    matlab2tikz('figures\regeneration_of_fish.tex','showInfo', false);
end
%}
    
fr = @(x) fr_max*x.^2.*(100-x);

%% b) Ship Effectiveness
x = linspace(0,6,1000);
y = x./(1+x);

x = 100/6*x;
fe_max = 25/max(y);
y = 25/max(y)*y;

%{
figure(2)
plot(x,y)
ylim([0 30])
xlabel('Fish Density')
ylabel('Ship Effectiveness')
title('Ship Effectiveness')
pbaspect([2 1 1])
grid on

if exist('matlab2tikz_path','var')
    matlab2tikz('figures\ship_effectiveness.tex','showInfo', false);
end
%}
    
fe = @(x) fe_max * 6*x./(100+6*x);

%% c) Dynamics of Fish Population
x_max = 2000;
fx = @(x,y) (fr(100*x./x_max) - y.*fe(100*x./x_max));

%% d) Equilibrium points and region of attraction
%{
syms x

N = 40;
y_max = 40;
equi = zeros(4,N+1);
y = linspace(0,y_max,N+1);

ubs = zeros(1,N+1);
lbs = zeros(1,N+1);
for i=1:N+1
    solv = double(solve(fx(x,y(i))));
    if numel(solv) < 4
        solv = [zeros(4-numel(solv),1); solv];
    end
    equi(:,i) = solv;
    
    df = diff(sym(@(x)fx(x,y(i))));
    bounds = double(solve(df));
    bounds = bounds(abs(imag(bounds)) < 1e-6);
    ubs(i) = max(bounds);
    lbs(i) = min(bounds);
end
eq = equi;
equi = real(equi);
equi(2,:) = [equi(2,1:18) 830 equi(3,20:end)];
equi(3,:) = [];

figure, hold on
plot(0:N,equi(1,:),'Color',[1, 0, 0],'LineWidth',2)
plot(0:24,equi(2,1:25),'Color',[0.9290, 0.6940, 0.1250],'LineWidth',2)
plot(0:24,equi(3,1:25),'Color',[0, 0.5, 0],'LineWidth',2)
ylim([0 x_max])
xlim([0 y_max])
grid on

x = 0:N;
xx = [x fliplr(x)];
yy1 = [equi(1,:) fliplr(equi(2,:))];
fill(xx,yy1,'r','FaceAlpha',0.1,'EdgeColor','none')

x = 0:24;
xx = [x fliplr(x)];
yy2 = [equi(2,1:25) fliplr(equi(3,1:25))];
yy3 = [equi(3,1:25) fliplr(2000*ones(1,25))];
fill(xx,yy2,'g','FaceAlpha',0.1,'EdgeColor','none')
fill(xx,yy3,'g','FaceAlpha',0.1,'EdgeColor','none')

x = 24:N;
xx = [x fliplr(x)];
yy4 = [equi(3,25:end) 2000*ones(size(equi(3,25:end)))];
fill(xx,yy4,'r','FaceAlpha',0.1,'EdgeColor','none')

xlabel('Fishing Boats')
ylabel('Fish')
legend('stable','unstable','stable','extinction zone','surviving zone')

if exist('matlab2tikz_path','var')
    matlab2tikz('figures\region_of_attraction.tex','showInfo', false);
end
%}

%{
figure
fc=fcontour(fx,[0,2000,0,40],...
    'Fill','on','MeshDensity',100,'LevelList',linspace(-800,800,10000));
view(90,-90)
xlabel('Fishing Boats') 
ylabel('Fish')

if exist('stoplight_path','var')
    colorbar
    colormap stoplight
    caxis([-800 800])
end

fname = 'figures/';                             % figure directory path
filename = 'fish_dynamics_colormap';            % file name
saveas(gca, fullfile(fname, filename), 'epsc')  % 'epsc' for colored plots
%}

%% f) Dynamics number of fishing  boats
ky = [0.1 0.5 1];
c = [20 22 24];
[ky,c] = meshgrid(ky,c);

%{
fig = figure;
for i=1:numel(ky)
    
    fy = @(x,y) ky(i)*y.*(fe(100*x./x_max)-c(i));
    [X1,X2] = meshgrid(linspace(0,2000,100),linspace(0,80,100));
    F1 = fx(X1,X2);
    F2 = fy(X1,X2);
    
    subplot(3,3,i)
    streamslice(X1,X2,F1,F2,0.2,'noarrows');
    
    if i==8
        xlabel('Fish')
    end
    if i==4
        ylabel('Fishing Boats')
    end
    
    title(sprintf('ky=%.1f, c=%.0f', [ky(i),c(i)]))
    
    xticks([0 1000 2000])
    xticklabels({'0','1000','2000'})
    
    axis([0 2000 0 80])
    grid on
end
fig.Position(3:4) = 0.975*fig.Position(3:4);

fname = 'figures/';                             % figure directory path
filename = 'dynamic_ships';                     % file name
saveas(gca, fullfile(fname, filename), 'epsc')  % 'epsc' for colored plots
%}

%% h) Subsidies for struggling fishing boats
%{
fig = figure;
for i=1:numel(ky)
    
    fy = @(x,y) ky(i)*y.*max(fe(100*x./x_max)-c(i),-2);
    [X1,X2] = meshgrid(linspace(0,2000,100),linspace(0,80,100));
    F1 = fx(X1,X2);
    F2 = fy(X1,X2);
    
    subplot(3,3,i)
    streamslice(X1,X2,F1,F2,0.2,'noarrows');
    
    if i==8
        xlabel('Fish')
    end
    if i==4
        ylabel('Fishing Boats')
    end
    
    title(sprintf('ky=%.1f, c=%.0f', [ky(i),c(i)]))
    
    xticks([0 1000 2000])
    xticklabels({'0','1000','2000'})
    
    axis([0 2000 0 80])
    grid on
end
fig.Position(3:4) = 0.9*fig.Position(3:4);

fname = 'figures/';                             % figure directory path
filename = 'subsidies';                         % file name
saveas(gca, fullfile(fname, filename), 'epsc')  % 'epsc' for colored plots
%}