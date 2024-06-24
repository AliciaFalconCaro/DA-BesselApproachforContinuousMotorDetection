function [fullSegment,SegmentLabel,LengthSegment] = CleaningAllSessions (FullData, FullLabels)

        for i=1:length(FullLabels)
            if ((FullLabels(i)==-1) ||(FullLabels(i)==0))
                Data_Start=i+1;
            end
            if (FullLabels(i)~=4)
                Data_end=i;
            end
        end
    
        data= FullData(:,Data_Start:Data_end);
        Labels = FullLabels(:,Data_Start:Data_end);
        Length = length (data);

        %% gets start and end time of for each task based on their labels.
        %1: left hand - commonTask:1
        %2:right hand - commonTask:2
        %3: free-will time - uncommonTask:0
        NumberSegments_left =1;
        NumberSegments_right =1;
        NumberSegments_FreeWill =1;
    
        Block=1;
        i=1;
        while(Block<=Length) 
        
            if (Labels(Block)==1) 
                left_start(NumberSegments_left)=Block;
                for j=Block:Length
                    if (Labels(j) ~=1)
                        left_end(NumberSegments_left) = j-1;
                        PreSegmentLabel(i)=1; %used to define the regions together with data_start and data_end
                        data_start(i) =Block;
                        data_end(i) = j-1;
                        NumberSegments_left=NumberSegments_left+1;
                        Block=j-1;
                        break
                    end
                end
    
            elseif (Labels(Block)==2) 
                right_start(NumberSegments_right)=Block;
                for j=Block:Length
                    if (Labels(j) ~=2)
                        right_end(NumberSegments_right) = j-1;
                        PreSegmentLabel(i)=2;
                        data_start(i) =Block;
                        data_end(i) = j-1;
                        NumberSegments_right=NumberSegments_right+1;
                        Block=j-1;
                        break
                    end
                end
        
            elseif (Labels(Block)==3) 
                FreeWill_start(NumberSegments_FreeWill)=Block;
                for j=Block:Length
                    if (Labels(j) ~=3)
                        FreeWill_end(NumberSegments_FreeWill) = j-1;
                        PreSegmentLabel(i)=0;
                        data_start(i) =Block;
                        data_end(i) = j-1;
                        NumberSegments_FreeWill=NumberSegments_FreeWill+1;
                        Block=j-1;
                        break
                    end
                end
            end
    
            i=i+1;
            Block=Block+1;
        end
    
        %% segment data and decide length of data based on minimum length of segments
        for i=1:length(data_end)
            SizeSegments(i)=data_end(i)-data_start(i)+1;
        end
        LengthSegment = min(SizeSegments);
    
        %% Segment EEG based on labels and the maximum window per labelled ROI.
        NumberSegments = size(PreSegmentLabel,2);
        NumberFullSegment=1;
        for i=1:NumberSegments
            if (SizeSegments(i)==LengthSegment)
                fullSegment(:,:,NumberFullSegment)=data(:,data_start(i):data_end(i));
                SegmentLabel(NumberFullSegment)=PreSegmentLabel(i);
            else
                MultipleSegments=data(:,data_start(i):data_end(i));
                fullSegment(:,:,NumberFullSegment) = MultipleSegments(:,1:LengthSegment);
                SegmentLabel(NumberFullSegment)=PreSegmentLabel(i);
                NewSegmentStart = LengthSegment;

                while (length(MultipleSegments(:,NewSegmentStart:end)) >= LengthSegment)
                    NumberFullSegment=NumberFullSegment+1;
                    fullSegment(:,:,NumberFullSegment)=MultipleSegments(:,NewSegmentStart+1:NewSegmentStart+LengthSegment);
                    SegmentLabel(NumberFullSegment)=PreSegmentLabel(i);
                    NewSegmentStart = NewSegmentStart+ LengthSegment;
                end
            end
        NumberFullSegment=NumberFullSegment+1;
        end
end