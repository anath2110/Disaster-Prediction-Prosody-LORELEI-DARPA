%-----------------------------------------------------------------------------
% examined is the duplet, types present is the triplet,auto generated 
% manually in previous code
function [examined,typespresent]= getLabelsLeaveOneOut(trainSetDir,newOroldAnno,train)
   %disp(trainSetDir);
   folders=getfolders(trainSetDir);
   %noofdir=length(folders);% all the audio directories in the language set used for training
   %noofdir=9; 
   %noofdir=floor((80/100)*length(folders));%first 80 percent of the audio directories in the language set used for training 
   noofdir=find(train==1);
   %disp('noofdir');
   %disp(noofdir');
   examined=[];
    typespresent=[];
    for i=noofdir'
        %audio directory path
        audiodir = sprintf('%s%s/AUDIO/', trainSetDir, folders(i).name);% 'path to traindir/001/AUDIO/'   
        %disp(audiodir);
        %audio files in each directory
        audiopath=strcat(audiodir,'*.au');
        audiofiles=dir(audiopath);
        lastaudio=audiofiles(length(audiofiles)).name; %last audio in the directory
        lastaudiolast3=lastaudio(end-5:end-3); %number of the audio %001
        
        %creating examined
        examined=vertcat(examined,[str2num(folders(i).name) str2num(lastaudiolast3)]);%duplet%the directory number, the number of the last audio in it

        % annotations directory
        annodir = sprintf('%s%s/ANNOTATION/', trainSetDir, folders(i).name);% 'path to traindir/001/ANNOTATION/'

        % annotation files in each directory
        annopath=strcat(annodir,'*.txt');
        annofiles=dir(annopath);

        annoname=[];
        annonamelast3=[];
        for k=1:length(annofiles)        
                annoname=vertcat(annoname,strcat(annodir ,annofiles(k).name));
                annonamelast3=vertcat(annonamelast3,annofiles(k).name(end-6:end-4));                   
        end
        %disp('before parsing');
        % parsing annotation files and creating typespresent    
        for l=1:size(annoname,1)
            %fprintf('%d_%d,%s\n',i,l,annoname(l,:));
            parsedtypeType=getAnnotationField(annoname(l,:),1,newOroldAnno);
            %disp(parsedtypeType);
            parsedtypeTime=getAnnotationField(annoname(l,:),2,newOroldAnno);
            %disp(parsedtypeTime);
            parsedtypeResolution=getAnnotationField(annoname(l,:),3,newOroldAnno);
            %disp(parsedtypeResolution);
            parsedtypeUrgency=getAnnotationField(annoname(l,:),5,newOroldAnno);
            %disp(parsedtypeUrgency);
            for p=1:size(parsedtypeType,1)
                %disp(p);
                %typespresent: directory number,annotation file
                %number,type,status, resolution, urgency values according
                %to the given annotations
               
                    typespresent=vertcat(typespresent,[str2num(folders(i).name)...
                    str2num(annonamelast3(l,:)) parsedtypeType(p,1) parsedtypeTime...
                    parsedtypeResolution parsedtypeUrgency ]);  
                
                 
            end
           
        end
    end 
    typespresent(any(typespresent==0,2),:)=[];
    typespresent=unique(typespresent,'rows');
    %disp('annotations');
    %disp(typespresent);
end
%-----------------------------------------------------------------------------
function annotation=getAnnotationField(filename, numberOfLine,newOroldAnno)
    fprintf('%s\n',filename);
    %disp('numberOfLine');
    %disp(numberOfLine);
    fileID = fopen(filename);
    alllines= textscan(fileID,'%s','delimiter','\n');%read all the lines in annotation file
    status=fclose(fileID);
    %disp(status);
    selectedLine=alllines{1}{numberOfLine};
    splitselectedLine= strsplit(selectedLine,{':',','});%e.g. %'Type' 'Typename1' 'TypeName2'%separate the types delimited by commas
    splitselectedLine=strtrim(splitselectedLine);%without the whitespaces    
    %disp(splitselectedLine);
    annotation=[];
    if(strcmp(newOroldAnno,'old')>0)        
        %Select attributes depending on number of line
        if(numberOfLine == 1)
            %create a typelist of 13 instead of 11 types, reason explained below
            typeList = cell(1,13);
            typeList{1} = 'Civil Unrest or Wide-spread Crime';
            typeList{2} = 'Elections and Politics';
            typeList{3} = 'Evacuation';
            typeList{4} = 'Food Supply';
            typeList{5} = 'Urgent Rescue';
            typeList{6} = 'Utilities';
            typeList{7} = 'Energy';
            typeList{8} = 'or Sanitation';
            typeList{9} = 'Infrastructure';
            typeList{10} = 'Medical Assistance';
            typeList{11} = 'Shelter';
            typeList{12} = 'Terrorism or other Extreme Violence';       
            typeList{13} = 'Water Supply';

           
            for i=2:size(splitselectedLine,2)% name of the types start from the....
                                          %second word in first line of annotation file
                for j=1:size(typeList,2)
                    %disp(splitfirstline{i});

                     if(strcmp(splitselectedLine{i},typeList{j})>0)
                        %for old annotations of situation types                            
                            if(j==6 || j==7 || j==8)
                                j=6;%the 3 extra type numbers are merged to 1
                            elseif(j==9)
                                j=7;
                            elseif(j==10) 
                                j=8;
                            elseif(j==11)
                                j=9;
                            elseif(j==12)
                                j=10;
                            elseif(j==13)
                                j=11;%'Water Supply' which was treated as type #13 in line 613 goes back to being type#11
                            else
                                j=j;%the rest type numbers remain as it is
                            end  
                    
                             if(length(annotation)==0)
                                annotation= j;
                             else
                                annotation=vertcat(annotation,j);% column vector containing the number of the type(s)(1 to 11) ....
                                                             %present in the corresponding annonation file
                             end
                     end
                     if(strcmp(splitselectedLine{2},'out-of-domain')>0)
                        annotation = 0;
                        return;
                     end
                    
                     if(strcmp(splitselectedLine{i},'Skipped')>0)
                        annotation = -1;
                        return;
                     end
                   
                end
            end
        else
            if(numberOfLine == 2)
                typeList = cell(1,2);
                typeList{1} = 'Current';
                typeList{2} = 'Not Current';
            elseif(numberOfLine == 3)
                typeList = cell(1,2);
                typeList{1} = 'Sufficient';
                typeList{2} = 'Not Sufficient';
            elseif(numberOfLine == 5)
                typeList = cell(1,2);
                typeList{1} = 'Urgent';
                typeList{2} = 'Not Urgent';
            end
            %disp(splitselectedLine{2})
            if(strcmp(splitselectedLine{2},typeList{1})>0)
                annotation = 1;
            else
                annotation = 2;
            end
            
            if(strcmp(splitselectedLine{2},'Skipped')>0)
                annotation = -1;
                return;
            end

            if(strcmp(splitselectedLine{2},'n/a')>0)
                annotation = 0;
                return;
            end
            
        
        end         
            
       
    end
    
end
%-----------------------------------------------------------------------------

