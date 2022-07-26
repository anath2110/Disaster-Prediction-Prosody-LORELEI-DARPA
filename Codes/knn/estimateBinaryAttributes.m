function univefileSlashes=estimateBinaryAttributes( filedirpath,trainpath,testpath,trainname,testname,featurefile,newOroldAnno)

%creating the directory in the path of the current script where all its output will be saved
[Pathstr,FolderName] = fileparts(filedirpath);
univfile=sprintf('%s/%s/SF_OP/%s_%s/', Pathstr,FolderName,trainname,testname);
univefileSlashes=strcat(Pathstr,'\',FolderName,'SF_OP','\', trainname,'_',testname,'\');

[~,~]= mkdir(univfile);
cd(univfile);

%create the .mat files in the above directory where all output will be saved
refmatfile=strcat(univfile,'refdataBinary');
estimatesmat=strcat(univfile,'estimatesBinary');
neighbormat=strcat(univfile,'neighborpertestaudioBinary');
testmatfile=strcat(univfile,'testdataBinary');

[typeListTime,typeListResolution,typeListUrgency, confusionMatrix] = setGlobals(newOroldAnno);
ntypes = length(typeListTime); %Binary types

featurelist = getfeaturespec(featurefile);

examinedalltrain={};
typesPresentalltrain={};
refnames=[];
reftimestamps=[];
refFeatures=[];
perFileTypes=[];
refTypes=[];
%disp('uptil this:');
testSetDir = strrep(testpath,'\','/');
for i=1:size(trainpath,1)
    trainSetDir = strrep(trainpath(i,:),'\','/');
    [examined, typesPresent] = trained(trainSetDir,newOroldAnno);
    %disp('BEFORE:');
    %disp((examined));
    [dirInExamined]=unique(examined(:,1));                                                
    %disp(dirInExamined);
    %disp(typesPresent);
%     disp(size(typesPresent));
   
    %skip entire audio if any one attribute is annotated 'Skipped' i.e. -1
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
        
        %examined( any(examined==0, 2),:) = []; % removes all rows with all zero
    end
  


   % disp(examined);   
   
       
    examinedalltrain=vertcat(examinedalltrain,{trainpath(i,:) examined});
    typesPresentalltrain=vertcat(typesPresentalltrain,{trainpath(i,:) typesPresent});
    
    % the reference data : running MakeTrackMonster.m in this method on the
    % training audio to return the name,pathces,features in each patch,types in each patch, types per audio
    
    [refnames_pertr,reftimestamps_pertr,refFeatures_pertr, refTypes_pertr, perFileTypes_pertr] = prepRefData(trainSetDir,testSetDir,trainname(i,:),testname, examined, typesPresent, featurelist);

    refnames=vertcat(refnames,refnames_pertr);
    reftimestamps=vertcat(reftimestamps,reftimestamps_pertr);
    refFeatures=vertcat(refFeatures,refFeatures_pertr);
    refTypes=vertcat(refTypes,refTypes_pertr);
    perFileTypes=vertcat(perFileTypes,perFileTypes_pertr);
   
end

save(refmatfile,'refnames','examinedalltrain','typesPresentalltrain','reftimestamps', 'refFeatures', 'refTypes', 'perFileTypes','-v7.3');% save the reference data


% these 3 lines are for experimenting treating the dev set as test data
% testdataType = 'dev';
% rootdir = devsetDir
% [nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(examined, devsetDir);

testSetDir = strrep(testpath,'\','/');
% another set of test data: the eval set
testdataType = 'eval';
folders = getfolders(testSetDir);
evalDirCount = length(folders);
first80=floor((80/100)*evalDirCount);% first 80 percent of audio directories in the language
from81st=first80+1;% the 81st directory
evaldataspec = [(from81st:evalDirCount)'  zeros(evalDirCount-first80,1)];% the eval/test set consists of remaining 20 audio directories in that language 
%evaldataspec = [(1:evalDirCount)'  zeros(evalDirCount,1)];
%evaldataspec = [[2,6,9]'  zeros(evalDirCount,1)];
%evaldataspec = [[30]'  zeros(evalDirCount-first80,1)];
%evaldataspec = [[2,6,9,12,15,16,18,19,21,24,25,27,28,31,32,33,34,37,40,41,43,44,45,46,48,51,52,56,57,58,60,62,64,65,67,69,70,74,77]'  zeros(evalDirCount,1)];

[nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(evaldataspec, testSetDir);

rootdir = testSetDir;
neighbor=struct();% conatins data of neighbors as obtained after running knn
test=struct();% contains test patches and testfeatures per patch after running MakeTrackMonster.m on test audio with the feature file
flag=0;% gets incremented every time the following code encounters a pitchCache file


 for i=1:nfiles      
     if(strcmp(basenames(i),'pitchCache')==0)
        
         trackspec = singleFileTrackspec(rootdir, dirlist(i), filelist(i), testdataType,trainname,testname);
         rawEstimates = estimatePresenceOfTypes(trackspec, refnames,reftimestamps,refFeatures, refTypes, featurelist);
         
         neighbor(i).testaudio=trackspec.filename;% saving the name of test audio in neighbor sturct
         test(i).testaudio=trackspec.filename;% saving the name of test audio in test sturct
         neighbor(i).testpatches=rawEstimates.testimestamps;% saving the testpatches of test audio in neighbor sturct
         test(i).testpatches=rawEstimates.testimestamps;%saving the testpatches of test audio in test sturct
         test(i).testfeatures=rawEstimates.testfeatures;%saving the test festures of test audio in test sturct
         
         estimatespertestrow=rawEstimates.votePerTest;%estimates per patch of test audio
         normalizedEstimatespertestrow= normalizeTo01(estimatespertestrow);% normalizing estimates per test patch  
         neighbor(i).pertestprediction=normalizedEstimatespertestrow;% saving normalized estimates per test patch  in the neighbor struct      
         neighbor(i).namespatches=rawEstimates.namespatches;%saving names of neighboring audio/audios and corresponding patches given by knn in the neighbor sruct
         estimates = rawEstimates.stancePrediction;% estimates for each type at the segment level i.e. for the entire test audio
         
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
%for p=1:size(normalizedEstimates,1)
    %for q=1:size(normalizedEstimates,2)
%         if normalizedEstimates(p,q)<0.05
%             normalizedEstimates(p,q)=0.0511;
        
            %end
     %normalizedEstimates(p,q)=1;% baseline always predict 1
   % end
%end
%previous code
% outfile = sprintf('utep-%s.txt', datestr(now, 'mmmdd-HH-MM'));
% save('estimates', 'i', 'typeList', 'basenames', 'normalizedEstimates', 'outfile');

%creating the json file template

save(estimatesmat, 'i', 'basenames', 'normalizedEstimates');% saving the estimates in a .mat file
fclose('all');
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
    %size(perFileTypes)
    %size(allEstimates)
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
         [~, basename, ~] = fileparts(fileitem.name);
         filenumInDir = filenumInDir + 1;
         filesProcessed = filesProcessed + 1;
         dirlist(filesProcessed) = dirnum;
         filelist(filesProcessed) = filenumInDir;
         basenames{filesProcessed} = basename;
         explicitlyJudged = (filenumInDir <= dirsAndFileCounts(thisDir, 2));
         explicit(filesProcessed) = explicitlyJudged;
     end
 end
end 
%----------------------------------------------------------------------------

%-----------------------------------------------------------------------------
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
function estimates = estimatePresenceOfTypes(trackspec, refnames,reftimestamps,refFeatures, refTypes, featurelist)
    [~, queryFeatures] = makeTrackMonster(trackspec, featurelist);
    querytimestamps=((1:size(queryFeatures,1)).* 0.01)';

    queryFeatures = queryFeatures(10:10:end,:);
    querytimestamps=querytimestamps(10:10:end,1);

    fprintf('size(queryFeatures) = (%d, %d); ', size(queryFeatures));
    fprintf('size(refFeatures) = (%d, %d)\n', size(refFeatures));


    [stancePrediction, votePerTest, neighbors,neighnames,neighdisnames,neighpatches,namespatches,uniquenamespatches] =....
    regSegmentKNN_pNeigh(queryFeatures, querytimestamps,refFeatures, refTypes,reftimestamps,refnames,3);
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
function [typeListTime,typeListResolution,typeListUrgency, confusionMat] = setGlobals(newOroldAnno)
     if(strcmp(newOroldAnno,'old')>0)

        typeListTime = cell(1,2);
        typeListTime{1} = 'Current';
        typeListTime{2} = 'Not Current';

        typeListResolution = cell(1,2);
        typeListResolution{1} = 'Sufficient';
        typeListResolution{2} = 'Not Sufficient';

        typeListUrgency = cell(1,2);
        typeListUrgency{1} = 'Urgent';
        typeListUrgency{2} = 'Not Urgent';
        
    elseif(strcmp(newOroldAnno,'new')>0)
        
        typeListTime = cell(1,2);
        typeListTime{1} = 'current';
        typeListTime{2} = 'not_current';

        typeListResolution = cell(1,2);
        typeListResolution{1} = 'sufficient';
        typeListResolution{2} = 'insufficient';

        typeListUrgency = cell(1,2);
        typeListUrgency{1} = 'urgent';
        typeListUrgency{2} = 'not_urgent';
        
    end
    
    % using the types in the order given, confusion matrix is proportional to
    rawConfusionMat = [ ...
		 [100  0]; ...
		 [0  100]; ... 
	       ];
  % normalize so rows sum to one
  confusionMat = (rawConfusionMat ./ repmat(sum(rawConfusionMat),2,1))';
end
%------------------------------------------------------------------
% sets up the trainingset parallel matrices of features and types
% one row per timepoint; each row has many features and 11 booleans for types
function [allnames,alltimestamps,allfeats, alltypes, perFileTypes] = ...
	 prepRefData(trainSetDir,testSetDir,trainname,testname, examined, annotations, featurelist)
     allfeats = [];
     alltypes = [];   % per row types
     allnames = [];
     alltimestamps =[];

     [nfiles, basenames, dirlist, filelist, explicit] = createFlatLists(examined, trainSetDir);
     perFileTypes = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, annotations);

    if(strcmp(trainSetDir,testSetDir))
        dirtype='eval';    
    else
        dirtype='dev';
    end
%     flag1=0;
%      for i= 1:nfiles
%          if(strcmp(basenames(i),'pitchCache')>0)
%              flag1=flag1+1;% if the file is pitchCache
%          end
%      end
%      nfiles=nfiles-flag1;% the number of files minus the pitchCache
    j = 1;
     for i= 1:nfiles

        if (~explicit(i))% treats pitchCache as a non-explicit audio 
            continue;
        end    
        if(strcmp(basenames(i),'pitchCache')==0)
            trackspec = singleFileTrackspec(trainSetDir, dirlist(i), filelist(i), dirtype,trainname,testname);
            filename=trackspec.filename;
            names = filename;
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
                typeVec = 0.04 * ones(1,6);            
            end
            veridicalTypes(i,:) = typeVec;        
        else
            veridicalTypes(i,:) = -0.001;% insert negative spurious values if pitchCahe is encountered and treated as audio
        end
    end
    rows_to_remove = any(veridicalTypes==-0.001, 2);
    veridicalTypes(rows_to_remove,:) = []; % delete negative rows,corresponding to pitchCache

end
%------------------------------------------------------------------
% returns a boolean vector
function typesPresent = setupTypeVec(dirnum, filenum, annotations)
    typesPresent = zeros(1,6);
    %disp(length(annotations));
    for i=1:size(annotations,1)
        %disp(i);
        
        if annotations(i,1) == dirnum && annotations(i,2) == filenum;
            
            %disp(dirnum);
            %disp(filenum);
            time = (annotations(i,3));
            resolution = (annotations(i,4));
            urgent = (annotations(i,5));
            typesPresent(time) = true;
            typesPresent(resolution + 2) = true;
            typesPresent(urgent + 4) = true;
            %  fprintf('looking for  non-zero annotations; found one for dir %d file %d type %d \n', ...
            %    dirnum, filenum, typePresent);
        end
    end
end
%-----------------------------------------------------------------------------

%-----------------------------------------------------------------------------
% examined is the duplet, types present is the triplet,auto generated 
% manually in previous code
function [examined,typespresent]= trained(trainSetDir,newOroldAnno)
   folders=getfolders(trainSetDir);
   %noofdir=length(folders);% all the audio directories in the language set used for training
   %noofdir=9; 
   noofdir=floor((80/100)*length(folders));%first 80 percent of the audio directories in the language set used for training 
    examined=[];
    typespresent=[];
    for i=1:noofdir 
        %audio directory path
        audiodir = sprintf('%s%s/AUDIO/', trainSetDir, folders(i).name);% 'path to traindir/001/AUDIO/'   
        %audio files in each directory
        audiopath=strcat(audiodir,'*.au');
        audiofiles=dir(audiopath);
        lastaudio=audiofiles(length(audiofiles)).name; %last audio in the directory
        lastaudiolast3=lastaudio(end-5:end-3); %number of the audio %001    
        %creating examined
        examined=vertcat(examined,[str2num(folders(i).name) str2num(lastaudiolast3)]);%duplet%the directory number, the number of the last audio in it

        % annotations directory
        annodir = sprintf('%s%s/ANNOTATION/', trainSetDir, folders(i).name);% 'path to traindir/001/ANNOTATION/'

        % annotation files in each directory
        annopath=strcat(annodir,'*.txt');
        annofiles=dir(annopath);

        annoname=[];
        annonamelast3=[];
        for k=1:length(annofiles)        
                annoname=vertcat(annoname,strcat(annodir ,annofiles(k).name));
                annonamelast3=vertcat(annonamelast3,annofiles(k).name(end-6:end-4));                   
        end
        %disp('before parsing');
        % parsing annotation files and creating typespresent    
        for l=1:size(annoname,1)
            %fprintf('%d_%d,%s\n',i,l,annoname(l,:));
            parsedtypeTime=parse(annoname(l,:),2,newOroldAnno);
            parsedtypeResolution=parse(annoname(l,:),3,newOroldAnno);
            parsedtypeUrgency=parse(annoname(l,:),5,newOroldAnno);
            for p=1:size(parsedtypeTime,1)
                %typespresent-the triplet: directory number, audio file/annotation file number,typenumber present as per the given annotations
                typespresent=vertcat(typespresent,[str2num(folders(i).name) str2num(annonamelast3(l,:)) parsedtypeTime(p,1) parsedtypeResolution(p,1) parsedtypeUrgency(p,1)]);           
            end
        end
    end 
    typespresent(any(typespresent==0,2),:)=[];
    typespresent=unique(typespresent,'rows');
    
end
%-----------------------------------------------------------------------------
function parsedtype=parse(filename, numberOfLine,newOroldAnno)
    fprintf('%s\n',filename);
    fileID = fopen(filename);
    alllines= textscan(fileID,'%s','delimiter','\n');%read all the lines in annotation file
    selectedLine=alllines{1}{numberOfLine};
    splitselectedLine= strsplit(selectedLine,{':',','});%e.g. %'Type' 'Typename1' 'TypeName2'%separate the types delimited by commas
    splitselectedLine=strtrim(splitselectedLine);%without the whitespaces    
    
    if(strcmp(newOroldAnno,'old')>0)
        %Select binary attribute depending on number of line
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
    elseif(strcmp(newOroldAnno,'new')>0)
        %Select binary attribute depending on number of line
        if(numberOfLine == 2)
            typeList = cell(1,2);
            typeList{1} = 'current';
            typeList{2} = 'not_current';
        elseif(numberOfLine == 3)
            typeList = cell(1,2);
            typeList{1} = 'sufficient';
            typeList{2} = 'insufficient';
        elseif(numberOfLine == 5)
            typeList = cell(1,2);
            typeList{1} = 'urgent';
            typeList{2} = 'not_urgent';
        end  
    end
    if(strcmp(splitselectedLine{2},'Skipped')>0)
        parsedtype = -1;
        return;
    end
    if(strcmp(splitselectedLine{2},'n/a')>0)
        parsedtype = 0;
        return;
    end
    if(strcmp(splitselectedLine{2},typeList{1})>0)
        parsedtype = 1;
    else
        parsedtype = 2;
    end
    %status=fclose(fileID);
    status=fclose('all');
    %disp(status);
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
function [stancePrediction, votePerTest, neighbors,neighnames,neighdisnames,neighpatches,namespatches,uniquenamespatches] = ....
    regSegmentKNN_pNeigh(testdata, testtimestamps,Model, trainingResults,reftimestamps,refnames, k)
    %regSegmentNN predicts values for each segment testdata using...
    %Model(training features) and trainingResults(types per training patch)...
    %according to the k nearest neighbor algorithm and outputs the predicted values.
    votes = zeros(1, size(trainingResults,2));
    votePerTest = zeros(size(testdata,1), size(trainingResults,2));
    disp(size(votePerTest))
    [neighbors, distances] = knnsearch(Model,testdata,'K',k);
    
    %retrieving names,patches of the all 3 neighbour audio files
    neighnames=[];
    neighpatches=[];
    testpatchesneigh=[];
    for neighrow=1:size(neighbors,1)
        for neighcol=1:size(neighbors,2)
            neighnames=vertcat(neighnames,refnames(neighbors(neighrow,neighcol),:));
            neighdisnames=unique(neighnames,'rows');
            neighpatches=vertcat(neighpatches,reftimestamps(neighbors(neighrow,neighcol),1));
            testpatchesneigh=vertcat(testpatchesneigh,[testtimestamps(neighrow) reftimestamps(neighbors(neighrow,neighcol),1)]);
        end
    end
    namespatches=table(testpatchesneigh,neighnames);
    uniquenamespatches=unique(namespatches);

    distances = distances .^ 2 + 0.0000000001;
    %test every value
    for row = 1:size(testdata,1)
        %sums each squared element and keeps track of the index
        dist = distances(row,:);
        %get indices of the k nearest frames in the training data
        vals = neighbors(row,:);
        %get the type values of those k nearest frames from the
        %trainingResults
        vals = trainingResults(vals,:);
        %get the squared distances of the k nearest frames and invert them for
        %weights
        weights = (1 ./ dist)';
        % replicate the weights for each of the type predictions
        weights = repmat(weights,1,size(trainingResults,2));
        % weighted average = sum(value_i * weight_i) / sum(weight_i) for all i
        vals = vals .* weights;
        vals = sum(vals,1);
        vals = vals ./ (sum(weights, 1));
        votePerTest(row,:) = vals; %type prediction per row of testdata
        % add the weighted average to the running total
        for j = 1:size(votes,2)
            votes(1,j) = votes(1,j) + vals(1,j);
        end
    end
    %get the predictions by dividing the running sum of weighted averages by
    %the number of frames in the test data.

    stancePrediction = votes ./ size(testdata,1);
%     disp(size(stancePrediction))
%     disp(size(votePerTest))
%     disp(size(neighbors))
%     disp(size(neighnames))

end
