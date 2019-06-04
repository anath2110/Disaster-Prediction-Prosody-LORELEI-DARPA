function outputDir=estimateSFGravity(outputPath,trainpath,testpath,trainname,testname,featurefile,newOroldAnno)

%creating an output directory in the provided path 'outputDirPath' where
%all of this script's output will be saved
[Pathstr,FolderName] = fileparts(outputPath);
outputDir=strcat(Pathstr,'\',FolderName,'SF_OP','\', trainname,'_',testname,'\');
%disp(outputDir);
[status,msg]= mkdir(outputDir);
cd(outputDir);
%name the output.mat files to be placed in the above directory 
refmatfile=strcat(outputDir,'refdataSF');
estimatesmat=strcat(outputDir,'estimateSF');
neighbormat=strcat(outputDir,'neighborpertestaudioSF');
testmatfile=strcat(outputDir,'testdataSF');

[typeList,timeList,resolutionList,urgencyList, confusionMatrix] = setGlobals(newOroldAnno);

featurelist = getfeaturespec(featurefile);

examinedalltrain={};
typesPresentalltrain={};
refnames=[];
reftimestamps=[];
refFeatures=[];
perFileTypes=[];
refTypes=[];

testSetDir = strrep(testpath,'\','/');
for i=1:size(trainpath,1)
    trainSetDir = strrep(trainpath(i,:),'\','/');
    [examined, typesPresent] = getLabels(trainSetDir,newOroldAnno);
    %disp('BEFORE:');
    %disp((examined));
    [dirInExamined]=unique(examined(:,1));                                                
    %disp(dirInExamined);
    %disp(typesPresent);
    %disp(size(typesPresent));
   
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
    [dirInTypesPresent]=unique(typesPresent(:,1));
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
                    examined(indicesExamined,2)=sum(typesPresent(:,1)==...
                        dirInTypesPresent(indicesTypesPresent));
              
                end
            end
        end
        
        %examined( any(examined==0, 2),:) = []; % removes all rows with all zero
    end
    % disp(examined);   
          
    examinedalltrain=vertcat(examinedalltrain,{trainpath(i,:) examined});
    typesPresentalltrain=vertcat(typesPresentalltrain,{trainpath(i,:) typesPresent});
    
    % the reference data : running MakeTrackMonster.m in this method on the
    % training audio to return the name,pathces,features in each patch,...
    % types in each patch, types per audio
    
    [refnames_pertr,reftimestamps_pertr,refFeatures_pertr, refTypes_pertr, perFileTypes_pertr] =...
        prepRefData(trainSetDir,testSetDir,trainname(i,:),testname, examined, typesPresent, featurelist);

    refnames=vertcat(refnames,refnames_pertr);
    reftimestamps=vertcat(reftimestamps,reftimestamps_pertr);
    refFeatures=vertcat(refFeatures,refFeatures_pertr);
    refTypes=vertcat(refTypes,refTypes_pertr);
    perFileTypes=vertcat(perFileTypes,perFileTypes_pertr);
   
end

save(refmatfile,'refnames','examinedalltrain','typesPresentalltrain',...
    'reftimestamps', 'refFeatures', 'refTypes', 'perFileTypes','-v7.3');% save the reference data


% these 3 lines are for experimenting treating the dev set as test data
% testdataType = 'dev';
% rootdir = devsetDir
% [nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(examined, devsetDir);

testSetDir = strrep(testpath,'\','/');
% another set of test data: the eval set
testdataType = 'eval';
folders = getfolders(testSetDir);
evalDirCount = length(folders);
% first80=floor((80/100)*evalDirCount);% first 80 percent of audio directories in the language
% from81st=first80+1;% the 81st directory
% evaldataspec = [(from81st:evalDirCount)'  zeros(evalDirCount-first80,1)];% the eval/test set consists of remaining 20 audio directories in that language 
evaldataspec = [(1:evalDirCount)'  zeros(evalDirCount,1)];
%evaldataspec = [(17:evalDirCount)'  zeros(evalDirCount-16,1)];
%evaldataspec = [[2,6,9]'  zeros(evalDirCount,1)];
%evaldataspec = [[30]'  zeros(evalDirCount-first80,1)];

[nfiles, basenames, dirlist, filelist, ~] =  createFlatLists(evaldataspec, testSetDir);

rootdir = testSetDir;
neighbor=struct();% conatins data of neighbors as obtained after running knn
test=struct();% contains test patches and testfeatures per patch ...
              % after running MakeTrackMonster.m on test audio with the feature file
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
         %disp((rawEstimates.votePerTest(1:11)));         
         estimatespertestrowTypes=rawEstimates.votePerTest(1:11) * confusionMatrix;%estimates per patch of test audio
         estimatespertestrowBinary=rawEstimates.votePerTest(12:18);%estimates per patch of test audio
         estimatespertestrow=[estimatespertestrowTypes estimatespertestrowBinary];
         %disp(size(estimatespertestrow));
         normalizedEstimatespertestrow= normalizeTo01(estimatespertestrow);% normalizing estimates per test patch  
         neighbor(i).pertestprediction=normalizedEstimatespertestrow;% saving normalized estimates per test patch
                                                                     %in the neighbor struct      
         neighbor(i).namespatches=rawEstimates.namespatches;%saving names of neighboring audio/audios ...
                                                            %and corresponding patches given by knn in the neighbor sruct
         estimatesTypes = rawEstimates.stancePrediction(1:11) * confusionMatrix;% estimates for each type at the segment level...
                                                   %i.e. for the entire test audio
         estimatesBinary = rawEstimates.stancePrediction(12:18);
         
         estimates=[estimatesTypes estimatesBinary];
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
         neighbor(neigh)=[]; % deleting empty rows from structure, 'neighbor'....
                             % generated because of reading pitchCache
    end
end

for k = 1:length(neighbor) 
  save(neighbormat,'neighbor');% saving the neighbor structure in a .mat file
end 

testdim=length(test);
for testi=testdim:-1:1
    if(isempty(test(testi).testaudio))
         test(testi)=[];  % deleting empty rows from structure, 'test'...
                          % generated because of reading pitchCache
        
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


save(estimatesmat, 'i', 'typeList','timeList','resolutionList','urgencyList',...
    'basenames', 'normalizedEstimates');% saving the estimates in a .mat file
fclose('all');
fprintf('processed %d files\n', length(dirlist));

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
    knnCode(queryFeatures, querytimestamps,refFeatures, refTypes,reftimestamps,refnames,3);
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
function [typeList,timeList,resolutionList,urgencyList, confusionMat] = setGlobals(newOroldAnno)
     if(strcmp(newOroldAnno,'old')>0)
        
        typeList = cell(1,11);
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
        
        timeList = cell(1,2);
        timeList{1} = 'Current';
        timeList{2} = 'Not Current';

        resolutionList = cell(1,2);
        resolutionList{1} = 'Sufficient';
        resolutionList{2} = 'Not Sufficient';

        urgencyList = cell(1,2);
        urgencyList{1} = 'Urgent';
        urgencyList{2} = 'Not Urgent';
        
    elseif(strcmp(newOroldAnno,'new')>0)
        
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
        
        timeList = cell(1,2);
        timeList{1} = 'current';
        timeList{2} = 'not_current';

        resolutionList = cell(1,2);
        resolutionList{1} = 'sufficient';
        resolutionList{2} = 'insufficient';

        urgencyList = cell(1,2);
        urgencyList{1} = 'urgent';
        urgencyList{2} = 'not_urgent';
        
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
	 prepRefData(trainSetDir,testSetDir,trainname,testname, examined, annotations, featurelist)
     allfeats = [];
     alltypes = [];   % per row types
     allnames = [];
     alltimestamps =[];

     [nfiles, basenames, dirlist, filelist, explicit] = createFlatLists(examined, trainSetDir);
     perFileTypes = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, annotations);
     %disp('perfiletypes_booleanlabels');
     %disp(perFileTypes);
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
                typeVec = 0.04 * ones(1,18);            
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
    typesPresent = zeros(1,18);
    %disp(length(annotations));
    for i=1:size(annotations,1)
        %disp(i);
        
        if annotations(i,1) == dirnum && annotations(i,2) == filenum;
            
            %disp(dirnum);
            %disp(filenum);
            type=(annotations(i,3));
            time = (annotations(i,4));
            resolution = (annotations(i,5));
            urgent = (annotations(i,6));
            typesPresent(type) = true;
            typesPresent(time + 11) = true;
            typesPresent(resolution + 13) = true;
            typesPresent(urgent + 15) = true;
            if(typesPresent(12) && typesPresent(15) && typesPresent(16))
                typesPresent(18)=true;                
            end
            %  fprintf('looking for  non-zero annotations; found one for dir %d file %d type %d \n', ...
            %    dirnum, filenum, typePresent);
        end
    end
    %disp('booleanlabels');
    %disp(typesPresent);
end
%-----------------------------------------------------------------------------




