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

%% Load data from datastores
filepath=strcat(ClassifierParameters.DatastorefilePath,'/*.mat');
filedatastore = fileDatastore(filepath,'ReadFcn',@load);
EEGData = transform(filedatastore,@rearrangeData);


%% classify: validation and CNN
%% Crossvalidation:5-folds
%divide into training and testing
trainRatio = 0.9;
TestingRatio=0.1;
TotalIndices=1:ClassifierParameters.NumberSubjects;
miniBatchSize=8;

%split training/validation and testing
indicesTrainingValidation = TotalIndices(1:floor(ClassifierParameters.NumberSubjects*trainRatio));
indicesTesting = TotalIndices(floor(ClassifierParameters.NumberSubjects*trainRatio)+1:end);

subsetTrainingValidation = subset(EEGData,indicesTrainingValidation);
subsetTesting=subset(EEGData,indicesTesting);

%Training CNN with kfold cross-validation

layers = [
    imageInputLayer([ClassifierParameters.Num_channels ClassifierParameters.SegmentLength],'Name','input')  
    convolution2dLayer(4,8,'Padding','same','Name','conv_1')
     batchNormalizationLayer('Name','BN_1')
    reluLayer('Name','relu_1')

    convolution2dLayer(4,8,'Padding','same','Name','conv_2')
     batchNormalizationLayer('Name','BN_2')
    reluLayer('Name','relu_2')

    fullyConnectedLayer(ClassifierParameters.NumClassesClassifier,'Name','fc11')
    softmaxLayer('Name','softmax')];

% Split Data into k Folds
cv = cvpartition(indicesTrainingValidation, 'LeaveOut');
k=cv.NumTestSets;


% Initialize arrays to store metrics for each fold
ValAccuracy = zeros(k, 1);
ValfScore = zeros(k, 1);
ValaucScore = zeros(k, 1);
confMatrixSum = zeros(ClassifierParameters.NumClassesClassifier, ClassifierParameters.NumClassesClassifier);
ConfusionMatrixPerFold = zeros(ClassifierParameters.NumClassesClassifier, ClassifierParameters.NumClassesClassifier, k);
trainedNetworks = cell(k, 1); % Cell array to store each fold's network

for fold = 1:k
    % Create training and validation sets for this fold
    indicesTraining = training(cv, fold);
    indicesValidation = test(cv, fold);
    subsetTraining = subset(subsetTrainingValidation,indicesTraining);
    subsetValidation = subset(subsetTrainingValidation,indicesValidation);

    % shuffle data and train network
    ShuffledTrainingData=shuffle(subsetTraining);
    ShuffledValidationData=shuffle(subsetValidation);

    options = trainingOptions("adam", ...
    "Acceleration","none",...
    "ExecutionEnvironment", "cpu",...
    "MaxEpochs",30, ...
    "ValidationData",ShuffledValidationData, ...
    "Metrics", "accuracy", ...
    "MiniBatchSize",miniBatchSize, ...
    "Shuffle","every-epoch",...
    "InitialLearnRate",0.001,...
    "Plots","training-progress",...
    "L2Regularization",1e-2,...
    "OutputNetwork","best-validation",...
    "Verbose", false);

    [trainedNetSPN, info] = trainnet(ShuffledTrainingData,layers,"crossentropy",options);

    trainedNetworks{fold}.net = trainedNetSPN;
    trainedNetworks{fold}.info = info;

    % Validate on the validation set
    ValidationData=readall(ShuffledValidationData);
    ValTable = cell2table(ValidationData,...
    "VariableNames",["Signal" "Label"]);
    Yval = ValTable.Label;
    classNames=cellstr(unique(Yval));
    YPredScores = minibatchpredict(trainedNetSPN, ShuffledValidationData, MiniBatchSize=miniBatchSize, ExecutionEnvironment="cpu");
    YPred = scores2label(YPredScores,classNames);
    
    %Validation Accuracy
    ValAccuracy(fold) = testnet(trainedNetSPN, ShuffledValidationData, "accuracy", miniBatchSize=miniBatchSize);

    % Average F-score and AUC across classes for this fold
    ValfScore(fold) = testnet(trainedNetSPN, ShuffledValidationData, "fscore", miniBatchSize=miniBatchSize);
    ValaucScore(fold) = testnet(trainedNetSPN, ShuffledValidationData, "auc", miniBatchSize=miniBatchSize);

    % Calculate the confusion matrix for this fold
    foldConfMatrix = confusionmat(Yval, YPred,'Order', unique(Yval));
    confMatrixSum = confMatrixSum + foldConfMatrix;
    ConfusionMatrixPerFold(:,:,fold)=foldConfMatrix;

end

% Calculate the average confusion matrix
avgConfMatrix = confMatrixSum / k;

% Display average cross-validation metrics
fprintf('Average Cross-Validation Metrics:\n');
fprintf('Average Accuracy: %.3f ± %.3f\n', mean(ValAccuracy), std(ValAccuracy, 1));
fprintf('Average F-Score: %.3f ± %.3f\n', mean(ValfScore), std(ValfScore, 1));
fprintf('Average AUC: %.3f ± %.3f\n', mean(ValaucScore), std(ValaucScore, 1));



%% Final testing with blind data using best performance Model based on F-Score:

TrainedNet=trainedNetworks{4}.net; %model to be selected from the saved models from the k-fold crossvalidation
ShuffledTestingData=shuffle(subsetTesting);
TestingData=readall(ShuffledTestingData);
TestingTable = cell2table(TestingData,...
    "VariableNames",["Signal" "Label"]);
Ytest = TestingTable.Label;
classNames=cellstr(unique(Ytest));

YPredScores = minibatchpredict(TrainedNet, ShuffledTestingData, MiniBatchSize=miniBatchSize, ExecutionEnvironment="cpu");
YPred = scores2label(YPredScores,classNames);

TestingAcc=testnet(TrainedNet, ShuffledTestingData,"accuracy", miniBatchSize=miniBatchSize);
Testing_fscore=testnet(TrainedNet, ShuffledTestingData,"fscore", miniBatchSize=miniBatchSize);

confusionMatrix = confusionchart(Ytest, YPred,Normalization="column-normalized");

% Display testing metrics
fprintf(' Testing Metrics:\n');
fprintf('Testing Accuracy: %.3f\n', TestingAcc);
fprintf('Testing F-Score: %.3f\n', Testing_fscore);
