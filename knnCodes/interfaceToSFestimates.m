%function interfaceToSFestimates(featurefile,pathCommonToTrainTestDir,....
%pathToTrainSet,pathToTestSet,nameTrainLang,nameTestLang,newOroldAnno,pathToOutputDir)
%------------------------------------------------------------------
%May'2017
%modified : May'2018
%Anindita Nath
%University of Texas at El Paso
%------------------------------------------------------------------
%This is the top-level function which calls the functions computing the
%estimates for sitution types as well as the binary attributes,
%the function prinitng the outputs in the Lorelei approved json schema,
% and the function printing the confidence scores of all attributes in json
% form.

%Input: 
%   i) featurefile :    file listing prosodic features with .fss extension
%      ('mono.fss')
%   ii) pathCommonToTrainTestDir :  absolute path upto the '\' common to both the
%       train and test directories
%   iii)pathToTrainSet: path starting from right after the 
%   'pathCommonToTrainTestDir' upto the parent to the numbered
%   directories,'001', in the train set.
%   iv)pathToTestSet: path starting from right after the 
%   'pathCommonToTrainTestDir' upto the parent of the numbered
%   directories,'001' in the test set.
%   nameTrainLang: This is the abbreviated name of the training language, 
%   it is the audio name or the annotation file name but ending right
%   before the last undersscore
%   e.g. if audio name is CHN_EVAL_2016589,'nameTrainLang' would be 'CHN_EVAL' 
%   nameTestLang: This is the abbreviated name of the test language, 
%   it is the audio name or annotation file name but ending right
%   before the last undersscore 
%   e.g. if audio name is 'ARA_2016589,'nameTestLang' would be 'ARA' 
%   newOroldAnno: A string either 'new' or 'old' representing the new or
%   old annotation formats, respectively
%   pathToOutputDir: This is the absolute path to the directory where 
%   you want the output directory to be created, could be anywhere in your
%   PC

%------------------------------------------------------------------
% to run: 
%  addpath jsonlab-1.5
%  addpath midlevelmaster/src/
%  addpath voicebox
%  addpath estimateBinaryAttributes.m
%  addpath estimateTypes.m
%  addpathknnForTypes.m
%  addpath normalizeTo01.m
%  addpath outputAsJson.m
 
%------------------------------------------------------------------
function interfaceToSFestimates(featurefile,pathCommonToTrainTestDir,....
pathToTrainSet,pathToTestSet,nameTrainLang,nameTestLang,newOroldAnno,pathToOutputDir)
% lines# 24-28, currently not needed
% currentPath=mfilename('fullpath'); %fullpath to the current script
% currentScriptName=mfilename;%scriptname
% pathToParent=strrep(filepath,filename,''); % replacing the scriptname with balnk,..
%                                           % retreiving path to the parent
%                                           % directory of this current script



folders=getfolders(pathCommonToTrainTestDir);
countOfLangSets=length(folders);% count the number of language directories
trainsetpath=[];
testsetpath=[];
trainsetname=[];
testsetname=[];

for i=1:countOfLangSets %loop runs only once if there is a single train and testset
    
    %     uncomment the lines# 41-58 for many-to-one train-test experiments
    %     dirName=folders(i).name;
    %     langName=dirName(1:3);% first three letters of the directory name'ARA_20161130' is the abbreviated language name %e.g. ARA
    %     pathToNumberedDir=strcat(pathCommonToTrainTestDir,dirName,'\',dirName,'\');% path to the '001', etc. numbered directory..
    %                                                                      % contains hierarchy of 2 folders
    %                                                                      % with the same name as the 'dirName'
    %                                                                      %eg.ARA_20161130\ARA_20161130\001 
    %    
    %     if length(trainsetpath)==0 && length(testsetpath)==0
    %         trainsetpath=pathToNumberedDir;% column vector with the path to all the language directories
    %         testsetpath=pathToNumberedDir; % duplicate vector as above
    %         trainsetname=langName;% column vector with the name of all the language directories
    %         testsetname=langName; % duplicate vector as above
    %     else
    %         trainsetpath=vertcat(trainsetpath,pathToNumberedDir);
    %         testsetpath=vertcat(testsetpath,pathToNumberedDir);
    %         trainsetname=vertcat(trainsetname,langName);
    %         testsetname=vertcat(testsetname,langName);
    %     end  
    
    % uncomment if it is only one train set and one test set
    trainsetpath=strcat(pathCommonToTrainTestDir,pathToTrainSet);
    %disp(trainsetpath);
    testsetpath=strcat(pathCommonToTrainTestDir,pathToTestSet);
    %disp(testsetpath);
    trainsetname=nameTrainLang;
    testsetname=nameTestLang;            

end
jsonFileName=strcat(trainsetname,'_',testsetname);
jsonFileNameScores=strcat('Scores_',trainsetname,'_',testsetname);
for i=1:size(trainsetpath,1) % repeat for training on each of the language directories   
    for j=1:size(testsetpath,1) % repeat test for each of the language directories, trained on the above 
    
        %common function to estimate all of SF's attributes        
%         pathToDirWithEstimates=estimateSF(pathToOutputDir,trainsetpath,testsetpath(j,:),...
%         trainsetname,testsetname(j,:),featurefile,newOroldAnno);        
        pathToDirWithEstimates=estimateSFGravity(pathToOutputDir,trainsetpath,testsetpath(j,:),...
        trainsetname,testsetname(j,:),featurefile,newOroldAnno);        

        outputAsJsonV2commonSF(pathToDirWithEstimates,jsonFileName); % json outputs
        outputAsJsonV2_1Scores(pathToDirWithEstimates,jsonFileNameScores); % json outputs with confidence scores
    end
end    
end
%------------------------------------------------------------------
