function avgEstimatesModel( pathToEstimateModel1,pathToEstimateModel2,pathToNewEstimates,weights,algo, auc1,auc2)
% assuming pathToEstimateModel1 is the path to the Model with better
% estimates as determined buy Auc values
% weights , boolean variable , default is false, if true, weighted average
% of the estimates are taken
%algo  either 'knn' or 'linearRegression'
%auc1 and auc2 are '0' for 'knn' 
% for linearRegression, auc1 >= auc2
    if (strcmp(algo,'knn'))
        if(weights==false)
            nfilesstruct=load(pathToEstimateModel1,'i'); % number of audios in the test set
            i=nfilesstruct.i; 

           basenamesstruct=load(pathToEstimateModel1,'basenames'); %names of audios in the test set
           basenames=basenamesstruct.basenames;

            %confidence scores for situation types
            estimatesStruct1=load(pathToEstimateModel1,'normalizedEstimates');
            normEstimates1=estimatesStruct1.normalizedEstimates;

            estimatesStruct2=load(pathToEstimateModel2,'normalizedEstimates');
            normEstimates2=estimatesStruct2.normalizedEstimates;

            for testAudio=1:i
               results(testAudio,:)= (normEstimates1(testAudio,:) + normEstimates2(testAudio,:))/2;
            end
            pathToNewEstimates=strcat(pathToNewEstimates,'avgEqualWeightsEstimates\');
            mkdir(pathToNewEstimates);
            % save the new estimates and create corresponding  json files
            save(strcat(pathToNewEstimates,'estimateSF'),'normalizedEstimates','basenames','i');
            jsonfilename=strcat('system_output_knnAvgEqualWeightsEstimate');
            jsonFileNameScores=strcat('likelihoodScores_knnAvgEqualWeightsEstimate');
            outputAsJsonV2commonSF(pathToNewEstimates,jsonfilename);
            outputAsJsonV2_1Scores(pathToNewEstimates,jsonFileNameScores); % json outputs with confidence scores

        end
    end
    if (strcmp(algo,'linearRegression'))
        if(weights==false)

            %confidence scores for situation types
            estimatesStruct1=load(pathToEstimateModel1,'results');
            normEstimates1=estimatesStruct1.results;

            estimatesStruct2=load(pathToEstimateModel2,'results');
            normEstimates2=estimatesStruct2.results;
            
             for testAudio=1:size(normEstimates1,1)
               results(testAudio,:)= (normEstimates1(testAudio,:) + normEstimates2(testAudio,:))/2;
            end
            % save the new estimates and create corresponding  json files 
            pathToNewEstimates=strcat(pathToNewEstimates,'avgEqualWeightsEstimates\');
            mkdir(pathToNewEstimates);
            save(strcat(pathToNewEstimates,'estimatesLreg'),'results');
            writeFieldLikelihoodsJson(results, 'IL9_SetE');  % for partners
            writeSfJson(results, 'IL9_SetE');   % for submission 
        
       elseif(weights==true)

            %confidence scores for situation types
            estimatesStruct1=load(pathToEstimateModel1,'results');
            normEstimates1=estimatesStruct1.results;

            estimatesStruct2=load(pathToEstimateModel2,'results');
            normEstimates2=estimatesStruct2.results;
            
            
            results= (((auc1/(auc1+auc2))*normEstimates1) + ...
                  ((auc2/(auc1+auc2))*normEstimates2))/2;
          
            % save the new estimates and create corresponding  json files 
            pathToNewEstimates=strcat(pathToNewEstimates,'avgTunedWeightsEstimates\');
            mkdir(pathToNewEstimates);
            save(strcat(pathToNewEstimates,'estimatesLreg'),'results');
            writeFieldLikelihoodsJson(results, 'IL10_SetE');  % for partners
            writeSfJson(results, 'IL10_SetE');   % for submission 
       end
    end
end
function writeSfJson(results, testLangDir)
  %% prepare to pick out which situation frames to output
  ndocs = size(results, 1);
  ntypes = 11;
  gravityOverlay = repmat(results(:,6), 1, ntypes);
  relevanceOverlay = repmat(results(:,5), 1, ntypes);
  typeEstimates = results(:, 7:17);
  hotness = gravityOverlay .* relevanceOverlay .* typeEstimates;
  sortedHotness = sort(reshape(hotness, 1, []));
  avgTypesMentioned = 1.4;
  avgFractionInDomain = 0.57;
  %% nothing depends on this being even-approximately accurate
  numberToOutput = min(1000, floor(ndocs * avgFractionInDomain * avgTypesMentioned * 1.5));

  threshold = sortedHotness(end - numberToOutput);
  
  %% build the list of SFs to output 
  filenames = aufilenames(['C:\ANINDITA\Lorelei_2018\Lorelei_2018\Audios\ForLinearReg\' testLangDir '\aufiles']);
  [~, typeStdNames] = sfNamings();
  answerObjects = cell(1, numberToOutput);   % allocate storage 
  acounter = 1;

  for doc = 1:size(results,1)
    for type = 1:ntypes
      if hotness(doc, type) < threshold
	continue
      end
      filename = filenames(doc);
      ansObj.DocumentID = filename{1}(1:end-3);
      ansObj.Type = typeStdNames(type);
      if(hotness(doc, type)>1)
          hotness(doc, type)=1;
      end
      if(hotness(doc, type)<0)
          hotness(doc, type)=0;
      end 
      ansObj.Confidence = hotness(doc, type);            
      ansObj.Place_KB_ID = '';
      ansObj.Justification_ID = 'dummyValue'; 
      ansObj.Status = 'current'; 
      ansObj.Resolution = 'insufficient';
      ansObj.Urgent = true;
      if type >= 9  % it's not a need frame, so we can't write these fields 
        ansObj = rmfield(ansObj, 'Resolution');
      end
      
      answerObjects{acounter} = ansObj;
      acounter = acounter + 1;  
    end
  end 
  
  savejson('', answerObjects, struct('FileName','submittable.json', ...
				     'ParseLogical', 1, 'FloatFormat', '%.3g'));
end



function writeFieldLikelihoodsJson(results, testLangDir)
  filenames = aufilenames(['C:\ANINDITA\Lorelei_2018\Lorelei_2018\Audios\ForLinearReg\' testLangDir '\aufiles']);
  [~, typeStdNames] = sfNamings();
  answerObjects = cell(1, size(results, 1));   % allocate storage 
  acounter = 1;

  for doc = 1:size(results, 1)    
    filename = filenames(doc);
    ansObj.DocumentID = filename{1}(1:end-3);
    ansObj.Current = results(doc, 1);
    ansObj.Insufficient = results(doc, 2);
    ansObj.Urgent = results(doc, 3);
    ansObj.Place_Mentioned = results(doc,4);
    ansObj.Relevant = results(doc, 5);
    ansObj.Grave = results(doc, 6);
    for type = 1:11
      ansObj.(typeStdNames(type)) = results(doc, 6+type);
    end
    
    answerObjects{acounter} = ansObj;
    acounter = acounter + 1;
  end
  savejson('', answerObjects, struct('FileName','fieldLikelihoods.json', ...
				     'FloatFormat', '%.3g'));
end



function filenames = aufilenames(audir)
  filespec = sprintf('%s/*au', audir);
  aufiles = dir(filespec);
  if (size(aufiles,1) == 0)
    error('no au files in the specified directory, "%s"\n', audir);
  end 
  filenames = cell(1, length(aufiles));   % allocate storage 
  for testAudio = 1:length(aufiles);
    struct = aufiles(testAudio);
    filenames{testAudio} = struct.name;
  end
end


