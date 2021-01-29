import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
import FeedForwardNetwork as FFN
import TrepanDatasetType as TDT
import pickle

def generateRandomDataset(examplesNumber):
    ### Remember to create the input tensors using .cuda() 
    ### if you want to run the model on gpu.
    #examples = torch.rand(examplesNumber, 2).cuda()
    #labels = torch.zeros(examplesNumber, 1).cuda()
    examples = torch.rand(examplesNumber, 2)
    labels = torch.zeros(examplesNumber, 1)
    for i, ex in enumerate(list(examples)):
        if (ex[0] > 0.5 and ex[1] < 0.5) or (ex[0] < 0.5 and ex[1] > 0.5):
            labels[i] = 1
    return zip(examples, labels)

def generateBalancedDataset(examplesNumber):
    examples = torch.rand(examplesNumber, 2)
    
    # x < 0.5 and y < 0.5
    minRange = 0
    maxRange = 0.5
    x = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    y = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    twoLowValues = torch.cat((x, y), 1)
    
    # x > 0.5 and y > 0.5
    minRange = 0.5
    maxRange = 1 
    x = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    y = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    twoHighValues = torch.cat((x, y), 1)
    
    # x > 0.5 and y < 0.5
    minRange = 0.5
    maxRange = 1 
    x = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    minRange = 0
    maxRange = 0.5
    y = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    firstHighSecondLowValues = torch.cat((x, y), 1)

    # x < 0.5 and y > 0.5
    minRange = 0
    maxRange = 0.5
    x = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    minRange = 0.5
    maxRange = 1 
    y = (minRange - maxRange) * torch.rand(int(examplesNumber / 4), 1) + maxRange
    firstLowSecondHighValues = torch.cat((x, y), 1)

    balancedDataset = torch.cat((twoLowValues, twoHighValues, firstHighSecondLowValues, firstLowSecondHighValues), 0)
    npArray = balancedDataset.data.numpy()  
    np.random.shuffle(npArray)
    shuffledDataset = torch.from_numpy(npArray)

    labels = torch.zeros(examplesNumber, 1)
    for i, ex in enumerate(list(shuffledDataset)):
        if (ex[0] > 0.5 and ex[1] < 0.5) or (ex[0] < 0.5 and ex[1] > 0.5):
            labels[i] = 1
    return zip(shuffledDataset, labels)

network = FFN.FeedForwardNetwork("ThresholdXor", 2, 1, [8], 1)

### Uncomment to run on CUDA GPU (do that only for BIG networks)
# if (torch.cuda.is_available):
#     network.cuda()

### Uncomment to generate and store training and test sets.
# trainingSet = list(generateBalancedDataset(200))
# validationSet = list(generateBalancedDataset(60))
# trainingFile = open("ThresholdXor.train", 'wb')
# validationFile = open("ThresholdXor.test", 'wb')
# pickle.dump(trainingSet, trainingFile)
# trainingFile.close()
# pickle.dump(validationSet, validationFile)
# validationFile.close()

trainingFile = open("ThresholdXor.train", 'rb')
validationFile = open("ThresholdXor.test", 'rb')

trainingSet = pickle.load(trainingFile)
trainingFile.close()
validationSet = pickle.load(validationFile)
validationFile.close()

network.writeTrepanNetFile()
trepanInputDescriptors = [["firstInput", "R"], ["secondInput", "R"]]
network.writeTrepanAttributesFile(trepanInputDescriptors)
network.writeTrepanDatasetFile(TDT.Train, trainingSet, bConvertOutputToBool=True)
network.writeTrepanDatasetFile(TDT.Validation, validationSet, bConvertOutputToBool=True)

criterion = nn.MSELoss()
optimizer = optim.SGD(network.parameters(), lr = 0.01) 

inputs, targets = zip(*trainingSet)
network.train(inputs, targets, criterion, optimizer, 8000, 500)

inputs, targets = zip(*validationSet)
network.test(inputs, targets)

network.saveWeights()

print("\n>> Done.")