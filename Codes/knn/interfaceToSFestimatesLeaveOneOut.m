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
function interfaceToSFestimatesLeaveOneOut(featurefile,pathToTrainSet,pathToTestSet,...
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
        langTestName=strcat(dirTestName(1:3),'_EVAL');%if the languagename has 'EVAL' as a suffix
        %langTestName=strcat(dirTestName);%if the languagename has 'EVAL' as a suffix
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
%disp(trainsetname);
%disp(testsetpath);
%disp(testsetname);

%creating an output directory in the provided path 'pathToOutputDir' where
%all of this script's output will be saved
[Pathstr,FolderName] = fileparts(pathToOutputDir);
%disp('Pathstr');
%disp(Pathstr);
%outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\',trainsetname,'_',testsetname,'\');%single training language
%outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\','Set0Set1_allSessions',testsetname,'\');%multiple training language
outputDir=strcat(Pathstr,'\',FolderName,'reRuns','\','Leave1out_',testsetname,'\');%multiple training language
%disp('outputDir');
%disp(outputDir);
%disp(outputDir);
[status,msg]= mkdir(outputDir);

%single training language 
%jsonFileName=strcat('system_output',trainsetname,'_',testsetname);
%jsonFileNameScores=strcat('likelihoodScores_',trainsetname,'_',testsetname);
%disp(jsonFileName);
%multiple training langugae
jsonFileName=strcat('system_output_Leave1out__traintest','_',testsetname);
jsonFileNameScores=strcat('likelihoodScores_','Leave1out__traintest','_',testsetname);
refmatfile=strcat(outputDir,'refdataSF');
refmatfileAppend=strcat(outputDir,'refdataSF');
estimatesmatAppend=strcat(outputDir,'estimateSF');
neighbormatAppend=strcat(outputDir,'neighborpertestaudioSF');
testmatfileAppend=strcat(outputDir,'testdataSF');

%disp('refmatfile');
%disp(refmatfile);
% call function to prepare the refData 

n=length(getfolders(trainsetpath));
% disp(n);
indices = crossvalind('Kfold',n,n);

refFeaturesAppend=[];
refnamesAppend=[];
reftimestampsAppend=[];
refTypesAppend=[];
refperFileTypesAppend=[];
reftypesPresentalltrainAppend=[];
refexaminedalltrainAppend=[];

esiAppend=[];
esBasenamesAppend=[];
esNormesAppend=[];

neighborAppend=[];
testAppend=[];

for repeatFolds = 1:n
    test = (indices == repeatFolds); 
    train = ~test;
    
% noofdir=find(train==1);
% disp('noofdir');
% disp(noofdir);
% 
% evalDirCount = length(find(test==1));
% evaldataspec = [find(test==1)  zeros(evalDirCount,1)];
% disp('evalDirCount');
% disp(evalDirCount);
% disp('evaldataspec');
% disp(evaldataspec);
    
[refmatfile,confusionMatrix]= createRefModelLeaveOneOut(refmatfile,outputDir,trainsetpath,trainsetname,featurefile,newOroldAnno,delSkip,train);  

refFeatures=load(refmatfile,'refFeatures');
refnames=load(refmatfile,'refnames');
reftimestamps=load(refmatfile,'reftimestamps');
refTypes=load(refmatfile,'refTypes'); 
refperFileTypes=load(refmatfile,'perFileTypes'); 
reftypesPresentalltrain=load(refmatfile,'typesPresentalltrain');
refexaminedalltrain=load(refmatfile,'examinedalltrain');

refFeaturesAppend=vertcat(refFeaturesAppend,refFeatures);
refnamesAppend=vertcat(refnamesAppend,refnames);
reftimestampsAppend=vertcat(reftimestampsAppend,reftimestamps);
refTypesAppend=vertcat(refTypesAppend,refTypes);
refperFileTypesAppend=vertcat(refperFileTypesAppend,refperFileTypes);
reftypesPresentalltrainAppend=vertcat(reftypesPresentalltrainAppend,reftypesPresentalltrain);
refexaminedalltrainAppend=vertcat(refexaminedalltrainAppend,refexaminedalltrain);

% % %call to the function computing estimates of all attributes
[estimatesmat,neighbormat,testmatfile]=estimateSFMto1GravityLeaveOneOut(outputDir,featurefile,refmatfile,testsetpath,testsetname,confusionMatrix,test);
esi=load(estimatesmat,'i');
esBasenames=load(estimatesmat,'basenames');
esNormes=load(estimatesmat,'normalizedEstimates');

esiAppend=vertcat(esiAppend,esi);
esBasenamesAppend=vertcat(esBasenamesAppend,esBasenames);
esNormesAppend=vertcat(esNormesAppend,esNormes);


neighbor=load(neighbormat,'neighbor');
test=load(testmatfile,'test');


neighborAppend=vertcat(neighborAppend,neighbor);
testAppend=vertcat(testAppend,test);

end
save(refmatfileAppend,'refnamesAppend','refperFileTypesAppend','reftypesPresentalltrainAppend',....
    'refexaminedalltrainAppend','refTypesAppend','reftimestampsAppend','refFeaturesAppend','-v7.3');

save(estimatesmatAppend,'esiAppend','esBasenamesAppend','esNormesAppend','-v7.3');
save(neighbormatAppend,'neighborAppend','-v7.3');
save(testmatfileAppend,'testAppend','-v7.3');

outputAsJsonLeave1Out(outputDir,jsonFileName); % json outputs 
outputAsJsonLeave1OutScores(outputDir,jsonFileNameScores); % json outputs with confidence scores
end
%------------------------------------------------------------------
