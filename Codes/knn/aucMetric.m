function aucMetric()
testpath = 'C:\ANINDITA\Lorelei_2018\Lorelei_2018\Audios\LDC2017E92_LORELEI_Bengali_Speech_Database\BEN_EVAL_20170831\BEN_EVAL_20170831\';
labels = getLabel(testpath);
disp(labels);
labels = labels(1:end,3:5);
labels((labels == 2))=0;

labelsTime = labels(1:end,1);
labelsResolution = labels(1:end,2);
labelsUrgency = labels(1:end,3);
%disp(labels);
pred = load('C:\ANINDITA\Lorelei_2018\Lorelei_2018\Results\SF_OP\1hour_BEN_EVAL_BEN_EVAL\estimateSF.mat');
pred = getfield(pred,'normalizedEstimates');
%disp(size(pred));
%disp(pred);

predTime=pred(:,12:13);

predResolution=pred(:,14:15);

predUrgency=pred(:,16:17);
% 
% predTimemax = max(predTime,[],2);
% predResolutionmax = max(predResolution,[],2);
% predUrgencymax = max(predUrgency,[],2);
%disp(pred);
%chart = zeros(size(pred,1),2);
%chart(1:end,1) = pred;
%chart(1:end,2) = labels;
%disp(chart);
% 
% Atime = auc(predTimemax, labelsTime);
% Aresolution = auc(predResolutionmax, labelsResolution);
% Aurgency = auc(predUrgencymax, labelsUrgency);
Atime = auc(predTime(:,1), labelsTime);
Aresolution = auc(predResolution(:,1), labelsResolution);
Aurgency = auc(predUrgency(:,1), labelsUrgency);

disp(Atime);
disp(Aresolution);
disp(Aurgency);
end

function [typespresent]= getLabel(testpath)
    devsetDir = strrep(testpath,'\','/');
    folders=getfolders(devsetDir);
    evalDirCount = length(folders);
    %first80=floor((80/100)*evalDirCount);% first 80 percent of audio directories in the language
    %from81st=first80+1;% the 81st directory
    examined=[];
    typespresent=[];
    %for i=from81st:evalDirCount
    for i=11:evalDirCount
    %for i=1:evalDirCount
        %audio directory path
        audiodir = sprintf('%s%s/AUDIO/', testpath, folders(i).name);% 'path to traindir/001/AUDIO/'   
        %audio files in each directory
        audiopath=strcat(audiodir,'*.au');
        audiofiles=dir(audiopath);
        lastaudio=audiofiles(length(audiofiles)).name; %last audio in the directory
        lastaudiolast3=lastaudio(end-5:end-3); %number of the audio %001    
        %creating examined
        examined=vertcat(examined,[str2num(folders(i).name) str2num(lastaudiolast3)]);%duplet%the directory number, the number of the last audio in it

        % annotations directory
        annodir = sprintf('%s%s/ANNOTATION/', testpath, folders(i).name);% 'path to traindir/001/ANNOTATION/'

        % annotation files in each directory
        annopath=strcat(annodir,'*.txt');
        annofiles=dir(annopath);
        annoname=[];
        annonamelast3=[];
        for k=1:length(annofiles)        
                annoname=vertcat(annoname,strcat(annodir ,annofiles(k).name));
                annonamelast3=vertcat(annonamelast3,annofiles(k).name(end-6:end-4));                   
        end
        % parsing annotation files and creating typespresent    
        for l=1:size(annoname,1)
            %fprintf('%d_%d,%s\n',i,l,annoname(l,:));
            timeLabel=getAnnotationField(annoname(l,:),2);
            resolutionLabel=getAnnotationField(annoname(l,:),3);
            urgencyLabel=getAnnotationField(annoname(l,:),5);
            for p=1:size(timeLabel,1)
                %typespresent-the triplet: directory number, audio file/annotation file number,typenumber present as per the given annotations
                typespresent=vertcat(typespresent,[str2num(folders(i).name) str2num(annonamelast3(l,:)) timeLabel(p,1) resolutionLabel(p,1) urgencyLabel(p,1)]);           
            end
        end
    end  
    typespresent=unique(typespresent,'rows');
    %disp(typespresent);
end
%-----------------------------------------------------------------------------
function typeLabel=getAnnotationField(filename, numberOfLine)
    %fprintf('%s\n',filename);
    fileID = fopen(filename);
    alllines= textscan(fileID,'%s','delimiter','\n');%read all the lines in annotation file
    selectedLine=alllines{1}{numberOfLine};
    splitfirstline= strsplit(selectedLine,{':',','});%e.g. %'Type' 'Typename1' 'TypeName2'%separate the types delimited by commas
    splitfirstline=strtrim(splitfirstline);%without the whitespaces    
    
    %Select binary attribute depending in number of line
    if(numberOfLine == 2)
        typeList = cell(1,2);
        typeList{1} = 'Current';
        typeList{2} = 'Not Current';
    elseif(numberOfLine == 3)
        typeList = cell(1,2);
        typeList{1} = 'Sufficient';
        typeList{2} = 'Not Sufficient';
    elseif(numberOfLine == 5)
        typeList = cell(1,2);
        typeList{1} = 'Urgent';
        typeList{2} = 'Not Urgent';
    end  
    
    if(strcmp(splitfirstline{2},'Skipped')>0)
        typeLabel = -1;
        return;
    end
    if(strcmp(splitfirstline{2},typeList{1})>0)
        typeLabel = 1;
    else
        typeLabel = 2;
    end
    fclose(fileID);
end
%-----------------------------------------------------------------------------

function A = auc(pred, ground_truth)
% Computes the area under the ROC curve
% pred is in the [0,1] range, ground truth is either 0 or 1
% Programmed by Olac Fuentes
% Last modified December 2, 2016
pos = sum(ground_truth);
disp(pos);
neg = length(ground_truth) - pos;
disp(neg);
[sorted_pred, ind] = sort(pred);
sorted_gt = ground_truth(ind);
c = cumsum(sorted_gt);
c = c(end) - c;
A = sum(c(sorted_gt==0))/pos/neg;
end