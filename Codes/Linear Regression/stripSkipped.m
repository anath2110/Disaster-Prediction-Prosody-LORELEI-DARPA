% Strip audios that have 'Skipped' annotations from training set

% Path parameters point to the parent folder of all
% audio/annotation directories 001,002,...,XXX.
% Path parameters must include closing slash '\'

function stripSkipped(pathToDirs, pathToNewDirs)
  dirList = dir(pathToDirs);
  for d = 3:(length(dirList))
    made = false;
    auPath = [pathToDirs dirList(d).name '\AUDIO\'];
    anPath = [pathToDirs dirList(d).name '\ANNOTATION\'];
    anList = dir(anPath);
    for an = 3:length(anList)
      anNameParts = strsplit(anList(an).name, {'_', '.'}, 'CollapseDelimiters', true);
      fid = fopen([anPath anList(an).name], 'r');
      anStr = fscanf(fid,'%s');
      %if ~contains(anStr, 'Skipped') % only works in version>= 2016b
      if(isempty(strfind(anStr,'Skipped')))
        if ~made
          newDirPath = [pathToNewDirs anNameParts{3} '\'];
          newAuPath = [newDirPath 'AUDIO\'];
          newAnPath = [newDirPath 'ANNOTATION\'];
          mkdir(newDirPath);
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