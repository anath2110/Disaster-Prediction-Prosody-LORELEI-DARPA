% function outputAsJsonV2_1Scores(pathToDirWithEstimates,outfilename) %
%..........................................................................%
% prints the likelihoods(confidence scores) of the estimates 
%..........................................................................%
% Input:
%   i)pathToDirWithEstimates - path to the directory contating the
%   estimates.mat files
%   ii)outfilename - name of the json output file
%..........................................................................%

function outputAsJsonV2_1Scores(pathToDirWithEstimates,outfilename)

matfilepath=strcat(pathToDirWithEstimates);

matfileEstimates=strcat(matfilepath,'estimateSF.mat');
load(matfileEstimates);

nfilesstruct=load(matfileEstimates,'i'); % number of audios in the test set
nfiles=nfilesstruct.i;

outfilename=strcat(outfilename,'.json');
outfiledir=strcat(matfilepath,'\',outfilename);


basenamesstruct=load(matfileEstimates,'basenames'); %names of audios in the test set
basenames=basenamesstruct.basenames;

% typelist
typeList=cell(1,11);
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


%confidence scores for situation types
estimatesStruct=load(matfileEstimates,'normalizedEstimates');
normEstimates=estimatesStruct.normalizedEstimates;

writeResultsAsJson(nfiles, typeList,basenames,normEstimates, outfiledir);
 end

function writeResultsAsJson(nfiles, typeList,basenames,...
    normEstimates, outfiledir)

  answerObjects = cell(1, nfiles);  % allocate storage
  acounter = 1;
  %disp(nfiles);  
  
  for f = 1:nfiles  
     
      
      ansObj.DocumentID = basenames{f};
      ansObj.Current = normEstimates(f, 12);
      ansObj.Insufficient = normEstimates(f, 15);
      ansObj.Urgent = normEstimates(f, 16);
      ansObj.Place_Mentioned = 0;
      ansObj.Relevant = 0;
      ansObj.Grave = normEstimates(f, 18);
      for type = 1:11
          ansObj.(typeList{type}) = normEstimates(f,type);
      end    
          
     
      answerObjects{acounter} = ansObj;     
      acounter = acounter + 1;
    
  end
  
  fprintf('saving %d answer objects\n', length(answerObjects));

  savejson('',answerObjects,'FileName',outfiledir,'ParseLogical',1,'FloatFormat', '%.3g');% 'ParseLogical'..
                                                                 %  is for outputting 
                                                                 %  boolean true or false                                                             %  or'flase'
                                                                 %  in json schema                                                                 %  scema
end 


%-----------------------------------------------------------------------------
