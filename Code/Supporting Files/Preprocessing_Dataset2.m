function [AllData, ConnNetworkMatrix, ProcessedNetworkMatrix] = Preprocessing_Dataset2 (Data, LowFilter, HighFilter, Fs, FullNetworkMatrix)

NumberSegments = size(Data,3);
SegmentLength = size(Data,2);
for i=1:NumberSegments
    DataSegment = Data(:,:,i);
    FilteredData = (bandpass(DataSegment',[HighFilter LowFilter],Fs))';
    DataRemovedBaseline=FilteredData - mean(FilteredData,2);
    NewData(:,:,i)=DataRemovedBaseline;

    %Connectivity Measure per segment
    %ConnNetworkMatrix(:,:,i)=granger_cause(DataSegment);
    %for EEGnet/SCCNet
    ConnNetworkMatrix(:,:,i)=zeros(size(DataSegment,1),size(DataSegment,2));
end

ContinuousData=[];
for i=1:NumberSegments
     ContinuousData=[ContinuousData,NewData(:,:,i)]; 
end

NormalizedData=normalize(ContinuousData,2);
 InitialPoint=1;
 for i=1:NumberSegments
     AllData(:,:,i)=NormalizedData(:,InitialPoint:InitialPoint+SegmentLength-1);
 end

 %eliminate any removed EEG channel from the 64 channel NetworkMatrix. In
 %this case no channels needs to be removed.
 ProcessedNetworkMatrix=FullNetworkMatrix;

end

