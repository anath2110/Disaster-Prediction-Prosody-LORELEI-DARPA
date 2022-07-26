% randomly pick files from a directory

%Linear Regression style directory structure

function randomPickFiles(pathToDirs, pathToNewDirs) 

    auPath = [pathToDirs '\aufiles\'];
    anPath = [pathToDirs '\anfiles\'];
    anList = dir(fullfile(anPath, '*.txt')); 
    %disp(length(anList))
    
    index = randperm(numel(anList(3:end)),60);% pick k(60) indices randomly from n integers(length of anList)
    %count=0;
    for an = index
      %count=count + 1;   

      newAuPath = [pathToNewDirs '\aufiles\'];
      newAnPath = [pathToNewDirs '\anfiles\'];

      mkdir(newAuPath);
      mkdir(newAnPath);


      copyfile([auPath strrep(anList(an).name, 'txt', 'au')], newAuPath);
      copyfile([anPath anList(an).name], newAnPath);

    end
    %disp(count)
  end
