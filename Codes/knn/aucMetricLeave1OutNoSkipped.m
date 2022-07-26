function aucMetricLeave1OutNoSkipped()
% testpath = 'C:\ANINDITA\Lorelei_2018\Lorelei_2018\EvaluationJuly''18\Langauge packs\TrainIL9\IL9_Set1\IL9_Set1\';
% [examined,labels]= getLabels(testpath,'old');
% 
% 
% % for i=1:94
% %     i
% %     rows=find(labels(:,1)==i)
% % end
% labelsOutofdomain=find(labels(:,3)==0);
% %disp(labelsOutofdomain);
% labelsSkipped=find(labels(:,3)==-1);
% %disp(size(labelsSkipped));
% labels(any(labels==0,2),:)=[];
% %labels(any(labels==-1,2),:)=[];
% %disp(size(labels));
% 
% [nfiles, basenames, dirlist, filelist, explicit] = createFlatLists(examined, testpath);
% perFileLabels = labeledTypes(nfiles,basenames, dirlist, filelist, explicit, labels);
% %disp(size(perFileLabels));
% nonSkippedLabels=perFileLabels(find(perFileLabels(:,19)==0),:);
% 
% estimatesStruct = load('C:\ANINDITA\Lorelei_2018\Lorelei_2018\Results\reRuns\Leave1out_IL9_Set1\estimateSF.mat');
% %disp(estimatesStruct);
% normEstimates=[];
% for i=1:length(estimatesStruct.esNormesAppend)
%     normEstimates=vertcat(normEstimates,estimatesStruct.esNormesAppend(i).normalizedEstimates);    
% end
% 
% basenamesAppended=[];
% for i=1:length(estimatesStruct.esBasenamesAppend)
%    
%     for j=1:length(estimatesStruct.esBasenamesAppend(i).basenames)
%      
%        basenamesAppended=vertcat(basenamesAppended,estimatesStruct.esBasenamesAppend(i).basenames{1,j});
%     end
% end
% %pred = getfield(pred,normEstimates);
% pred=normEstimates(find(perFileLabels(:,19)==0),:);
% save('Leave1OutLangSpecIL9Set1', 'labels','perFileLabels','nonSkippedLabels','pred');
%disp(size(pred));
%disp(pred);
loadmatfiles('Leave1OutLangSpecIL9Set0.mat','Leave1OutLangSpecIL9Set1.mat');
end
function loadmatfiles(matfile1,matfile2)

matfile1=load(matfile1);
matfile2=load(matfile2);
pred=vertcat(matfile1.pred,matfile2.pred);
%disp(size(pred));
predType=pred(:,1:11);
predTime=pred(:,12:13);
predResolution=pred(:,14:15);
predUrgency=pred(:,16:17);

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


nonSkippedLabels=vertcat(matfile1.nonSkippedLabels,matfile2.nonSkippedLabels);
%disp(size(nonSkippedLabels));

labelsTime = nonSkippedLabels(:,12:13);
labelsResolution = nonSkippedLabels(:,14:15);
labelsUrgency = nonSkippedLabels(:,16:17);


Atime = auc(predTime(:,1), labelsTime(:,1));
Aresolution = auc(predResolution(:,2), labelsResolution(:,2));% 1 for sufficient and 2 for insufficinet
Aurgency = auc(predUrgency(:,1), labelsUrgency(:,1));

Acrimeviolence=auc(predType(:,1), nonSkippedLabels(:,1));
Aregimechange=auc(predType(:,2), nonSkippedLabels(:,2));
Aevac=auc(predType(:,3), nonSkippedLabels(:,3));
Afood=auc(predType(:,4), nonSkippedLabels(:,4));
Asearch=auc(predType(:,5), nonSkippedLabels(:,5));
Autils=auc(predType(:,6), nonSkippedLabels(:,6));
Ainfra=auc(predType(:,7), nonSkippedLabels(:,7));
Amed=auc(predType(:,8), nonSkippedLabels(:,8));
Ashelter=auc(predType(:,9), nonSkippedLabels(:,9));
Aterrorism=auc(predType(:,10), nonSkippedLabels(:,10));
Awater=auc(predType(:,11), nonSkippedLabels(:,11));

AUC=[Atime Aresolution Aurgency Acrimeviolence Aregimechange Aevac Afood...
    Asearch Autils Ainfra Amed Ashelter Aterrorism Awater];
save('AUCLangSpecificIL9','AUC');

end


%-----------------------------------------------------------------------------
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
%-----------------------------------------------------------------------------
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
            
            
            %disp(type);
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
function A = auc(pred, ground_truth)
% Computes the area under the ROC curve
% pred is in the [0,1] range, ground truth is either 0 or 1
% Programmed by Olac Fuentes
% Last modified December 2, 2016
pos = sum(ground_truth);
%disp(pos);
neg = length(ground_truth) - pos;
%disp(neg);
[sorted_pred, ind] = sort(pred);
%disp(ind);
sorted_gt = ground_truth(ind);
c = cumsum(sorted_gt);
c = c(end) - c;
A = sum(c(sorted_gt==0))/pos/neg;
end