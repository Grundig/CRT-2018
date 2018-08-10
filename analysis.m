%% Initialisation
tic;
filepath = 'C:\Users\laptop\Desktop\2018\2018-08-07.hdf5';
run = '120';
data = h5read(filepath, '/RUN 120/coincidences');
coinc = 1000;%length(data.Pixel);
CoincWindow = 5;                                                           % coincidence window in ns
cw = ceil(CoincWindow / 0.256);                                             % number of samples in coincidence window
RunData = struct();
LowToHiRes = uint64(zeros(1,coinc));
texp;
load('texp.mat');                                                           % Loads a matrix containing all possible travel times
%parpool;

% In this loop the high and low resolution timestamps are combined and the
% .time value is the high resolution (0.256 ns intervals) since the start of the run.

parfor n = 1:coinc
    LowToHiRes(n) = uint64(data.LowResHitTime(n)-data.LowResHitTime(1))*3.90625e+10;
    RunData(n).time = uint64(data.HiResHitTime(n)) + LowToHiRes(n);
    RunData(n).pixel = data.Pixel(n);
end



%UpIndex = find([RunData.Pixel] > 15);
%DownIndex = find([RunData.Pixel] < 16);

% Splitting the hit list to top and bottom detector hits.
UpData = RunData([RunData.pixel] > 15);
DownData = RunData([RunData.pixel] < 16);


%%
timePairs = int64.empty(0,2);
pixPairs = single.empty(0,2);
P=0;

Closest = nearestpoint([UpData.time],[DownData.time]);
L = length([DownData.pixel]);
parfor u = 1:length([UpData.pixel])

%     timePairs(1:end,1) = UpData(Closest).time;
%     timePairs(1:end,2) = DownData(Closest).time;        
%     pixPairs(1:end,1) = UpData(Closest).pixel;
%     pixPairs(1:end,2) = DownData(Closest).pixel;
%     
    a = max(Closest(u)-10, 1);
    b = min(Closest(u)+10, L);
    dt = [DownData(a:b).time];
    ut = UpData(u).time;
    
    Pindex = find((dt>ut-cw) .* (dt<ut+cw)) + a-1;
    
    f = length(Pindex);
    P = size(pixPairs,1);
    y = P+1:P+f;
    if f > 0
        timePairs(y,1) = UpData(u).time;
        timePairs(y,2) = [DownData(Pindex).time]';
        pixPairs(y,1) = UpData(u).pixel;
        pixPairs(y,2) = [DownData(Pindex).pixel]';
       
    end
end
RunTime = toc

%% Confidence Calculation
td = zeros(length(pixPairs),1);
treal = double.empty(0);
parfor i = [1:length(pixPairs)]
    pix1 = pixPairs(i,1)-15;
    pix2 = pixPairs(i,2)+1;
    texpect = Te(pix1,pix2);
    treal = abs(double(timePairs(i,1)-timePairs(i,2))*0.256);
    td(i) = treal-texpect;
end

histogram(td,50)
sigma = std(td)
