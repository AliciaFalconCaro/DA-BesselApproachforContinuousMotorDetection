%% Dataset 2 preprocessing and Bessel functions estimation
% Data to test: http://gigadb.org/dataset/100295

clear all; clc;
tic
filepath=fullfile("Data"); 
Ds = fileDatastore(filepath,"ReadFcn",@load,IncludeSubFolders=true);
p=endsWith(Ds.Files,".mat");
EEGdata = subset(Ds,p);

% constants and parameters
Parameters.Fs=512; %sampling rate (srate)
Parameters.LowFilter=30;
Parameters.HighFilter=8;
Parameters.MaxSegmentLength=1; 
Parameters.NuEtaRatio=1; %nu-to-eta ratio: 0.1-1 (nu: size dictionary of orthogonal functions - number of available Bessel functions)
Parameters.NumberSubGestures=4; %finger gestures
DirectoryPath = what('DAModeledGesturesPerSubject');
ClassifierParameters.DatastorefilePath= DirectoryPath.path;
ClassifierParameters.NumClassesClassifier=Parameters.NumberSubGestures;

%% process data (data segmentation and labelling) and basic preprocessing (bad channel removal and bandpass filtering)
k=1;
Number_Subjects=1;
reset(EEGdata); 
load('NetworkMatrix_64ElectrodesConnected.mat', 'NetworkMatrix')
Parameters.FullNetworkMatrix=NetworkMatrix;

while hasdata(EEGdata)
    clearvars -except Ds EEGdata Parameters ClassifierParameters k FullData Number_Subjects IndividualData
    data=read(EEGdata);

    FullData(k).Data=data.eeg.movement_left(1:64,:);
    FullData(k).Labels=data.eeg.movement_event;

    %onset cue index for the start of each movement trial. 20 trials in
    %total per subject. Each movement takes 3seconds.
    FullData(k).index=find(FullData(k).Labels==1); 

    [IndividualData(k).PreprocessSegments,IndividualData(k).LengthSegment, IndividualData(k).SegmentLabel]=LabellingAndSegmentation(FullData(k).Data, FullData(k).index,Parameters.Fs);

    % Data filtering
    [IndividualData(k).Segment, IndividualData(k).ConnectivityNetworkMatrix, Parameters.ProcessedNetworkMatrix] = Preprocessing_Dataset2 (IndividualData(k).PreprocessSegments, Parameters.LowFilter, Parameters.HighFilter,Parameters.Fs, Parameters.FullNetworkMatrix);

    Number_Subjects=Number_Subjects+1;

    if (Parameters.MaxSegmentLength <IndividualData(k).LengthSegment) %obtain maximum segment length
        Parameters.MaxSegmentLength=IndividualData(k).LengthSegment;
    end

k=k+1;
end

%% Generate Dictionary of Bessel functions.
SizeDictionary=ceil(Parameters.NuEtaRatio*Parameters.NumberSubGestures);
NumberSamplesBessel=1:1:Parameters.MaxSegmentLength;
NumberSamplesBessel=0.5:0.5:(Parameters.MaxSegmentLength/2);
for i=1:SizeDictionary
    BesselFunctions_Reduced(i,:)=besselj(i,NumberSamplesBessel); 
end 

%% if (SizeDictionary<Parameters.NumberSubGestures): Some orthogonal functions will be assigned to similar sub-gestures.
    for i=1:Parameters.NumberSubGestures
        if (i==1)
            BesselFunctions(i,:)=BesselFunctions_Reduced(1,:);
        elseif (i==4)
              BesselFunctions(i,:)=BesselFunctions_Reduced(2,:);
%         elseif (i==2 || i == 3)
%             BesselFunctions(i,:)=BesselFunctions_Reduced(3,:);
%         elseif (i==4)
%             BesselFunctions(i,:)=BesselFunctions_Reduced(4,:);
%         elseif (i==7)
%             BesselFunctions(i,:)=BesselFunctions_Reduced(5,:);
        % elseif ( i==8 ) 
        %     BesselFunctions(i,:)=BesselFunctions_Reduced(6,:);
        else
            BesselFunctions(i,:)=BesselFunctions_Reduced(3,:);
        end
    end

%% Compute DAOT-CNN 
DAOT_CNN_EEG_BCI_SubgesturesClassification
