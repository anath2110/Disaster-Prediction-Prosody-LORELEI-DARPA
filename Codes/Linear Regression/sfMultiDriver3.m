%% evaluate situation-frame predictive models' performance
%% on trainLangID languages, i.e., those  not in the training data
%% Nigel Ward, UTEP, June 2018
%% aiming to discover
%% 1. which prosody-based model is best
%% 2. how well we perform on all tasks, in order to tell our partners
%% both for the metadata-only predictors and the plus-prosody-summary-stats predictors
%%  a. a table of pranuc values, averaged across all languages
%%  b. for gravity, a table of ditto, for each language 
%% This is for 6 languages, 17 predictees, 3 models

%% TODO:
%% - Look at 80-20 function/example in sfMultiDriver, bug

%% sfMultiDriver3
function sfMultiDriver3()
    
  %{
  trainSets = containers.Map({1,2,3}, ...
    {containers.Map({1,2,3,4,5,6}, {'bengali', 'english', 'indonesian', 'tagalog', 'thai', 'zulu'})}, ...
    {containers.Map({1,2}, {'IL9-Set0-LR', 'IL9-Set1-LR'})}, ...
    {containers.Map({1,2}, {'IL10-Set0-LR', 'IL10-Set1-LR'})});

  testSets = containers.Map({1,2}, ...
    {containers.Map({1,2}, {'IL9-Set0-LR', 'IL9-Set1-LR'})}, ...
    {containers.Map({1,2}, {'IL10-Set0-LR', 'IL10-Set1-LR'})});
  %}
  
  %langNames = containers.Map({1,2}, {'IL9-Set0-LR', 'IL9-Set1-LR'});
  
  %
  lang1 = containers.Map({1}, ...
    {'IL10Prioritize60RandomGreaterThan1'});
  
%   lang2 = containers.Map({1,2}, ...
%     {'IL10-Set0-LR', 'IL10-Set1-LR'});
  
  %trainSets = {lang1, lang2};
   
  trainSets = {lang1};
  %
  
  for lang = 1:length(trainSets) % index of language
    setNames = trainSets{lang} % map with set names
    dirNum = 0;
    
    for set = 1:length(setNames) % index of set with dir left out
      otherSets = cell2mat(keys(setNames));
      otherSets(set) = []
      dirList = buildDirList(setNames(set))
      % Should be reversed, and renamed %
      [~, ~, trainX3_2, trainY_2] = buildSets(set, setNames); % only set
      [~, ~, trainX3_1, trainY_1] = buildSets(otherSets, setNames); % everything but set
      
      for diri = 1:length(dirList) % index of dir
        [trainX4, testX4, trainY4, testY4] = buildLeave1OSet(trainX3_2, trainY_2, dirList(diri));
        size(trainX3_1)
        size(trainY_1)
        trainX3 = [trainX3_1; trainX4];
        trainY = [trainY_1; trainY4];
        fprintf('trainX3 length = %d = %d trainY length ?\n', length(trainX3(:,1)), length(trainY(:,1)))
        nPredictees = size(trainY,2);
        dirNum = dirNum + 1; % seperate counter for pranucs auc
        
        %% ERROR inside this loop: Index exceeds matrix dimensions.
        for predictee = 1:nPredictees
          model3 = fitlm(trainX3, trainY(:,predictee));
          preds3 = predict(model3, testX4);
          [~, pranuc, ~] = niceStats(preds3, testY4(:,predictee), ...
             [setNames(set) ' ' sfFieldName(predictee)]);
          pranucs3(predictee, diri) = pranuc;
        end
      end % diri
      
      %% Save each set's perf, compute avgs
      save(['pranucs3-' setNames(set)], 'pranucs3');
      
      fprintf('AVERAGES FOR %s\n', setNames(set));
      avgperfs = zeros(nPredictees);
      for p = 1:nPredictees
        % Custom averaging, ignoring NaN
        sum = 0;
        count = 0;
        for d = 1:length(dirList)

          if ~isnan(pranucs3(p,d))
            sum = sum + pranucs3(p,d);
            count = count + 1;
          end
          
        end
        
        avgperfs(p) = sum / count;
        typeAvg = meanNoNaN(avgperfs(7:end));
        gravityAvg = avgperfs(6);
        overallAvg = (typeAvg + gravityAvg) / 2;
        
        perf(lang, set, 1) = typeAvg;
        perf(lang, set, 2) = gravityAvg;
        perf(lang, set, 3) = overallAvg;
        % Could be a bug with sfFieldName ordering..?
        fprintf('AVERAGE PERF FOR %s: %f\n', sfFieldName(p), avgperfs(p))
        
      end % averages
      
    end % set
    
    %% Compute and save language perf
    typeAvgForLang = mean(perf(lang,:,1));
    gravityAvgForLang = mean(perf(lang,:,2));
    overallAvgForLang = mean(perf(lang,:,3));
    
    save(['averagesForLang-' num2str(lang)], 'typeAvgForLang', 'gravityAvgForLang', 'overallAvgForLang');
  end % lang
  
end % end sfMultiDriver3

%% Splits the train set around a directory
function [trainX4, testX4, trainY4, testY4] =  buildLeave1OSet(trainX3, trainY, dirNum)
  fprintf('buildLeave10Set on dirNum %d\n', dirNum)
  
  % Error was here, dir number not available for match in trainY data.
  dir = find(trainX3(:,1) == dirNum);
  notDir = find(trainX3(:,1) ~= dirNum);
  
  trainX4 = trainX3(notDir,:);
  testX4 = trainX3(dir,:);
  
  trainY4 = trainY(notDir,:);
  testY4 = trainY(dir,:);
  
  fprintf('input "trainX3" length = %d, "trainY" length = %d\n', length(trainX3(:,1)), length(trainY(:,1)))
  fprintf('trainX4 length: %d testX4 length: %d\n', length(trainX4(:,1)), length(testX4(:,1)))
  fprintf('trainY4 length: %d testY4 length: %d\n', length(trainY4(:,1)), length(testY4(:,1)))
  size(trainX4)
  size(testX4)
  size(trainY4)
  size(testY4)
end

%% Identifies all directories present in folder
function swissDirList = buildDirList(langName)
  fprintf('BuildDirList with %s\n', langName)
  baseDir = 'F:\ANINDITA\LORELEI\Lorelei_2018\Lorelei_2018\EvaluationJuly2018\Audios\ReRuns\IL10\';
  audir = [baseDir langName '\aufiles\']
  auList = dir([audir '*.au'])
  if length(auList) == 0
    error('No au files in %s', audir)
  end
  auNameParts = strsplit(auList(1).name, '_');
  swissDirList = [str2num(auNameParts{3})];
  for au = 1:length(auList)
    auNameParts = strsplit(auList(au).name, '_');
    dirNum = str2num(auNameParts{3});
    lastDirNum = swissDirList(end);
    %fprintf('swissDirList: %d = %d ?', lastDirNum, dirNum)
    if (lastDirNum ~= dirNum)
      swissDirList = [swissDirList dirNum];
    end
  end
end

%% buildSets
function[setX1, setX2, setX3, setY] =  buildSets(trainingLangIDs, langNames)
  naudios = 3;     % likely min number of audios
  setX1 = zeros(naudios, 3);    % 3 predictors
  setX2 = zeros(naudios, 16);   % 3+13 predictors
  setX3 = zeros(naudios, 29);   % 3+13*2 predictors
  setY = zeros(naudios, 17);    % 17 predictees
  instancesSoFar = 0;
  for i = 1:length(trainingLangIDs)
    lang = trainingLangIDs(i);
    fprintf('buildSets for %s\n', langNames(lang));
    audir = ['F:\ANINDITA\LORELEI\Lorelei_2018\Lorelei_2018\EvaluationJuly2018\Audios\ReRuns\IL10\' langNames(lang) '\aufiles'];
    andir = ['F:\ANINDITA\LORELEI\Lorelei_2018\Lorelei_2018\EvaluationJuly2018\Audios\ReRuns\IL10\' langNames(lang) '\anfiles'];
    thisLangX1 = getAudioMetadata(audir);
    
    % thisLangX2 = getProsodicFeatureAverages(audir);
    fssfile = 'F:\ANINDITA\LORELEI\Lorelei_2018\Lorelei_2018\EvaluationJuly2018\Requisites''2018\midlevel-master\flowtest\oneOfEachTuned.fss'; 
    pfAvgsStds = findPFaverages(audir, fssfile);
    thisLangX2 = [thisLangX1 pfAvgsStds(:,1:13)];

    thisLangX3 = [thisLangX1 pfAvgsStds];
    thisLangY = readSFannotations(andir);
    instancesForLang = size(thisLangX1,1);
    setX1(instancesSoFar+1:instancesSoFar+instancesForLang,:) = thisLangX1;
    setX2(instancesSoFar+1:instancesSoFar+instancesForLang,:) = thisLangX2;
    setX3(instancesSoFar+1:instancesSoFar+instancesForLang,:) = thisLangX3;
    setY(instancesSoFar+1:instancesSoFar+instancesForLang,:) = thisLangY;
    instancesSoFar = instancesSoFar+instancesForLang;
  end
  %fprintf('\n');
end

%% cache for future reuse, to prevent heavy, repetitive computation and file i/o
function pfa = findPFaverages(audir,fssfile)
  persistent PFAcache;
  persistent nEntries;

  if length(PFAcache) == 0  % first call so initialize the cache
    nEntries = 0;
    PFAcache = struct('dir', {}, 'values', {});
  end

  for i = 1:nEntries
    entry = PFAcache(i);
    if strcmp(audir, entry.dir)
      pfa = entry.values;
      return
    end
  end

  %pfa = getProsodicFeatureAverages(audir);
  pfa = getProsodicFeatureAvgStds(audir,fssfile);
  nEntries = nEntries + 1;
  PFAcache(nEntries).values = pfa;
  PFAcache(nEntries).dir = audir;
end

function [trainX4, testX4, trainY4, testY4] = eightyTwentySameLang(trainX3, trainY)
  nstories = size(trainX3, 1);
  splitpoint = floor(nstories * 0.80);
  trainX4 = trainX3(1:splitpoint,:);
  testX4  = trainX3(splitpoint:end,:);
  trainY4 = trainY(1:splitpoint,:);
  testY4 = trainY(splitpoint:end, :);
end

function mean = meanNoNaN(set)
  sum = 0;
  count = 0;
  for i = 1:length(set)
    if ~isnan(set(i))
      sum = sum + set(i);
      count = count + 1;
    end
    mean = sum / count;
  end
end