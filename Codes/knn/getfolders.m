function folders = getfolders(path)
%get all the directories in the given path except..
%current directory '.' and %parent directory '..'
folders = dir(path);
for k = length(folders):-1:1
    % remove those which are not folders
    if ~folders(k).isdir
        folders(k) = [ ];
        continue
    end
    % remove folders starting with '.'
    fname = folders(k).name;
    if fname(1) == '.'
        folders(k) = [ ];
    end
end
end



