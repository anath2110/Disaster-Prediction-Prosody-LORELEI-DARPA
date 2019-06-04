%function interfaceToSFestimatesMto1(featurefile,pathToTrainSet,pathToTestSet,...
%   newOroldAnno,pathToOutputDir)
%------------------------------------------------------------------
%June'2018
%Anindita Nath
%University of Texas at El Paso
%------------------------------------------------------------------
% This is used to create "universal model" trained on multiple languages 
%This is the top-level function which calls the functions computing the
%estimates for sitution types as well as the binary attributes,
%the function prinitng the outputs in the Lorelei approved json schema,
% and the function printing the confidence scores of all attributes in json
% form.

%Input: 
%   i) featurefile :    file listing prosodic features with .fss extension
%      ('mono.fss')
%   ii)pathToTrainSet: absolute path upto the parent of the duplicate hierarchical
%   langugae directory.
%   e.g. if the language directory is CHN_DEV_123456/CHN_DEV_123456, path
%   will include upto the parent of this.
%   iii)pathToTestSet: ditto but for the test set.
%   iv) newOroldAnno: A string either 'new' or 'old' representing the new or
%   old annotation formats, respectively
%   v) pathToOutputDir: This is the absolute path to the directory where 
%   you want the output directory to be created, could be anywhere in your
%   PC
%   vi) delSkip: true or false; 

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
function interfaceToSFestimatesMto1(featurefile,pathToTrainSet,pathToTestSet,...
newOroldAnno,pathToOutputDir,delSkip)

% lines# 24-28, currently not needed
% currentPath=mfilename('fullpath'); %fullpath to the current script
% currentScriptName=mfilename;%scriptname
% pathToParent=strrep(filepath,filename,''); % replacing the scriptname with balnk,..
%                                           % retreiving path to the parent
%                                           % directory of this current script


%folders=getfolders(pathCommonToTrainTestDir);% for single train-test
trainFolders=getfolders(pathToTrainSet);
testFolders=getfolders(pathToTestSet); 


trainsetpath=[];
testsetpath=[];
trainsetname=[];
testsetname=[];

for i=1:length(trainFolders)    
   
        dirTrainName=trainFolders(i).name;
        %langTrainName=strcat(dirTrainName(1:3));
        %disp(langTrainName);
        %langTrainName=strcat(dirTrainName(1:3),'_DEV');% if the languagename has DEV as a suffix
        langTrainName=strcat(dirTrainName(1:3),'_EVAL');% if the languagename has DEV as a suffix
        %langTrainName=strcat(dirTrainName);
        %disp(langTrainName);
        pathToTrainNumberedDir=strcat(pathToTrainSet,dirTrainName,'\',dirTrainName,'\');
                                                                         
       
        if length(trainsetpath)==0 
            trainsetpath=pathToTrainNumberedDir;          
            trainsetname=langTrainName;
          
        else
            trainsetpath=vertcat(trainsetpath,pathToTrainNumberedDir);           
            trainsetname=vertcat(trainsetname,langTrainName);
        end
end
for j=1:length(testFolders) 
    
        dirTestName=testFolders(j).name;
        pathToTestNumberedDir=strcat(pathToTestSet,dirTestName,'\',dirTestName,'\');
        %langTestName=strcat(dirTestName(1:3));
        %disp(langTestName);
        %langTestName=strcat(dirTestName(1:3),'_EVAL');%if the languagename has 'EVAL' as a suffix
        langTestName=strcat(dirTestName);%if the languagename has 'EVAL' as a suffix
        %disp(langTestName);
        if  length(testsetpath)==0           
            testsetpath=pathToTestNumberedDir;         
            testsetname=langTestName; 
        else
          
            testsetpath=vertcat(testsetpath,pathToTestNumberedDir);           
            testsetname=vertcat(testsetname,langTestName);
        end   
end

%disp(trainsetpath);
% disp(trainsetname);
%disp(testsetpath);
%disp(testsetname);

%creating an output directory in the provided path 'pathToOutputDir' where
%all of this script's output will be saved
[Pathstr,FolderName] = fileparts(pathToOutputDir);
%disp('Pathstr');
%disp(Pathstr);
%outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\',trainsetname,'_',testsetname,'\');%single training language
%outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\','Set0Set1_allSessions',testsetname,'\');%multiple training language
outputDir=strcat(Pathstr,'\',FolderName,'reRuns','\','UniversalTrain_',testsetname,'\');%multiple training language
%disp('outputDir');
%disp(outputDir);
%disp(outputDir);
[status,msg]= mkdir(outputDir);

%single training language 
%jsonFileName=strcat('system_output',trainsetname,'_',testsetname);
%jsonFileNameScores=strcat('likelihoodScores_',trainsetname,'_',testsetname);
%disp(jsonFileName);
%multiple training langugae
jsonFileName=strcat('system_output_universalTrain_test','_',testsetname);
jsonFileNameScores=strcat('likelihoodScores_','universalTrain_test','_',testsetname);
refmatfile=strcat(outputDir,'refdataSF');
%disp('refmatfile');
%disp(refmatfile);
% call function to prepare the refData 

   
[refmatfile,confusionMatrix]= createRefModel(refmatfile,outputDir,trainsetpath,trainsetname,featurefile,newOroldAnno,delSkip);  

%call to the function computing estimates of all attributes
estimateSFMto1Gravity(outputDir,featurefile,refmatfile,testsetpath,testsetname,confusionMatrix)
outputAsJsonV2commonSF(outputDir,jsonFileName); % json outputs 
outputAsJsonV2_1Scores(outputDir,jsonFileNameScores); % json outputs with confidence scores
end
%------------------------------------------------------------------
