% function outputAsJsonV2commonSF(pathToDirWithEstimates,outfilename) %
%..........................................................................%
% prints the estimates in Lorelei approved json schema
%..........................................................................%
% Input:
%   i)pathToDirWithEstimates - path to the directory contating the
%   estimates.mat files
%   ii)outfilename - name of the json output file
%..........................................................................%

function outputAsJsonV2commonSF(pathToDirWithEstimates,outfilename)

matfilepath=strcat(pathToDirWithEstimates);
 
matfileEstimates=strcat(matfilepath,'estimateSF.mat');
%matfileNNEstimates=strcat(matfilepath,'NNunivTrain_IL9SetE.mat');
load(matfileEstimates);
%load(matfileNNEstimates);

basenamesstruct=load(matfileEstimates,'basenames'); %names of audios in the test set
basenames=basenamesstruct.basenames;

nfilesstruct=load(matfileEstimates,'i'); % number of audios in the test set
nfiles=nfilesstruct.i;

outfilename=strcat(outfilename,'.json');
outfiledir=strcat(matfilepath,'\',outfilename);


% typelist
typeList=cell(1,11);
% typeList{1} = 'crimeviolence';
% typeList{2} = 'regimechange';
% typeList{3} = 'evac';
% typeList{4} = 'food';
% typeList{5} = 'infra';
% typeList{6} = 'med';
% typeList{7} = 'shelter';
% typeList{8} = 'terrorism';
% typeList{9} = 'search';
% typeList{10} = 'utils';
% typeList{11} = 'water';

typeList{1} = 'crimeviolence';
typeList{2} = 'regimechange';
typeList{3} = 'evac';
typeList{4} = 'food';
typeList{5} = 'search';
typeList{6} = 'utils';
typeList{7} = 'infra';
typeList{8} = 'med';
typeList{9} = 'shelter';
typeList{10} = 'terrorism';
typeList{11} = 'water';

%relieflist
reliefList=cell(1,2);
reliefList{1} = 'sufficient';
reliefList{2} = 'insufficient';

%urgencylist
urgencyList=cell(1,2);
urgencyList{1}=true;
urgencyList{2}=false;



%confidence scores for situation types
estimatesStruct=load(matfileEstimates,'normalizedEstimates');
%estimatesStruct=load(matfileNNEstimates,'normalizedEstimates');
normEstimates=estimatesStruct.normalizedEstimates;

writeResultsAsJson(nfiles, typeList,reliefList,urgencyList,...
    basenames,normEstimates, outfiledir);
 end

function writeResultsAsJson(nfiles, typeList,reliefList,urgencyList,...
    basenames,normEstimates, outfiledir)

  ntypes = length(typeList);
  answerObjects = cell(1, nfiles * ntypes);  % allocate storage
  acounter = 1;
  %disp(nfiles);  
  
  for f = 1:nfiles  
     % most likely first
    [~, indicesLargestToSmallest] = sort(normEstimates(f,(1:11)),'descend'); %sort the SFs in descending order ..
                                                                     % of type confidence scores
    % for the binary estimates, we choose the one with maximum confidence
    % score as the corresponding attribute's value 
    [~, indicesMaxStatus] = max(normEstimates(f,12:13));  
    [~, indicesMaxRelief] = max(normEstimates(f,14:15));  
    [~, indicesMaxUrgency] = max(normEstimates(f,16:17));
    
    for ix = 1:ntypes
      t = indicesLargestToSmallest(ix);
      s = indicesMaxStatus(1);
      r = indicesMaxRelief(1);     
      u = indicesMaxUrgency(1);
      %disp(s);
      %disp(r);
      %disp(u);     
      
      basename = basenames(f);
      ansObj.DocumentID = basename{1};
      ansObj.Type = typeList{t};
      ansObj.Confidence = normEstimates(f,t);
      %if(mod(f,2)==0)
        ansObj.Place_KB_ID = '';
      %else
        %ansObj.Place_KB_ID = 'Sichuan province';
      %end
      
      ansObj.Justification_ID = basename{1};
      %%%issue frame%%%
      % has types : 'regimechange', 'crimeviolence','terrorism'
      if(strcmp(ansObj.Type,'regimechange')>0 ....
          || strcmp(ansObj.Type,'crimeviolence')>0 || strcmp(ansObj.Type,'terrorism')>0)
     
          %disp(ansObj.Type);
       % has status as current and not_current
          if(s==1)
             ansObj.Status = 'current'; 
          elseif(s==2)
           ansObj.Status = 'not_current';
           %disp(ansObj.Status);
          end
          ansObj.Urgent= urgencyList{u};
       % has no Resolution  fields
          if(isfield(ansObj,'Resolution')>0)
            ansObj = rmfield(ansObj,'Resolution');
          end
%           if(isfield(ansObj,'Urgent')>0)
%             ansObj = rmfield(ansObj,'Urgent');
%           end
          %disp(ansObj);
          answerObjects{acounter} = ansObj;   
     
      else
          %disp(ansObj.Type);
          %%%%need frame%%%
          % has rest of the situation types
          % has status as current, future and past
          if(s==1)
             ansObj.Status = 'current'; 
          elseif(s==2)
           ansObj.Status = 'past';
           %disp(ansObj.Status);
          end   
          %has the Resolution and Urgent fields
          ansObj.Resolution = reliefList{r};     
          ansObj.Urgent= urgencyList{u};
          answerObjects{acounter} = ansObj;   
      end      	    
          
      acounter = acounter + 1;
    end
  end
  
  fprintf('saving %d answer objects\n', length(answerObjects));

  savejson('',answerObjects,'FileName',outfiledir,'ParseLogical',1);% 'ParseLogical'..
                                                                 %  is for outputting 
                                                                 %  boolean true or false                                                             %  or'flase'
                                                                 %  in json schema                                                                 %  scema
end 


%-----------------------------------------------------------------------------
