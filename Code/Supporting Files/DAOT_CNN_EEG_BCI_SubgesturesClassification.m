% Given the individual filtered sub-gesture signals per sequence of movement, we
% reconstruct the signals of the complete sequence of movement and classify
% the full gesture. 
%% Compute DA for each slidding window
WindowLength = floor(Parameters.MaxSegmentLength/Parameters.NumberSubGestures);
Parameters.MovementToModel=1;
for i=1:size(IndividualData,2)
     [IndividualData(i).DAModeledEEG, IndividualData(i).NewWindowLabel,IndividualData(i).NewWindowGestureLabel] = DA_Modeling (IndividualData(i).Segment, IndividualData(i).SegmentLabel, BesselFunctions, WindowLength, IndividualData(i).ConnectivityNetworkMatrix, Parameters.ProcessedNetworkMatrix, Parameters.MovementToModel);
end

%% save data into datastores
ClassifierParameters.SegmentLength = size(IndividualData(1).DAModeledEEG,2);
ClassifierParameters.Num_channels=size(IndividualData(1).DAModeledEEG,1);
ClassifierParameters.NumberSubjects=size(IndividualData,2);
ClassifierParameters.NumClassesClassifier=size(categories(categorical(squeeze(IndividualData(1).NewWindowGestureLabel))),1);

for i=1:ClassifierParameters.NumberSubjects
    SegmentLength = size(IndividualData(i).DAModeledEEG,2);
    Num_channels=size(IndividualData(i).DAModeledEEG,1);
    Num_Segments=size(IndividualData(i).DAModeledEEG,3);

    dataCells = mat2cell(IndividualData(i).DAModeledEEG,Num_channels,SegmentLength,ones(Num_Segments,1));
    dataCells = reshape(dataCells,[Num_Segments 1 1]);

    LabelsCat=categorical(squeeze(IndividualData(i).NewWindowGestureLabel))';
    labelCells=arrayfun(@(x)x,LabelsCat,'UniformOutput',false)';

    combinedCells = [dataCells labelCells];
    filename = strcat(ClassifierParameters.DatastorefilePath,'/Subject',int2str(i),'_DAModelingGesturesAndLabels_Sessions51-6_June-July2023.mat');
    save(filename,'combinedCells');
end

filepath=strcat(ClassifierParameters.DatastorefilePath,'/*.mat');
filedatastore = fileDatastore(filepath,'ReadFcn',@load);
EEGData = transform(filedatastore,@rearrangeData);

%% classify: training,validation and testing
trainRatio = 0.7;
ValidationRatio=0.2;
TotalIndices=1:ClassifierParameters.NumberSubjects;

indicesTraining = TotalIndices(1:floor(ClassifierParameters.NumberSubjects*trainRatio));
indicesValidation = TotalIndices(floor(ClassifierParameters.NumberSubjects*trainRatio)+1:floor(ClassifierParameters.NumberSubjects*trainRatio)+floor(ClassifierParameters.NumberSubjects*ValidationRatio));
indicesTesting = TotalIndices(floor(ClassifierParameters.NumberSubjects*trainRatio)+floor(ClassifierParameters.NumberSubjects*ValidationRatio)+1:end);

subsetTraining = subset(EEGData,indicesTraining);
subsetValidation = subset(EEGData,indicesValidation);
subsetTesting=subset(EEGData,indicesTesting);

ShuffledTrainingData=shuffle(subsetTraining);
ShuffledValidationData=shuffle(subsetValidation);

%CNN definition
layers = [
    imageInputLayer([ClassifierParameters.Num_channels ClassifierParameters.SegmentLength],'Name','input')  
    convolution2dLayer(4,8,'Padding','same','Name','conv_1')
     batchNormalizationLayer('Name','BN_1')
    reluLayer('Name','relu_1')
    convolution2dLayer(4,8,'Padding','same','Name','conv_2')
     batchNormalizationLayer('Name','BN_2')
    reluLayer('Name','relu_2')

    fullyConnectedLayer(ClassifierParameters.NumClassesClassifier,'Name','fc11')
    softmaxLayer('Name','softmax')
    classificationLayer('Name','classOutput')];

options = trainingOptions("adam", ...
    "MaxEpochs",30, ...
    "MiniBatchSize",8, ...
    "Shuffle","every-epoch",...
    "InitialLearnRate",0.001,...
    "Plots","training-progress",...
    "ValidationData",ShuffledValidationData,...
    "L2Regularization",1e-2,...
    "OutputNetwork","best-validation-loss",...
    "Verbose", false);

trainedNetSPN = trainNetwork(ShuffledTrainingData,layers,options);

ShuffledTestingData=shuffle(subsetTesting);
YPred = classify(trainedNetSPN,ShuffledTestingData);

TestingData=readall(ShuffledTestingData);
TestingTable = cell2table(TestingData,...
    "VariableNames",["Signal" "Label"]);
Ytest = TestingTable.Label;
accuracy = mean(YPred == Ytest);

confusionMatrix = confusionchart(Ytest, YPred,Normalization="column-normalized");