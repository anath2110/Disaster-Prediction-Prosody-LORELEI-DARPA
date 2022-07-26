function estimateSFMto1Gravity(outputDir,featurefile,refmatfile,testpath,testname,confusionMatrix)

refFeaturesStruct=load(refmatfile,'refFeatures');
refnamesStruct=load(refmatfile,'refnames');
reftimestampsStruct=load(refmatfile,'reftimestamps');
refTypesStruct=load(refmatfile,'refTypes');

refFeatures=refFeaturesStruct.refFeatures;
refnames=refnamesStruct.refnames;
reftimestamps=reftimestampsStruct.reftimestamps;
refTypes=refTypesStruct.refTypes;


estimatesmat=strcat(outputDir,'estimateSF');
neighbormat=strcat(outputDir,'neighborpertestaudioSF');
testmatfile=strcat(outputDir,'testdataSF');

featurelist = getfeaturespec(featurefile);

testSetDir = strrep(testpath,'\','/');

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
        
         trackspec = singleFileTrackspec(rootdir, dirlist(i), filelist(i),testname);
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


save(estimatesmat, 'i','basenames', 'normalizedEstimates');% saving the estimates in a .mat file
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
function trackspec = singleFileTrackspec(rootdir, dirnum, filenum,testname)
  [dirname, filename, path] = assembleName(rootdir, dirnum, filenum,testname);
  trackspec.directory = dirname; 
  trackspec.filename = filename;
  trackspec.path = path;
  trackspec.side = 'l';
end
%-----------------------------------------------------------------------------
function [dirname, filename, path] = assembleName(rootdir, dirnum, filenum,testname)
  %fprintf('assemble name %s %d %d\n', rootdir, dirnum, filenum);
  
    dirname = sprintf('%s%03d/AUDIO/', rootdir, dirnum);
    filename = sprintf('%s_%03d_%03d.au',testname,dirnum, filenum);
  
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






