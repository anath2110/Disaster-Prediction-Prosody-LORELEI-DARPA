function [refmatfile,confusionMatrix]= createRefModel(refmatfile,outputDir,trainpath,trainname,featurefile,newOroldAnno,delSkip)
%name the output.mat files to be placed in the above directory 



[typeList,timeList,resolutionList,urgencyList, confusionMatrix] = setGlobals(newOroldAnno);

featurelist = getfeaturespec(featurefile);

examinedalltrain={};
typesPresentalltrain={};
refnames=[];
reftimestamps=[];
refFeatures=[];
perFileTypes=[];
refTypes=[];


for i=1:size(trainpath,1)
    trainSetDir = strrep(trainpath(i,:),'\','/');
   [examined, typesPresent] = getLabels(trainSetDir,newOroldAnno); 
          
    examinedalltrain=vertcat(examinedalltrain,{trainpath(i,:) examined});
    typesPresentalltrain=vertcat(typesPresentalltrain,{trainpath(i,:) typesPresent});
    
    % the reference data : running MakeTrackMonster.m in this method on the
    % training audio to return the name,pathces,features in each patch,...
    % types in each patch, types per audio
    
    [refnames_pertr,reftimestamps_pertr,refFeatures_pertr, refTypes_pertr, perFileTypes_pertr] =...
        prepRefData(trainSetDir,trainname(i,:),examined, typesPresent, featurelist);
    
       
    refnames=vertcat(refnames,refnames_pertr);
    reftimestamps=vertcat(reftimestamps,reftimestamps_pertr);
    refFeatures=vertcat(refFeatures,refFeatures_pertr);
    refTypes=vertcat(refTypes,refTypes_pertr);
    perFileTypes=vertcat(perFileTypes,perFileTypes_pertr);  
   
   
end

if(delSkip==true)
 %delete all rows with types/annotations as '0'(both Skipped and n/as) from each 'ref' variable
%     refnames(find(sum(refTypes,2)==0),:)=[];
%     reftimestamps(find(sum(refTypes,2)==0),:)=[];
%     refFeatures(find(sum(refTypes,2)==0),:)=[];
%     refTypes=refTypes(any(refTypes~=0, 2),:); 

 %delete all rows with types/annotations as '-1'(for Skipped) from each
 %'ref' variable, keep n/as as '0' annotations
  refnames(find(refTypes(:,19)==1),:)=[]; 
  reftimestamps(find(refTypes(:,19)==1),:)=[];  
  refFeatures(find(refTypes(:,19)==1),:)=[]; 
  refTypes(find(refTypes(:,19)==1),:)=[]; 
  
elseif(delSkip==false)
    
    %delete all rows with n/a('0') but replace Skipped(-1) as 0.04 
%     refnames(find(sum(refTypes,2)==0),:)=[];
%     reftimestamps(find(sum(refTypes,2)==0),:)=[];
%     refFeatures(find(sum(refTypes,2)==0),:)=[];
%     refTypes=refTypes(any(refTypes~=0, 2),:);

%replace Skipped(-1) as 0.04, keep n/as as '0' annotations 
    refTypes(find(refTypes(:,19)==1),:)=0.04;   
end

save(refmatfile,'refnames','examinedalltrain','typesPresentalltrain',...
    'reftimestamps', 'refFeatures', 'refTypes', 'perFileTypes','-v7.3');% save the reference data


end
%----------------------------------------------------------------------------
% returns paired lists of directories and files, for convenient iteration
function [filesProcessed, basenames, dirlist, filelist, explicit] = ...
	 createFlatLists(dirsAndFileCounts, rootDir)
 filesProcessed = 0;
%  disp(size(dirsAndFileCounts));
%  disp(rootDir);
 
 for thisDir = 1:size(dirsAndFileCounts,1)
     dirnum = dirsAndFileCounts(thisDir, 1);
     %disp(dirnum);
     directoryPath = sprintf('%s%03d/AUDIO/', rootDir, dirnum);
     %disp(directoryPath);
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
     %disp(filenumInDir);
     %disp(explicit);
 end
end 
%----------------------------------------------------------------------------

%-----------------------------------------------------------------------------
% massage the filename into a the format expected by makeTrackMonster
function trackspec = singleFileTrackspec(rootdir, dirnum, filenum,trainname)
  [dirname, filename, path] = assembleName(rootdir, dirnum, filenum,trainname);
  trackspec.directory = dirname; 
  trackspec.filename = filename;
  trackspec.path = path;
  trackspec.side = 'l';
end
%-----------------------------------------------------------------------------
function [dirname, filename, path] = assembleName(rootdir, dirnum, filenum,trainname)
  %fprintf('assemble name %s %d %d\n', rootdir, dirnum, filenum);

    dirname = sprintf('%s%03d/AUDIO/', rootdir, dirnum);
    filename = sprintf('%s_%03d_%03d.au',trainname,dirnum, filenum);

  path = [dirname filename];
end
%-----------------------------------------------------------------------------
function [typeList,timeList,resolutionList,urgencyList, confusionMat] = setGlobals(newOroldAnno)
     if(strcmp(newOroldAnno,'old')>0)
        
        typeList = cell(1,11);       
        
        typeList{1} = 'Civil Unrest or Wide-spread Crime';
        typeList{2} = 'Elections and Politics';
        typeList{3} = 'Evacuation';
        typeList{4} = 'Food Supply';
        typeList{5} = 'Urgent Rescue';
        typeList{6} = 'Utilities, Energy, or Sanitation';
        typeList{7} = 'Infrastructure';
        typeList{8} = 'Medical Assistance';
        typeList{9} = 'Shelter';
        typeList{10} = 'Terrorism or other Extreme Violence';
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
	 prepRefData(trainSetDir,trainname,examined, annotations, featurelist)
     allfeats = [];
     alltypes = [];   % per row types
     allnames = [];
     alltimestamps =[];

     [nfiles, basenames, dirlist, filelist, explicit] = createFlatLists(examined, trainSetDir);
     perFileTypes = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, annotations);
  
    j = 1;
     for i= 1:nfiles

        if (~explicit(i))% treats pitchCache as a non-explicit audio 
            continue;
        end    
        if(strcmp(basenames(i),'pitchCache')==0)
            trackspec = singleFileTrackspec(trainSetDir, dirlist(i), filelist(i),trainname);
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
                typeVec = 0.04 * ones(1,17);            
            end
            veridicalTypes(i,:) = typeVec;        
        else
            veridicalTypes(i,:) = -0.001;% insert negative spurious values if pitchCahe is encountered and treated as audio
        end
    end
    rows_to_remove = any(veridicalTypes==-0.001, 2);
    veridicalTypes(rows_to_remove,:) = []; % delete negative rows,corresponding to pitchCache
   

end
%------------------------------------------------------------------%

% returns a boolean vector
function typesPresent = setupTypeVec(dirnum, filenum, annotations)
   typesPresent = zeros(1,19);
   
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
            
            if(type==-1)
                    typesPresent(19) = true;
            else                  
                    typesPresent(type) = true;
                    typesPresent(time + 11) = true;
                    typesPresent(resolution + 13) = true;
                    typesPresent(urgent + 15) = true;
                    if(typesPresent(12) && typesPresent(15) && typesPresent(16))
                        typesPresent(18)=true;                
                    end
            end
           
           
            
            %  fprintf('looking for  non-zero annotations; found one for dir %d file %d type %d \n', ...
            %    dirnum, filenum, typePresent);
        end
    end
    %disp('booleanlabels');
    %disp(typesPresent);
end
%-----------------------------------------------------------------------------%

