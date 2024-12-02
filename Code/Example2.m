%% Dataset 1 preprocessing and Bessel functions estimation for the recognition of sequences of sub-gestures. 
% If nu-to-eta ratio < 1, the similar Bessel functions are assigned to
% similar sub-gestures.
clear all; clc;
%add data to datastores
filepath=fullfile("Copy_of_EEGHyperscanning"); 
Ds = fileDatastore(filepath,"ReadFcn",@load,IncludeSubFolders=true);
p=endsWith(Ds.Files,"d.mat");
EEGdata = subset(Ds,p);

% constants and parameters
Parameters.Fs=250; %sampling rate
Parameters.LowFilter=30;
Parameters.HighFilter=8;
Parameters.MaxSegmentLength=1; 
Parameters.NumberSubGestures=8; %\eta in total
Parameters.NuEtaRatio=1; %nu-to-eta ratio: 0.1-1 (nu: size dictionary of orthogonal functions - number of available Bessel functions)
DirectoryPath = what('DAModeledGesturesPerSubject');
ClassifierParameters.DatastorefilePath= DirectoryPath.path;
ClassifierParameters.NumClassesClassifier=Parameters.NumberSubGestures;

%% process data (data segmentation and labelling) and basic preprocessing (bad channel removal and bandpass filtering)
k=1;
Number_Subjects=1;
reset(EEGdata); 
load('NetworkMatrix_32ElectrodesConnected.mat', 'NetworkMatrix')
Parameters.FullNetworkMatrix=NetworkMatrix;

while hasdata(EEGdata)
    clearvars -except Ds EEGdata Parameters ClassifierParameters k FullData Number_Subjects IndividualData
    data=read(EEGdata);

    FullData(k).hyperscanningData=data.y(2:65,:);
    FullData(k).Labels=data.y(67,:);

    % Data labelling
    [FullData(k).FullSegment,FullData(k).SegmentLabel,FullData(k).LengthSegment]=CleaningAllSessions (FullData(k).hyperscanningData, FullData(k).Labels);          

    % Data filtering and bad channels removal   
    [FullData(k).ProcessedDataSegments, FullData(k).ConnectivityNetworkMatrixSubject1, FullData(k).ConnectivityNetworkMatrixSubject2, Parameters.ProcessedNetworkMatrix] = Preprocessing_Dataset1 (FullData(k).FullSegment, Parameters.LowFilter, Parameters.HighFilter,Parameters.Fs, Parameters.FullNetworkMatrix);

    % Separation of hyperscanning data into two subjects
    NumberChannels=size(FullData(k).ProcessedDataSegments,1)/2;
    IndividualData(Number_Subjects).Segment = FullData(k).ProcessedDataSegments(1:NumberChannels,:,:);
    IndividualData(Number_Subjects).SegmentLabel = FullData(k).SegmentLabel;
    IndividualData(Number_Subjects).ConnectivityNetworkMatrix=FullData(k).ConnectivityNetworkMatrixSubject1;
    Number_Subjects=Number_Subjects+1;
    
    IndividualData(Number_Subjects).Segment = FullData(k).ProcessedDataSegments(NumberChannels+1:end,:,:);
    IndividualData(Number_Subjects).SegmentLabel = FullData(k).SegmentLabel;
    IndividualData(Number_Subjects).ConnectivityNetworkMatrix=FullData(k).ConnectivityNetworkMatrixSubject2;
    Number_Subjects=Number_Subjects+1;

    if (Parameters.MaxSegmentLength <FullData(k).LengthSegment) 
        Parameters.MaxSegmentLength=FullData(k).LengthSegment;
    end

k=k+1;
end

%% Generate Dictionary of Bessel functions.
SizeDictionary=round(Parameters.NuEtaRatio*Parameters.NumberSubGestures);
NumberSamplesBessel=1:1:Parameters.MaxSegmentLength;
NumberSamplesBessel=0.5:0.5:(Parameters.MaxSegmentLength/2);
for i=1:SizeDictionary
    BesselFunctions_Reduced(i,:)=besselj(i,NumberSamplesBessel); 
end 

if (SizeDictionary<Parameters.NumberSubGestures) %Some orthogonal functions will be assigned to similar sub-gestures when nu-to-eta ratio < 1. The assigment of Bessel functions can be modified.
    for i=1:Parameters.NumberSubGestures
        if (i==4 || i==5)
             BesselFunctions(i,:)=BesselFunctions_Reduced(1,:);
        elseif (i==2 || i==3)
              BesselFunctions(i,:)=BesselFunctions_Reduced(2,:);
        elseif (i==6 || i == 7)
              BesselFunctions(i,:)=BesselFunctions_Reduced(3,:);
        elseif (i==1)
            BesselFunctions(i,:)=BesselFunctions_Reduced(4,:);
        else
            BesselFunctions(i,:)=BesselFunctions_Reduced(5,:);
        end
    end
else
    for i=1:Parameters.NumberSubGestures
        BesselFunctions(i,:)=BesselFunctions_Reduced(i,:);
    end
end

%% Compute DAOT-CNN 
 DAOT_CNN_EEG_BCI_SubgesturesClassification
