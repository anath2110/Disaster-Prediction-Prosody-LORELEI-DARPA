% estimateTypes.m
%------------------------------------------------------------------
%July,2017
%modified May,2018
%Anindita Nath
%University of Texas at El Paso
%------------------------------------------------------------------
% Input:  filedirpath: The path to the parent directory of this script
%         trainpath:   The column vector containing path to all the language directories
%         testpath:    Duplicate column vector
% Output: saves ouput in .mat files and prints the same in Lorelei approved json schema
%--------------------------------------------------------------------------
function outputDir=estimateTypes(outputPath,trainpath,testpath,trainname,testname,featurefile,newOroldAnno)
%creating an output directory in the provided path 'outputDirPath' where all of this script's output will be saved
[Pathstr,FolderName] = fileparts(outputPath);
outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\', trainname,'_',testname,'\');
%disp(outputDir);
[status,msg]= mkdir(outputDir);
cd(outputDir);
%name the output.mat files to be placed in the above directory 
refmatfile=strcat(outputDir,'refdataType');
estimatesmat=strcat(outputDir,'estimatesType');
neighbormat=strcat(outputDir,'neighborpertestaudioType');
testmatfile=strcat(outputDir,'testdataType');

[typeList, confusionMatrix] = setGlobals(newOroldAnno);
ntypes = length(typeList);   %a11 situation types
featurelist = getfeaturespec(featurefile);
%[devsetDir, examined, typesPresent, evalsetDir] = uyghurInfo(trainpath,testpath); %code for uyghur data
examinedalltrain={};
typesPresentalltrain={};
refnames=[];
reftimestamps=[];
refFeatures=[];
perFileTypes=[];
refTypes=[];
for i=1:size(trainpath,1)
    [devsetDir_pertr, examined, typesPresent, evalsetDir] = trained(trainpath(i,:), testpath,newOroldAnno);
    %disp(examined);
    %disp(typesPresent);
    %disp(size(examined));
    %disp(size(typesPresent));
    [dirInExamined]=unique(examined(:,1));   
    [rowSkipped,colSkipped]=find(typesPresent==-1);% count the skipped # -1s
    rowsSkipped=unique(rowSkipped);
    %disp(rowsSkipped);
    %disp(size(rowsSkipped));
    [rowNotSkipped,colNotSkipped]=find(typesPresent(:,3)~=-1);% count nonskipped rows
    rowsNotSkipped=unique(rowNotSkipped);
    %disp(size(rowsNotSkipped));
    %disp(typesPresent);
    %disp(size(typesPresent));
    typesPresent=typesPresent(rowNotSkipped,:);
    %disp(typesPresent);
    %disp(size(typesPresent));
    [temp,row,col]=unique(typesPresent(:,1),'last');
    [dirInTypesPresent]=unique(typesPresent(:,1))
    %disp(temp);
    %disp(size(temp));
    %rowfrom2nd=row(2:end)- row(1:end-1);
    %rowfrom1st=vertcat(row(1),rowfrom2nd);
    %disp(size(rowfrom1st));    
    %disp(col);
    if(size(rowsSkipped,1)~=0) % if rows have been skipped 
        %examined(:,2)=rowfrom1st'; % reduced the number of audios in each directory by #skipped audios    
         for indicesTypesPresent=1:length(dirInTypesPresent)
            for indicesExamined=1:length(dirInExamined)
                if(dirInTypesPresent(indicesTypesPresent)==dirInExamined(indicesExamined))
                    %disp(dirInTypesPresent(indicesTypesPresent));
                    %disp(dirInExamined(indicesExamined));
                    %disp(indicesExamined);
                    %disp(sum(typesPresent(:,1)==dirInTypesPresent(indicesTypesPresent)));
                    examined(indicesExamined,2)=sum(typesPresent(:,1)==dirInTypesPresent(indicesTypesPresent));
              
                end
            end
        end
    end
    %disp(examined);
    
    examinedalltrain=vertcat(examinedalltrain,{trainpath(i,:) examined});
    typesPresentalltrain=vertcat(typesPresentalltrain,{trainpath(i,:) typesPresent});

    % examined = [[021 005]]; %temporary, use only when running just to force pitchcache creation %code for uyghur data

    % the reference data : running MakeTrackMonster.m in this method on the
    % training audio to return the name,pathces,features in each patch,types in each patch, types per audio
 
    [refnames_pertr,reftimestamps_pertr,refFeatures_pertr, refTypes_pertr, perFileTypes_pertr] = prepRefData(devsetDir_pertr,evalsetDir,trainname(i,:),testname, examined, typesPresent, featurelist);

    if(refnames==0)
        refnames=refnames_pertr;
        reftimestamps=reftimestamps_pertr;
        refFeatures=refFeatures_pertr;
        refTypes=refTypes_pertr;
        perFileTypes=perFileTypes_pertr;
    else
        refnames=vertcat(refnames,refnames_pertr);
        reftimestamps=vertcat(reftimestamps,reftimestamps_pertr);
        refFeatures=vertcat(refFeatures,refFeatures_pertr);
        refTypes=vertcat(refTypes,refTypes_pertr);
        perFileTypes=vertcat(perFileTypes,perFileTypes_pertr);
    end
   
end

save(refmatfile,'refnames','examinedalltrain','typesPresentalltrain','reftimestamps', 'refFeatures', 'refTypes', 'perFileTypes','-v7.3');% save the reference data

% code for uyghur data

% [reftimestamps,refFeatures, refTypes, perFileTypes] = prepRefData(devsetDir, examined, typesPresent, featurelist);
% [refFeatures, refTypes, perFileTypes] = prepRefData(devsetDir, examined, typesPresent, featurelist);
%  save('refData','refFeatures', 'refTypes', 'perFileTypes');

% these 3 lines are for experimenting treating the dev set as test data
% testdataType = 'dev';
% rootdir = devsetDir
% [nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(examined, devsetDir);

% another set of test data: the eval set
testdataType = 'eval';
folders = getfolders(evalsetDir);
evalDirCount = length(folders);
%disp(evalDirCount);
first80=floor((80/100)*evalDirCount);% first 80 percent of audio directories in the language
from81st=first80+1;% the 81st directory
evaldataspec = [(from81st:evalDirCount)'  zeros(evalDirCount-first80,1)];% the eval/test set consists of remaining 20 audio directories in that language 
%evaldataspec = [(1:evalDirCount)'  zeros(evalDirCount,1)];% all the audio directories in the language as the eval/test set

% eval set when the directory numbers are not continuos 
%evaldataspec = [[2,6,9,12,15,16,18,19,21,24,25,27,28,31,32,33,34,37,40,41,43,44,45,46,48,51,52,56,57,58,60,62,64,65,67,69,70,74,77]'  zeros(evalDirCount,1)];
%evaldataspec = [[2,6,9]'  zeros(evalDirCount,1)];
%evaldataspec = [[1,2,23,30]'  zeros(evalDirCount,1)];

%code for uyghur data
% evaldataspec = [(31:59)'  zeros(length(31:59),1)];
% evaldataspec = [(31:31)'  zeros(length(31:31),1)];
% evaldataspec = [(11:20)'  zeros(length(11:20),1)];
% evaldataspec = [(2:2)'  zeros(length(2:2),1)];
% evaldataspec = [12 0; 13 0];  % a managable small test set
% evaldataspec = [63 0; 46 0];  % a managable tiny test set
% evaldataspec = [(27:86)'  zeros(60,1)];   % tmp, just to force the remaining pitch computations

[nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(evaldataspec, evalsetDir);

rootdir = evalsetDir;
neighbor=struct();% conatins data of neighbors as obtained after running knn
test=struct();% contains test patches and testfeatures per patch after running MakeTrackMonster.m on test audio with the feature file
flag=0;% gets incremented every time the following code encounters a pitchCache file

 for i=1:nfiles      
     if(strcmp(basenames(i),'pitchCache')==0)
        
         trackspec = singleFileTrackspec(rootdir, dirlist(i), filelist(i), testdataType,trainname,testname);
         rawEstimates = estimatePresenceOfTypes(trackspec, refnames,reftimestamps,refFeatures, refTypes, featurelist, false);
         
         neighbor(i).testaudio=trackspec.filename;% saving the name of test audio in neighbor sturct
         test(i).testaudio=trackspec.filename;% saving the name of test audio in test sturct
         neighbor(i).testpatches=rawEstimates.testimestamps;% saving the testpatches of test audio in neighbor sturct
         test(i).testpatches=rawEstimates.testimestamps;%saving the testpatches of test audio in test sturct
         test(i).testfeatures=rawEstimates.testfeatures;%saving the test festures of test audio in test sturct
         
         estimatespertestrow=rawEstimates.votePerTest * confusionMatrix;%estimates per patch of test audio
         normalizedEstimatespertestrow= normalizeTo01(estimatespertestrow);% normalizing estimates per test patch  
         neighbor(i).pertestprediction=normalizedEstimatespertestrow;% saving normalized estimates per test patch  in the neighbor struct      
         neighbor(i).namespatches=rawEstimates.namespatches;%saving names of neighboring audio/audios and corresponding patches given by knn in the neighbor sruct
         estimates = rawEstimates.stancePrediction * confusionMatrix;% estimates for each type at the segment level i.e. for the entire test audio
         
         allEstimates(i,:) = estimates;
     else
         flag=flag+1;% if it not a audio but a pitchCache
         allEstimates(i,:)=-0.001; % inserting spurious negative number for estimates corresponding to pitchCache
     end
 end  
  
%%%%pitchCache.....
%following things are needed to be done because of unwanted entries generated because of reading pitchCache
i=i-flag;
neighdim=length(neighbor);
for neigh=neighdim:-1:1
    if(isempty(neighbor(neigh).testaudio))
         neighbor(neigh)=[]; % deleting empty rows from structure, 'neighbor' generated because of reading pitchCache
    end
end

for k = 1:length(neighbor) 
  save(neighbormat,'neighbor');% saving the neighbor structure in a .mat file
end 

testdim=length(test);
for testi=testdim:-1:1
    if(isempty(test(testi).testaudio))
         test(testi)=[];  % deleting empty rows from structure, 'test' generated because of reading pitchCache
        
    end
end
for k = 1:length(test)
  save(testmatfile,'test');  % saving the test structure in a .mat file    
end 
 
  
basedim=length(basenames);%basenames : row vector containing names of audio files
for base=basedim:-1:1
     if(strcmp(basenames{base},'pitchCache')>0)
      basenames(base)=[]; % deleting those cells from basenames which has 'pitchCache'
     end
end   
      
rows_to_remove = any(allEstimates==-0.001, 2);
allEstimates(rows_to_remove,:) = []; % delete negative rows,generated for reading pitchCache
%%%....pitchCache

normalizedEstimates = normalizeTo01(allEstimates);% normalizing type scores between 0 to 1

%estimates(type confidence scores) less than 0.05 are hard-coded to 0.0511  
%previous code
% outfile = sprintf('utep-%s.txt', datestr(now, 'mmmdd-HH-MM'));
% save('estimates', 'i', 'typeList', 'basenames', 'normalizedEstimates', 'outfile');

%creating the json file template

save(estimatesmat, 'i', 'typeList', 'basenames', 'normalizedEstimates');% saving the estimates in a .mat file


fprintf('processed %d files\n', length(dirlist));

%will be required when no annotation data for eval set is given
if strcmp(testdataType,'dev')
    evaluatePredictionQuality(ntypes, perFileTypes, allEstimates);
end  
end
%----------------------------------------------------------------------------
function evaluatePredictionQuality(ntypes, perFileTypes, allEstimates)
% evaluate prediction quality
% veridical is 0 or 1.  Since the metric is AOC, we only care about ranking
% therefore  high correlation is more informative than low RMSE
sum = 0;
for i = 1:ntypes
    size(perFileTypes)
    size(allEstimates)
    corrMatrix = corrcoef(perFileTypes(:,i), allEstimates(:,i));
    corr = corrMatrix(1,2);
    fprintf('performance (correlation) for type %2d is %.2f\n', i, corr);
    sum = sum + corr;
end
fprintf('average correlation across all  types is %.2f\n', sum / ntypes);
end
%----------------------------------------------------------------------------
% returns paired lists of directories and files, for convenient iteration
function [filesProcessed, basenames, dirlist, filelist, explicit] = ...
	 createFlatLists(dirsAndFileCounts, rootDir)
 filesProcessed = 0;
 for thisDir = 1:size(dirsAndFileCounts,1)
     dirnum = dirsAndFileCounts(thisDir, 1);
     directoryPath = sprintf('%s%03d/AUDIO/', rootDir, dirnum);
     %     rmpc=strcat(directoryPath,'pitchCache'); % removes pitchcache each time
     %     status=rmdir(rmpc,'s');
     contents = dir(directoryPath);
     contents = contents(3:end);  % to skip '.' and '..'
     filenumInDir = 0;
     for fi = 1:length(contents)
         fileitem = contents(fi);
         [~, basename, extension] = fileparts(fileitem.name);
         %       if  ~strcmp(extension,'.flac')
         % 		    % iterate over only flac files
         %       	continue
         %       end
         filenumInDir = filenumInDir + 1;
         filename = sprintf('%s.au', basename);
         filesProcessed = filesProcessed + 1;
         dirlist(filesProcessed) = dirnum;
         filelist(filesProcessed) = filenumInDir;
         basenames{filesProcessed} = basename;
         explicitlyJudged = (filenumInDir <= dirsAndFileCounts(thisDir, 2));
         %      fprintf('directoryPath %s, filenumInDir %d, filename %s, dirsAndFileCounts %d \n', ...
         %	      directoryPath, filenumInDir, filename, explicitlyJudged);
         explicit(filesProcessed) = explicitlyJudged;
     end
 end
end 
%----------------------------------------------------------------------------

% massage the filename into a the format expected by makeTrackMonster
function trackspec = singleFileTrackspec(rootdir, dirnum, filenum, dirType,trainname,testname)
  [dirname, filename, path] = assembleName(rootdir, dirnum, filenum, dirType,trainname,testname);
  trackspec.directory = dirname; 
  trackspec.filename = filename;
  trackspec.path = path;
  trackspec.side = 'l';
end
%-----------------------------------------------------------------------------
function [dirname, filename, path] = assembleName(rootdir, dirnum, filenum, dirType,trainname,testname)
  %fprintf('assemble name %s %d %d\n', rootdir, dirnum, filenum);
  if strcmp(dirType, 'dev')
    dirname = sprintf('%s%03d/AUDIO/', rootdir, dirnum);
    filename = sprintf('%s_%03d_%03d.au',trainname, dirnum, filenum);
  elseif strcmp(dirType, 'eval')
    dirname = sprintf('%s%03d/AUDIO/', rootdir, dirnum);
    filename = sprintf('%s_%03d_%03d.au',testname,dirnum, filenum);
  else
    fprint('bad dirType %s!\n', dirtype);
  end
  path = [dirname filename];
end
%-----------------------------------------------------------------------------
% returns estimates of the presence of all situation types in the test audio
function estimates = estimatePresenceOfTypes(trackspec, refnames,reftimestamps,refFeatures, refTypes, featurelist, realFlag)
[~, queryFeatures] = makeTrackMonster(trackspec, featurelist);
querytimestamps=((1:size(queryFeatures,1)).* 0.01)';

queryFeatures = queryFeatures(10:10:end,:);
querytimestamps=querytimestamps(10:10:end,1);

fprintf('size(queryFeatures) = (%d, %d); ', size(queryFeatures));
fprintf('size(refFeatures) = (%d, %d)\n', size(refFeatures));

[stancePrediction, votePerTest, neighbors,neighnames,neighdisnames,neighpatches,namespatches,uniquenamespatches] =....
    knnForTypes(queryFeatures, querytimestamps,refFeatures, refTypes,reftimestamps,refnames,3);

estimates.stancePrediction=stancePrediction;
estimates.votePerTest=votePerTest;
estimates.testimestamps=querytimestamps;
estimates.neighbors=neighbors;
estimates.neighnames=neighnames;
estimates.neighdisnames=neighdisnames;
estimates.neighpatches=neighpatches;
estimates.namespatches=namespatches;
estimates.uniquenamespatches=uniquenamespatches;
estimates.testfeatures=queryFeatures;   
end
%-----------------------------------------------------------------------------
function [typeList, confusionMat] = setGlobals(newOroldAnno)
typeList = cell(1,11);
if(strcmp(newOroldAnno,'old')>0)
    typeList{1} = 'Civil Unrest or Wide-spread Crime';
    typeList{2} = 'Elections and Politics';
    typeList{3} = 'Evacuation';
    typeList{4} = 'Food Supply';
    typeList{5} = 'Infrastructure';
    typeList{6} = 'Medical Assistance';
    typeList{7} = 'Shelter';
    typeList{8} = 'Terrorism or other Extreme Violence';
    typeList{9} = 'Urgent Rescue';
    typeList{10} = 'Utilities, Energy, or Sanitation';
    typeList{11} = 'Water Supply';
else
% new type annotations
        typeList{1} = 'crimeviolence';
        typeList{2} = 'regimechange';
        typeList{3} = 'evac';
        typeList{4} = 'food';
        typeList{5} = 'infra';
        typeList{6} = 'med';
        typeList{7} = 'shelter';
        typeList{8} = 'terrorism';
        typeList{9} = 'search';    
        typeList{10} = 'utils';    
        typeList{11} = 'water';
end
% using the types in the order given, confusion matrix is proportional to
rawConfusionMat = [ ...
		 [100  20  10   5   5   5   5   5     5  20   5]; ...% civil unrest or widespread crime
		 [ 20 100   5   5   5   5   5   5     5  20   5]; ...% elections and politics
		 [ 10   5 100   5  20  10  10  10    30  10  10]; ...% evacuation 
		 [  5   5	  5 100   5  10  10  10    10  10  40]; ...% food supply
		 [  5   5	 20   5 100   5   5  10     5  10   5]; ...% urgent rescue
		 [  5   5  10  10	  5 100  40   5    40   5  20]; ...% utilities, energy, or sanitation
		 [  5   5  10  10	  5  40 100   5    50   5  20]; ...% infrastructure
		 [  5   5	 10  10  10   5  5  100	    5   5   5]; ...% medical assistance
		 [  5   5	 30  10	  5  40	 50   5   100   5   5]; ...% shelter
		 [ 20  20	 10  10	 10   5	  5   5     5 100   5]; ...% terrorism or extreme violence
		 [  5   5  10  40   5  20  20   5     5   5 100]; ...% water supply 
	       ];
  %fprintf('checking symmetry: %d\n', isequal(rawConfusionMat, rawConfusionMat'));
  % normalize so rows sum to one
  confusionMat = (rawConfusionMat ./ repmat(sum(rawConfusionMat),11,1))';
end
%------------------------------------------------------------------
% sets up the trainingset parallel matrices of features and types
% one row per timepoint; each row has many features and 11 booleans for types
function [allnames,alltimestamps,allfeats, alltypes, perFileTypes] = ...
	 prepRefData(devsetdir,evalsetdir,trainname,testname, examined, annotations, featurelist)
 allfeats = [];
 alltypes = [];   % per row types
 allnames = [];
 names=[];
 alltimestamps =[];
 perFileTypes = [];

 [nfiles, basenames, dirlist, filelist, explicit] = createFlatLists(examined, devsetdir);
 
 perFileTypes = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, annotations);
  
if(strcmp(devsetdir,evalsetdir))
    dirtype='eval';    
else
    dirtype='dev';
end
% flag1=0;
%  for i= 1:nfiles
%      if(strcmp(basenames(i),'pitchCache')>0)
%          flag1=flag1+1;% if the file is pitchCache
%      end
%  end
%  nfiles=nfiles-flag1;% the number of files minus the pitchCache
 j=1;
 for i= 1:nfiles

    if (~explicit(i))% treats pitchCache as a non-explicit audio 
        continue;
    end    
    if(strcmp(basenames(i),'pitchCache')==0)
        
        trackspec = singleFileTrackspec(devsetdir, dirlist(i), filelist(i), dirtype,trainname,testname);
        filename=trackspec.filename;
        names = filename;
        %[~, monster] = makeTrackMonster(trackspec, featurelist);
        [~, monster] = makeTrackMonster(trackspec, featurelist);
        timestamps=((1:size(monster,1)).* 0.01)';
        
        monster = monster(10:10:end,:);%downsample by 100 ms
        timestamps=timestamps(10:10:end,1);
        names=repmat(names,size(monster,1),1);      
        
        
        if (~explicit(i))
            monster = monster(1:6:end,:);% further downsample to save time
            timestamps=timestamps(1:6:end,1);
            names=repmat(names,size(monster,1),1);
           
        end      
        %copiedTypes = repmat(perFileTypes(i,:), length(monster), 1);       
        copiedTypes = repmat(perFileTypes(j,:), length(monster), 1);
%         if length(allfeats) == 0
%             allfeats = monster;
%             alltypes = copiedTypes;
%             alltimestamps= timestamps;
%             allnames= names;         
%         else
%             allfeats = vertcat(allfeats, monster);
%             alltypes = vertcat(alltypes, copiedTypes);
%             alltimestamps=vertcat(alltimestamps, timestamps);
%             allnames=vertcat(allnames,names);           
%         end
        allfeats = vertcat(allfeats, monster);
        alltypes = vertcat(alltypes, copiedTypes);
        alltimestamps=vertcat(alltimestamps, timestamps);
        allnames=vertcat(allnames,names);    
        j = j+1;
    end
    
    
    if (size(alltypes,1)==length(allfeats))
        alltypes=alltypes;
    else
        diff=(size(alltypes,1)-length(allfeats));% some extra rows in alltypes matrix enter due to pitchCache 
        alltypes=alltypes((1:end-diff),:);% deletes the extra rows
    end    
    fprintf('reference data: size(alltypes) = (%d, %d), ', size(alltypes));
    fprintf('length(allfeats) = %d\n', length(allfeats));
 end 
end
%-----------------------------------------------------------------------------
function veridicalTypes = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, annotations)
for i= 1:nfiles  
    if(strcmp(basenames(i),'pitchCache')==0)        
        dirnum = dirlist(i);
        filenum = filelist(i);        
        if explicit(i)
            typeVec = setupTypeVec(dirnum, filenum, annotations);            
        else
            % tho not listened to, seemed unlikely to relate to disasters            
            typeVec = 0.04 * ones(1,11);            
        end
        veridicalTypes(i,:) = typeVec;        
    else
        veridicalTypes(i,:) = -0.001;% insert negative spurious values if pitchCahe is encountered and treated as audio
    end
    %    fprintf('for dir %03d file %03d, typeVector is %.2f %.2f %.2f %.2f\n', ...
    %	    dirnum, filenum, typeVec(1), typeVec(2), typeVec(3), typeVec(4));
    
end
rows_to_remove = any(veridicalTypes==-0.001, 2);
veridicalTypes(rows_to_remove,:) = []; % delete negative rows,corresponding to pitchCache
    
end
%------------------------------------------------------------------
% returns a boolean vector
function typesPresent = setupTypeVec(dirnum, filenum, annotations)
typesPresent = zeros(1,11);
for i=1:length(annotations)
    if annotations(i,1) == dirnum && annotations(i,2) == filenum;
        typePresent = (annotations(i,3));
        typesPresent(typePresent) = true;
        %  fprintf('looking for  non-zero annotations; found one for dir %d file %d type %d \n', ...
        %    dirnum, filenum, typePresent);
    end
end

end
%-----------------------------------------------------------------------------
% right now, not being used, may be used if evaluation script is not given
function A = auc(pred, ground_truth)
% Computes the area under the ROC curve
% pred is in the [0,1] range, ground truth is either 0 or 1
% Programmed by Olac Fuentes
% Last modified December 2, 2016
pos = sum(ground_truth);
neg = length(ground_truth) - pos;
[sorted_pred, ind] = sort(pred);
sorted_gt = ground_truth(ind);
c = cumsum(sorted_gt);
c = c(end) - c;
A = sum(c(sorted_gt==0))/pos/neg;
end
%-----------------------------------------------------------------------------
% examined is the duplet, types present is the triplet,auto generated 
% manually in previous code
function [devsetDir,examined,typespresent,evalsetDir]= trained(trainpath,testpath,newOroldAnno)

devsetDir = strrep(trainpath,'\','/');
evalsetDir = strrep(testpath,'\','/');
folders=getfolders(devsetDir);
%noofdir=length(folders);% all the audio directories in the language set used for training
%noofdir=9;% only first 10 audio directories in the language used for training
noofdir=floor((80/100)*length(folders));%first 80 percent of the audio directories in the language set used for training 
%noofdir=1;
examined=[];
typespresent=[];
for i=1:noofdir 
    %audio directory path
    audiodir = sprintf('%s%s/AUDIO/', devsetDir, folders(i).name);% 'path to traindir/001/AUDIO/'    
    %audio files in each directory
    audiopath=strcat(audiodir,'*.au');
    audiofiles=dir(audiopath);
    %length(audiofiles)    
    audioname=[];
    for j=1:length(audiofiles)
        audioname=audiofiles(j).name;%ARA_001_001.au % at the end of the loop, stores the last file in the directory
    end    
    lastaudio=audioname; %last audio in the directory
    %disp(lastaudio);
    lastaudiolast3=lastaudio(end-5:end-3); %number of the audio %001    
    %creating examined
    if (length(examined)==0)
        examined=[str2num(folders(i).name) str2num(lastaudiolast3)];
    else
        examined=vertcat(examined,[str2num(folders(i).name) str2num(lastaudiolast3)]);%duplet%the directory number, the number of the last audio in it
    end
       
    % annotations directory
    annodir = sprintf('%s%s/ANNOTATION/', devsetDir, folders(i).name);% 'path to traindir/001/ANNOTATION/'
    %disp(annodir);
    
    % annotation files in each directory
    annopath=strcat(annodir,'*.txt');
    annofiles=dir(annopath);
   %disp(length(annofiles));
    
    annoname=[];
    annonamelast3=[];
    for k=1:length(annofiles)        
        if (length(annoname)==0 && length(annonamelast3)==0 )
            %disp(annodir);
            %annoname = strcat(annofiles(k).folder ,'\' ,annofiles(k).name);
            annoname = strcat(annodir ,annofiles(k).name);
            %disp(annoname);
            annonamelast3=annofiles(k).name(end-6:end-4);%001
        else
            %annoname=vertcat(annoname,strcat(annofiles(k).folder ,'\' ,annofiles(k).name));%ARA_001_001.txt
            annoname=vertcat(annoname,strcat(annodir ,annofiles(k).name));%ARA_001_001.txt
                                                         %ARA_001_002.txt
                                                         %ARA_001_002.txt
            annonamelast3=vertcat(annonamelast3,annofiles(k).name(end-6:end-4));%001
                                                                                %002
        end        
    end
    % parsing annotation files and creating typespresent    
    for l=1:size(annoname,1)
        %fprintf('%d_%d,%s\n',i,l,annoname(l,:));
        parsedtype=parse(annoname(l,:),newOroldAnno);
        disp(parsedtype);
        for p=1:size(parsedtype,1)
            %typespresent-the triplet: directory number, audio file/annotation file number,typenumber present as per the given annotations
            if (length(typespresent)==0)
                typespresent=[str2num(folders(i).name) str2num(annonamelast3(l,:)) parsedtype(p,1)];
            else
                typespresent=vertcat(typespresent,[str2num(folders(i).name) str2num(annonamelast3(l,:)) parsedtype(p,1)]);
            end            
        end
        %disp(typespresent);
    end
end  
typespresent=unique(typespresent,'rows');
end
%-----------------------------------------------------------------------------
function parsedtype=parse(filename,newOroldAnno)
    %fprintf('%s\n',filename);
    fileID = fopen(filename);
    alllines= textscan(fileID,'%s','Delimiter','\n');%read all the lines in annotation file
    firstline=alllines{1}{1};% Type: Nameof Type

    splitfirstline= strsplit(firstline,{':',','});%e.g. %'Type' 'Typename1' 'TypeName2'%separate the types delimited by commas
    splitfirstline=strtrim(splitfirstline);%without the whitespaces
    %disp(splitfirstline);
    if(strcmp(newOroldAnno,'old')>0)
        %create a typelist of 13 instead of 11 types, reason explained below
        typeList = cell(1,13);
        typeList{1} = 'Civil Unrest or Wide-spread Crime';
        typeList{2} = 'Elections and Politics';
        typeList{3} = 'Evacuation';
        typeList{4} = 'Food Supply';
        typeList{5} = 'Infrastructure';
        typeList{6} = 'Medical Assistance';
        typeList{7} = 'Shelter';
        typeList{8} = 'Terrorism or other Extreme Violence';
        typeList{9} = 'Urgent Rescue';
        %Type #10:'Utilities,Energy,or Sanitation' is delimited by commas,....
        %hence,line 594 splits it into 3 different types instead of 1
        typeList{10} = 'Utilities';
        typeList{11} = 'Energy';
        typeList{12} = 'or Sanitation';
        typeList{13} = 'Water Supply';
    else
    % new typelist with new forms of annotations
        typeList = cell(1,11);
        typeList{1} = 'crimeviolence';
        typeList{2} = 'regimechange';
        typeList{3} = 'evac';
        typeList{4} = 'food';
        typeList{5} = 'infra';
        typeList{6} = 'med';
        typeList{7} = 'shelter';
        typeList{8} = 'terrorism';
        typeList{9} = 'search';    
        typeList{10} = 'utils';    
        typeList{11} = 'water';
    end
    parsedtype=[];
    for i=2:size(splitfirstline,2)% name of the types start from the second word in first line of annotation file
        for j=1:size(typeList,2)
            %disp(splitfirstline{i});
            
             if(strcmp(splitfirstline{i},typeList{j})>0)
                    %for old annotations of situation types
                    if(strcmp(newOroldAnno,'old')>0)
                        if(j==10 || j==11 || j==12)
                            j=10;%the 3 extra type numbers are merged to 1
                        elseif(j==13)
                            j=11;%'Water Supply' which was treated as type #13 in line 613 goes back to being type#11
                        else
                            j=j;%the rest type numbers remain as it is
                        end  
                   end
                % for new annotations corresponding to situation types               
                
                 
                %disp(j);
                %parsedtype= j;
                %disp(parsedtype);
            
                if(length(parsedtype)==0)
                    parsedtype= j;
                else
                    parsedtype=vertcat(parsedtype,j);% column vector containing the number of the type(s)(1 to 11) ....
                                                     %present in the corresponding annonation file
                end
                
            end
            if(strcmp(splitfirstline{i},'Skipped')>0)
            parsedtype = -1;
            return;
            end
    
        end
    end
    %disp(parsedtype);
    %fclose(fileID);
    status=fclose('all');
end
%-----------------------------------------------------------------------------
function folders = getfolders(path)
%get all the folders in the given path except . and ..
folders = dir(path);

for k = length(folders):-1:1
    % remove non-folders
    if ~folders(k).isdir
        folders(k) = [ ];
        continue
    end

    % remove folders starting with .
    fname = folders(k).name;
    if fname(1) == '.'
        folders(k) = [ ];
    end
end
end
%-----------------------------------------------------------------------------
% code for uyghurData
% 
% function [devsetDir, examined, typesPresent, evalsetDir] = uyghurInfo(trainpath,testpath)% 
%  devsetDir = strrep(trainpath,'\','/');
%  evalsetDir = strrep(testpath,'\','/'); 
% 
% % listing, for each directory examined, the dirnum and the last file listened to% 
% %   examined = [
% %             [001 002];
% % 	     [002 002];
% % 	   ];
%     examined = [
%             [1 2];
% 	     [2 2];
% 	   ];
%     
% 
% % a triple of directory, file, and type (1..11)
% % typesPresent = [
% %     [001 001 2];
% %     [001 002 1];
% %     [002 001 8];
% %     [002 002 10]; 
% % ];
% typesPresent = [
%     [1 1 2];
%     [1 2 1];
%     [2 1 8];
%     [2 2 10]; 
% ];% 
% end
%-----------------------------------------------------------------------------

