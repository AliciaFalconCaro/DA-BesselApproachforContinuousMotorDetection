function [AllData, ConnNetworkMatrixSubject1,ConnNetworkMatrixSubject2, ProcessedNetworkMatrix] = Preprocessing_Dataset1 (hyperscanningData, LowFilter, HighFilter, Fs, FullNetworkMatrix)

NumberSegments = size(hyperscanningData,3);
for i=1:NumberSegments
    DataSegment = hyperscanningData(:,:,i);
    %remove bad channels, the same for all the subjects (27,32)
    BadChannelRemovedData=[DataSegment(1:26,:);DataSegment(28:31,:);DataSegment(33:53,:);DataSegment(55:63,:)];
    FilteredData = (bandpass(BadChannelRemovedData',[HighFilter LowFilter],Fs))';
    DataRemovedBaseline=FilteredData - mean(FilteredData,2);
    NewData(:,:,i)=DataRemovedBaseline;
    
    %Connectivity Measure per segment
    NumChannelsPerSubject=size(BadChannelRemovedData,1)/2;
    DataSegmentSubject1=BadChannelRemovedData(1:NumChannelsPerSubject,:);
    DataSegmentSubject2=BadChannelRemovedData(NumChannelsPerSubject+1:end,:);

    ConnNetworkMatrixSubject1(:,:,i)=granger_cause(DataSegmentSubject1);
    ConnNetworkMatrixSubject2(:,:,i)=granger_cause(DataSegmentSubject2);

end

SegmentLength=size(NewData,2);
ContinuousData=[];
for i=1:NumberSegments
     ContinuousData=[ContinuousData,NewData(:,:,i)]; 
end
 
NormalizedData=normalize(ContinuousData,2);
 InitialPoint=1;
 for i=1:NumberSegments
     AllData(:,:,i)=NormalizedData(:,InitialPoint:InitialPoint+SegmentLength-1);
 end

 %eliminate any removed EEG channel from the 32 channel NetworkMatrix
ProcessedNetworkMatrix=[FullNetworkMatrix(1:26,:);FullNetworkMatrix(28:31,:)];
ProcessedNetworkMatrix=[ProcessedNetworkMatrix(:,1:26),ProcessedNetworkMatrix(:,28:31)];

end
