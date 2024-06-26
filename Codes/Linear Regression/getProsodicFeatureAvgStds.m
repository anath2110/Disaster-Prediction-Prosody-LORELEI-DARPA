%% Nigel Ward, April 2018 

function props = getProsodicFeatureAvgStds(audir, fssfile)
  featurespec = getfeaturespec(fssfile);
  [means, stds] = getFileLevelProsody(audir, featurespec);
  props = [means stds];  
end


%% modified from getAudioMetadata
function [means, stds] = getFileLevelProsody(audir, featurespec)
  filespec = sprintf('%s/*au', audir);
  aufiles = dir(filespec);
  if (size(aufiles,1) == 0)
    error('no au files in the specified directory, "%s"\n', audir);
  end

  nproperties = length(featurespec);
  nfiles = length(aufiles);
  means = zeros(nfiles, nproperties);
  stds = zeros(nfiles, nproperties);
  for filei = 1:nfiles   
    file = aufiles(filei);
    trackspec = makeTrackspec('l', file.name, [audir '/']);
    [~, monster] =  makeTrackMonster(trackspec, featurespec);
    means(filei, :) = mean(monster);
    stds(filei, :) = std(monster);
  end
end




  
