import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
import FeedForwardNetwork as FFN
# import TrepanDatasetType as TDT
import pickle

# class TrepadDatasetType:
#     Train, Validation = range(2)

def generateWeatherDataset (examplesNumber):
    # Values of Outlook (Sunny (1), Overcast (2), Rain (3))
    categoricalData1 = torch.randint(1,4,(examplesNumber,)) 
    # Values of Humidity (High (4) / Low (5))
    categoricalData2 = torch.randint(4,6,(examplesNumber,)) 
    # Values of Wind (Strong (6) / Weak (7))
    categoricalData3 = torch.randint(6,8,(examplesNumber,)) 

    # Outlook nominals get mapped to 3 input neurons
    categoricalInputMapping1 = torch.zeros(examplesNumber, 3)
    for i, x in enumerate(categoricalData1):
        if x == 1:
            categoricalInputMapping1[i] = torch.Tensor([1, 0, 0])
        elif x == 2:
            categoricalInputMapping1[i] = torch.Tensor([0, 1, 0])
        elif x == 3:
            categoricalInputMapping1[i] = torch.Tensor([0, 0, 1])

    # Humidity nominals get mapped to 2 input neurons
    categoricalInputMapping2 = torch.zeros(examplesNumber, 2)
    for i, x in enumerate(categoricalData2):
        if x == 4:
            categoricalInputMapping2[i] = torch.Tensor([1, 0])
        elif x == 5:
            categoricalInputMapping2[i] = torch.Tensor([0, 1])

    # Wind nominals get mapped to 2 input neurons
    categoricalInputMapping3 = torch.zeros(examplesNumber, 2)
    for i, x in enumerate(categoricalData3):
        if x == 6:
            categoricalInputMapping3[i] = torch.Tensor([1, 0])
        elif x == 7:
            categoricalInputMapping3[i] = torch.Tensor([0, 1])

    # put all together
    examples = torch.cat([categoricalInputMapping1, categoricalInputMapping2, categoricalInputMapping3], 1)

    # generate the labels
    labels = torch.zeros(examplesNumber, 1)
    for i, example in enumerate(list(examples)):
        # Outlook = 2
        if example[1] == 1: 
            labels[i] = 1
        # Outlook = 1 and Humidity = 5
        elif example[0] == 1 and example[4] == 1:
            labels[i] = 1
        # Outlook = 3 and Wind = 7
        elif example[2] == 1 and example[6] == 1:
            labels[i] = 1
            
    return zip(examples, labels)

# create FFN model on CPU
network = FFN.FeedForwardNetwork("weather", 7, 1, [8], 1)

# create training and validation datasets
trainingSet = list(generateWeatherDataset(200))
validationSet = list(generateWeatherDataset(60))

# write the .net file for Trepan
network.writeTrepanNetFile()
# specify input types and their nominal values (optionally) 
trepanInputDescriptors = [["outlook", "N"], ["humidity", "N"], ["wind", "N"]]
trepanNominalInputValues = [[1, 2, 3], [4, 5], [6, 7]]
# write the .attr file for Trepan
network.writeTrepanAttributesFile(trepanInputDescriptors, trepanNominalInputValues)
# write the .train.pat file for Trepan
network.writeTrepanDatasetFile(0, trainingSet, trepanInputDescriptors, trepanNominalInputValues, True)
# write the .test.pat file for Trepan
network.writeTrepanDatasetFile(1, validationSet, trepanInputDescriptors, trepanNominalInputValues, True)
# write the .cmd file for Trepan
network.writeTrepanCommandFile()

# select MSE as loss function
criterion = nn.MSELoss()
# select stochastic gradient descent as optimization algorithm 
# with learning rate set to 0.01
optimizer = optim.SGD(network.parameters(), lr = 0.01) 

# train the model
inputs, targets = zip(*trainingSet)
network.train(inputs, targets, criterion, optimizer, 2000, 500)

# test the model
inputs, targets = zip(*validationSet)
network.test(inputs, targets)

# save the weights for Trepan
network.saveWeights()

print("\n>> Done.")