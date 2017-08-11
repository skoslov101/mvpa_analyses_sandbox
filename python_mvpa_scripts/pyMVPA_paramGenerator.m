function pyMVPA_paramGenerator(subID)
%% Convert pmTaskRegs to pyMVPA format
%this script will take a subject as an input and generate the PM task
%params for that subject
if length(subID)>1
    for subI=subID
        startDir=pwd;

        cd ../../
        curDir=pwd;

        subDir=[curDir '/forcemem_' mat2str(subI)];
        %If the pyMVPA params don't exist create one
        if exist([subDir '/behav/pyMVPA_params'])==0
            mkdir([subDir '/behav/pyMVPA_params']);
        end

        load([subDir '/behav/mvpa_params/pmTaskRegs.mat']);

        cd([subDir '/behav/pyMVPA_params']);
        %% start actual param generation
        blockN=5; %Five blocks
        blockLen=306; %306 TRs/probes per block


        timePoints=[];
        attrArray=[];

        for blockI=1:blockN
            for probeI=1:blockLen
                %First, I'm going to tell the python script which timepoints to keep
                %and which to discard.  This is based on whether there is one of the 4
                %events or a not-real trial at that moment
                pmType=find(pmTaskReg(:,(blockI-1)*306+probeI)==1);

                if isempty(pmType)
                    pmType=5;
                else
        %             timePoints=[timePoints,probeI];

                    if pmType==1
                        pmTarget='Face';
                    elseif pmType==2
                        pmTarget='Scene';
                    elseif pmType==3
                        pmTarget='OG';
                    else
                        pmTarget='Rest';
                    end






                end

                attrArray=[attrArray;pmType,blockI];



            end

            %Now save the target attributes
            attrFilename=['block' mat2str(blockI) '_attr.txt'];
            fileID=fopen(attrFilename,'w');
            formatSpec='%d %d\n';
            [nrows,ncols]=size(attrArray);
            for rowI=1:nrows
                fprintf(fileID,formatSpec, attrArray(rowI,:));
            end
            fclose(fileID); 

            attrArray=[];
        end

        % %Save the block useable timepoints
        % testID='testTimePoints.txt';
        % fileID=fopen(testID,'w');
        % formatSpec='%d\n';
        % [nrows,ncols]=size(timePoints);
        % for colI=1:ncols
        %     fprintf(fileID,formatSpec, timePoints(:,colI));
        % end
        % fclose(fileID); 
        cd(startDir)
    end
else
    

    startDir=pwd;

    cd ../../
    curDir=pwd;

    subDir=[curDir '/forcemem_' mat2str(subID)];
    %If the pyMVPA params don't exist create one
    if exist([subDir '/behav/pyMVPA_params'])==0
        mkdir([subDir '/behav/pyMVPA_params']);
    end

    load([subDir '/behav/mvpa_params/pmTaskRegs.mat']);

    cd([subDir '/behav/pyMVPA_params']);
    %% start actual param generation
    blockN=5; %Five blocks
    blockLen=306; %306 TRs/probes per block


    timePoints=[];
    attrArray=[];

    for blockI=1:blockN
        for probeI=1:blockLen
            %First, I'm going to tell the python script which timepoints to keep
            %and which to discard.  This is based on whether there is one of the 4
            %events or a not-real trial at that moment
            pmType=find(pmTaskReg(:,(blockI-1)*306+probeI)==1);

            if isempty(pmType)
                pmType=5;
            else
    %             timePoints=[timePoints,probeI];

                if pmType==1
                    pmTarget='Face';
                elseif pmType==2
                    pmTarget='Scene';
                elseif pmType==3
                    pmTarget='OG';
                else
                    pmTarget='Rest';
                end






            end

            attrArray=[attrArray;pmType,blockI];



        end

        %Now save the target attributes
        attrFilename=['block' mat2str(blockI) '_attr.txt'];
        fileID=fopen(attrFilename,'w');
        formatSpec='%d %d\n';
        [nrows,ncols]=size(attrArray);
        for rowI=1:nrows
            fprintf(fileID,formatSpec, attrArray(rowI,:));
        end
        fclose(fileID); 

        attrArray=[];
    end

    % %Save the block useable timepoints
    % testID='testTimePoints.txt';
    % fileID=fopen(testID,'w');
    % formatSpec='%d\n';
    % [nrows,ncols]=size(timePoints);
    % for colI=1:ncols
    %     fprintf(fileID,formatSpec, timePoints(:,colI));
    % end
    % fclose(fileID); 
    cd(startDir)
end

