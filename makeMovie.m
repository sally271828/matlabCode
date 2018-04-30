%% this script will take in time line and timecourse tif stack to make into a movie

%clear all
movingBarColor = 'r';
scalingFactor = 1.2; % decrease this number to get brighter images

% ask user for tifs, import them
[timeLineFile, timeLinePath] = uigetfile('../*.tif','Select timeline file');
[timeLapseFile, timeLapsePath] = uigetfile('../*.tif','Select image stack');
outputPath = uigetdir('','Select output file folder');
nImgs = getNum('Number of images?',100);
frameRate = getNum('Desired frame rate?',3);
lineWidth = getNum('Width of moving line?',2);
[timeLine, timeLineMap] = imread([timeLinePath timeLineFile]);
for i = 1:nImgs
    [tImg, ~] = imread([timeLapsePath timeLapseFile],i);
    timeLapse(:,:,i) = tImg;
end

% get positions for bar
f = msgbox({'Please draw initial position of moving line.';...
    'Click twice on the line when you are done.';...
    'Then do the same for the final position'});
pause(1)
imshow(timeLine)
h = imline;
barPosition1 = wait(h);
imshow(timeLine)
h = imline;
barPosition2 = wait(h);
close all
barHeight = [barPosition1(1,2) barPosition1(2,2)];
barTop = [barPosition1(1) barPosition2(1)];

% resize movie or tif to same x dim, make everything uint8
sizeImgs =  size(timeLapse);
sizeTimeLine = size(timeLine);
if isa(timeLine, 'uint16')
    timeLine = uint8(double(timeLine)./2^8);
end
mx = double(max(prctile(reshape(timeLapse, sizeImgs(1)*sizeImgs(2),sizeImgs(3)),98)))*scalingFactor; 
timeLapse = uint8(double(timeLapse)./mx.*2^8);% rescale timeLapse images to uint8, max at 98th percentile pixle value
if sizeImgs(2)>sizeTimeLine(2)
    xFinal = sizeImgs(2);
    timeLine = imresize(timeLine, sizeImgs(2)/sizeTimeLine(2));
    barHeight = barHeight.*sizeImgs(2)./sizeTimeLine(2);
    barTop = barTop.*sizeImgs(2)./sizeTimeLine(2);
else
    xFinal = sizeTimeLine(2);
    timeLapse = imresize(timeLapse, sizeTimeLine(2)/sizeImgs(2));
end

% write movie
cd(outputPath)
v = VideoWriter('movie.avi');
v.FrameRate = frameRate;
open(v);
barMove = (barTop(2)-barTop(1))/(nImgs-1);
barX = barTop(1);
for i = 1:nImgs
    for j = 1:3
        tmp(:,:,j) = timeLapse(:,:,i);
    end
    imshow([timeLine; tmp])
    hold on
    plot([barX barX], barHeight, 'Color', movingBarColor,'LineWidth',lineWidth)
    frame = getframe(gcf);
    writeVideo(v,frame);
    barX = barX + barMove;
end
close(v);

%%
function ang = getNum(s,ini)
prompt = s;
dlg_title = ' ';
num_lines = 1;
defaultans = {num2str(ini)};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
ang=str2num(answer{1});
end

function img = loadTif2(fname,bits, c)
    if ~exist('bits','var')
        bits = 8;
    end
    
    switch bits
        case 8
            bitstr = 'uint8';
        case 16
            bitstr = 'uint16';
        case 32
            bitstr = 'single';
        otherwise
            bitstr = 'uint8';
            disp('May not be loading tiff properly');
    end
    %loadTif Loads a multipage tiff and returns the image
    infoImage=imfinfo(fname);
    mImage=infoImage(1).Width;
    nImage=infoImage(1).Height;
    numberImages=length(infoImage);
    if c==1
        img=zeros(nImage,mImage,3,numberImages,bitstr);
    else
        img=zeros(nImage,mImage,numberImages,bitstr);
    end
    t = Tiff(fname,'r');
    
    for i=1:numberImages
         t.setDirectory(i);
         if c==1
            img(:,:,:,i) = t.read();
         else
             img(:,:,i) = t.read();
         end
    end
    t.close();
end