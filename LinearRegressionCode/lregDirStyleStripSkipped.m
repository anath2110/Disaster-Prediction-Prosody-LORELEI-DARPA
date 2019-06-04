% Strip audios that have 'Skipped' annotations from training set

%Linear Regression style director

function lregDirStyleStripSkipped(pathToDirs, pathToNewDirs)
  dirList = dir(pathToDirs);
  for d = 3:(length(dirList))
    made = false;
    auPath = [pathToDirs '\aufiles\'];
    anPath = [pathToDirs '\anfiles\'];
    anList = dir(anPath);
    for an = 3:length(anList)
      anNameParts = strsplit(anList(an).name, {'_', '.'}, 'CollapseDelimiters', true);
      fid = fopen([anPath anList(an).name], 'r');
      anStr = fscanf(fid,'%s');
      %if ~contains(anStr, 'Skipped') % only works in version>= 2016b
      if(isempty(strfind(anStr,'Skipped')))
        if ~made
         
          newAuPath = [pathToNewDirs '\aufiles\'];
          newAnPath = [pathToNewDirs '\anfiles\'];
         
          mkdir(newAuPath);
          mkdir(newAnPath);
          made = true;
        end
        copyfile([auPath strrep(anList(an).name, 'txt', 'au')], newAuPath);
        copyfile([anPath anList(an).name], newAnPath);
      end
      fclose(fid);
    end
  end
end