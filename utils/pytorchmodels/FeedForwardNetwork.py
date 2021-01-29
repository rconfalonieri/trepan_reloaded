import math
import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
from collections import OrderedDict
import os

class FeedForwardNetwork(nn.Module):

#    TODO roberto: the training algorithm should be improved to take into account the following pseudo-code
#   for each epoch
    #   for each training data instance
    #       propagate error through the network
    #       adjust the weights
    #       calculate the accuracy over training data
    #   for each validation data instance
    #       calculate the accuracy over the validation data
    #   if the threshold validation accuracy is met
    #       exit training
    #   else
    #       continue training 
    def __init__(self, modelName, numInputUnits, numHiddenLayers, numHiddenLayersUnits, numOutputUnits, 
                    bUseSoftmax = False, bBinaryClassifier = True):
        super(FeedForwardNetwork, self).__init__()

        if numInputUnits <= 0 or numHiddenLayers <= 0 or numOutputUnits <= 0:
            raise ValueError("Number of inputs, hidden layers or output cannot be 0 or negative.")

        if numHiddenLayersUnits[0] <= 0:
            raise ValueError("Number of hidden layers units cannot be 0 or negative.")

        # store settings
        self.modelName = modelName
        self.numInputUnits = numInputUnits
        self.numHiddenLayers = numHiddenLayers
        self.numHiddenLayersUnits = numHiddenLayersUnits
        self.numOutputUnits = numOutputUnits
        self.bUseSoftmax = bUseSoftmax
        self.bBinaryClassifier = bBinaryClassifier
        self.flat_weights = torch.Tensor([])
        self.TRAIN = "train"
        self.VALIDATION = "validation"


        # create layers
        self.layers = nn.ModuleList()
        for i in range(0, numHiddenLayers):
            if i == 0:
                self.layers.append(nn.Linear(numInputUnits, numHiddenLayersUnits[i]))    
            else:
                self.layers.append(nn.Linear(numHiddenLayersUnits[i], numHiddenLayersUnits[i]))
        # wire up the output layer
        self.outputLayer = nn.Linear(numHiddenLayersUnits[numHiddenLayers - 1], numOutputUnits)

        # randomize the weights
        self.resetParameters()

    # Prints an array of values formatted between square brackets with an initial label.
    def __printStatArray(self, arrayName, arrayLength, arrayData, bPrintOneStatPerLine, 
                            bRoundValues = False, roundingPrecision = 4):
        print("%s:[" %arrayName, end = '')
        for i in range(0, arrayLength):
            if i == arrayLength - 1:
                if bRoundValues:
                    print("%.4f" %round(float(arrayData[i]), roundingPrecision), end = '')
                else:
                    print("%.4f" %float(arrayData[i]), end = '')
            else:
                if bRoundValues:
                    print("%.4f, " %round(float(arrayData[i]), roundingPrecision), end = '')
                else:
                    print("%.4f, " %float(arrayData[i]), end = '')
        # new line or just append according to bPrintOneStatPerLine
        self.__printStatArrayEnd(bPrintOneStatPerLine)

    # This function exists only to reduce boiler-plate code 
    # between self.Test() and self.__PrintStatArray().
    def __printStatArrayEnd(self, bPrintOneStatPerLine):
            if bPrintOneStatPerLine:
                print("]")
            else:
                print("] ", end = '')

    # Simply randomize the params.
    # TODO: implement Xavier (Glorot) optionally
    def resetParameters(self):
        stdv = 1.0 / math.sqrt(self.numHiddenLayersUnits[-1])
        for weight in self.parameters():
            weight.data.uniform_(-stdv, stdv)

    def forward(self, dataVector):
        """Forward Pass
        
        Arguments:
            dataVector {Tensor} -- The input vector.

        """
        for layer in self.layers:
            dataVector = torch.sigmoid(layer(dataVector))

        if self.bUseSoftmax:
            return F.softmax(self.outputLayer(dataVector), dim=0).sum()

        return self.outputLayer(dataVector)

    def train(self, inputs, targets, criterion, optimizer, numMaxEpochs, 
                logEpochs, lossStopThreshold = 0, bDebug = 1):
        """Train the network.
        
        Arguments:
            inputs {List} -- The dataset examples.

            targets {List} -- The dataset labels.

            criterion {PyTorch Loss class} -- 
            The loss function. See "torch.optim" for more info. 

            optimizer {PyTorch Optimizer class} -- 
            The optimization algorithm. See "torch.nn" for more info.

            numMaxEpochs {int} -- Max number of epochs.

            logEpochs {int} -- 
            Number of epochs interval to report the stats. 
        
        Keyword Arguments:
            lossStopThreshold {int} -- Loss minimum threshold to reach. (default: {0})
        """
        if bDebug:
            print(">> Training")

        for i in range(0, numMaxEpochs + 1):
            correct = 0
            for input, target in zip(inputs, targets):
                # reset gradients
                optimizer.zero_grad()   
                # propagate - measure - backpropagate
                output = self.forward(input)
                loss = criterion(output, target)
                loss.backward()
                optimizer.step()
                # 0.5 threshold accuracy check for binary classification
                if (self.bBinaryClassifier):
                    bOutput = output > 0.5
                    bTarget = target > 0.5
                    if (bOutput == bTarget):
                        correct += 1
            # compute accuracy
            accuracy = (float(correct) / len(targets)) * 100
            # log    
            if bDebug and i % logEpochs == 0:
                accuracyStr = "N/A"
                if (self.bBinaryClassifier):
                    accuracyStr = "{:.2f}% ({}/{})".format(accuracy, correct, len(targets))
                print("Epoch {: >8} \t\tLoss: {: >24} \t\tAccuracy: {}".format(i, loss.cpu().data.numpy(), accuracyStr))
            # early termination condition check
            if loss < lossStopThreshold:
                if bDebug:
                    print("Loss Stop Threshold reached.")
                return

    def test(self, inputs, targets, bPrintOneStatPerLine = False):
        """Test the network and print the results and stats.
        
        Arguments:
            inputs {List} -- The dataset examples.
            targets {List} -- The dataset labels.
        
        Keyword Arguments:
            bPrintOneStatPerLine {bool} -- 
            If true, each data will be printed on a separate line. 
            (default: {False})
        """
        print("\n>> Test")
        correct = 0
        for input, target in zip(inputs, targets):
            # compute forward pass
            output = self.forward(input)

            # print inputs (rounding up the values)
            self.__printStatArray("Inputs", self.numInputUnits, input, bPrintOneStatPerLine, True)
            # print the labels (without rounding up the values)
            self.__printStatArray(" Labels", self.numOutputUnits, target, bPrintOneStatPerLine)
            # print prediction (rounding up the values)
            self.__printStatArray(" Predicted", self.numOutputUnits, output, bPrintOneStatPerLine, True)
            
            # print error
            print(" Error:[", end = '')
            if self.numOutputUnits > 1:
                # compute average 
                sum = 0
                for i in range(0, self.numOutputUnits):
                    sum += float(abs(target[i] - output[i]))

                error = sum / self.numOutputUnits
                print("%s" %round(float(error), 4), end = '')
            else:
                # compute difference between the label and the prediction
                print("%s" %round(float(abs(target[0] - output[0])), 4), end = '')
            # close array and insert new line char
            self.__printStatArrayEnd(True)

            # 0.5 threshold accuracy check for binary classification
            if self.bBinaryClassifier:
                bOutput = output > 0.5
                bTarget = target > 0.5
                if (bOutput == bTarget):
                    correct += 1
        # compute accuracy
        accuracy = (float(correct) / len(targets)) * 100
        print('Accuracy: {:.2f}% ({}/{})'.format(accuracy, correct, len(targets)))

    def writeTrepanNetFile(self):
        """Write Trepan network definition file.
        
        Arguments:
            fileName {String} -- The file name, including the extension ".net"
        """
        outFile = open("../examples/"+self.modelName+"_example/"+self.modelName + ".net", 'w')
        
        print("definitions:", file = outFile)
        print("ninputs %d" %self.numInputUnits, file = outFile)
        print("nhiddenlayers %d" %self.numHiddenLayers, end = '', file = outFile)
        # print the number of units for each hidden layer
        for layerIndex in range(0, self.numHiddenLayers):
            print(" %d " %self.numHiddenLayersUnits[layerIndex], end = '', file = outFile)
        # new line
        print('', file = outFile)
        print("noutputs %d" %self.numOutputUnits, file = outFile)
        print("end", file = outFile)

        outFile.close()

    def writeTrepanDatasetFile(self, trepanDatasetType, dataset, trepanInputDescriptors, 
                                trepanNominalInputValues = [], bConvertOutputToBool = False):
        """ Write Trepan attribute files for a training or test set.
        
        Arguments:
            fileName {String} -- 
            The file name, including the extension 
            "train.pat" or "test.pat".

            dataset {List} -- The dataset.
        
        Keyword Arguments:
            bConvertOutputToBool {bool} -- 
            Whether the output values must be converted 
            to a boolean string "True"/"False" (default: {False})
        """
        fileName = self.modelName
        if trepanDatasetType == 0:
            fileName += ".train.pat"
        elif trepanDatasetType == 1:
            fileName += ".test.pat"

        outFile = open("../examples/"+self.modelName+"_example/"+fileName, 'w')

        for i, j in enumerate(dataset):
            # print line header
            print("p-%s " %i, end = '', file = outFile)
            # print attribute input values
            idx = 0
            nominalIndex = 0
            for inputDesc in trepanInputDescriptors:
                # if nominal,
                # print the nominal value corresponding to the index 
                # of the input set to 1
                if inputDesc[1] == 'N': 
                    valueIndex = 0
                    for inputIndex in range(0, len(trepanNominalInputValues[nominalIndex])):
                        if j[0][idx + inputIndex] == 1:
                            valueIndex = inputIndex
                    print("%s " %trepanNominalInputValues[nominalIndex][valueIndex], end = '', file = outFile)
                    idx += len(trepanNominalInputValues[nominalIndex])
                    nominalIndex += 1
                else:
                    print("%s " %j[0][idx].item(), end = '', file = outFile)
                    idx += 1
            # print attribute output values
            if bConvertOutputToBool:
                # convert output to boolean literals 
                # not clear to me why to iterate on numOutputUnits, if binary class problem
                #there is only 1 unit
                for k in range(0, self.numOutputUnits):
                    if j[1][k].item() == 1.0:
                        print("true ", file = outFile)
                    else:
                        print("false ", file = outFile)
            else:
                # not working with the current data processing..
                for k in range(0, self.numOutputUnits):
                    print("%s " %j[1][k].item(), file = outFile)

        outFile.close()

    def writeTrepanAttributesFile(self, trepanInputDescriptors, 
                                    trepanNominalInputValues = [], bNominalClassification = False, 
                                    nominalClassificationValues = []):
        """Write Trepan attributes definition file.

        Arguments:
            fileName {String} -- 
            The file name, inclusive of the extension ".attr".

            trepanInputDescriptors {List} -- 
            A list of monodimensional string arrays with two entries, 
            each monodimensional array represents an attribute.
            The first entry in the array is the name 
            and the second a letter defining the type of attribute 
            [N = nominal, R = real or B = boolean].
            Example: [[["firstInput", "N"], ["secondInput", "R"]] 

        Keyword Arguments:
            trepanNominalInputValues {List} -- 
            A list of monodiminsional int arrays with N entries,
            each monodimensional array contains the nominal values
            for the nominal attribute in trepanInputDescriptors,
            in the order those are defined. (default: {[]})

            bNominalClassification {bool} -- 
            Whether the classification attribute 
            should be nominal or boolean. (default: {False})

            nominalClassificationValues {List} -- 
            If bNominalClassification is True, 
            this argument should be provided as a list 
            of nominal classification values/names. (default: {[]})
            Example: ["Class1", "Class2", "Class3"]
        """
        # print(os.listdir())
        outFile = open("../examples/"+self.modelName+"_example/"+self.modelName + ".attr", 'w')

        currentNominalIndex = 0
        for inputDesc in enumerate(trepanInputDescriptors):
            print("%s " %inputDesc[1][0], end = '', file = outFile)
            print("%s " %inputDesc[1][1], end = '', file = outFile)
           
            if str(inputDesc[1][1]) == "N":
                for nominalValue in trepanNominalInputValues[currentNominalIndex]:
                        print("%s " %nominalValue, end = '', file = outFile)
                currentNominalIndex += 1
            
            # new line
            print('', file = outFile)

        if bNominalClassification:
            print("class N ", end = '', file = outFile)
            for nominalValue in nominalClassificationValues:
                print("%s " %nominalValue, end = '', file = outFile)
            # new line
            print('', file = outFile)
        else:
            print("class B", file = outFile)

        outFile.close()

    def writeTrepanAttributesValuesFile(self, trepanInputDescriptors, 
                                    trepanRealInputValues = [], 
                                    trepanInputValueDescriptors = [],
                                    bNominalClassification = False, 
                                    nominalClassificationValues = []):
        """Write Trepan attributes values definition file.

        Arguments:
            fileName {String} -- 
            The file name, inclusive of the extension ".attr".

            trepanInputDescriptors {List} -- 
            A list of monodimensional string arrays with two entries, 
            each monodimensional array represents an attribute.
            The first entry in the array is the name 
            and the second a letter defining the type of attribute 
            [N = nominal, R = real or B = boolean].
            Example: [[["firstInput", "N"], ["secondInput", "R"]] 

        Keyword Arguments:
            trepanRealInputValues {List} -- 
            A list of monodiminsional int arrays with N entries,
            each monodimensional array contains the min and max values 
            for the real attribute in trepanInputDescriptors,
            in the order those are defined. (default: {[]})

            trepanInputValueDescriptors {List} -- 
            A list of monodiminsional int arrays with N entries,
            each monodimensional array contains the categorical values 
            for the nominal attribute in trepanInputDescriptors,
            in the order those are defined. (default: {[]})

            bNominalClassification {bool} -- 
            Whether the classification attribute 
            should be nominal or boolean. (default: {False})

            nominalClassificationValues {List} -- 
            If bNominalClassification is True, 
            this argument should be provided as a list 
            of nominal classification values/names. (default: {[]})
            Example: ["Class1", "Class2", "Class3"]
        """

        
        outFile = open("../examples/"+self.modelName+"_example/"+self.modelName + ".attr.values", 'w')

        currenNomimalIndex = 0
        currentRealIndex = 0 

        for inputDesc in enumerate(trepanInputDescriptors):
            print("%s " %inputDesc[1][0], end = '', file = outFile)
            print("%s " %inputDesc[1][1], end = '', file = outFile)
            print("%s " %inputDesc[1][0], end = '', file = outFile)
           
            if str(inputDesc[1][1]) == "N":
                for nominalValue in trepanInputValueDescriptors[currenNomimalIndex]:
                        print(" %s" %nominalValue, end = '', file = outFile)
                currenNomimalIndex += 1
            
            if str(inputDesc[1][1]) == "R":
                for realValue in trepanRealInputValues[currentRealIndex]:
                        print(" %s" %realValue, end = '', file = outFile)
                currentRealIndex += 1
            
            # new line
            print('', file = outFile)

        if bNominalClassification:
            print("class N ", end = '', file = outFile)
            i = 0
            for nominalValue in nominalClassificationValues:
                print(" ("+str(i)+",%s)" %nominalValue, end = '', file = outFile)
                i+=1
            # new line
            print('', file = outFile)
        else:
            print("class B", file = outFile)

        outFile.close()

    def writeTrepanCommandFile(self, seed = 10, treeSizeLimit = 10, minSample = 5000):
        outFile = open("../"+self.modelName + ".cmd", 'w')
        print("get attributes %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".attr"), file = outFile)
        print("get attribute_values %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".attr.values"), file = outFile)
        print("get ontofilename %s" %("libs/"+self.modelName+"_ontology.owl"), file = outFile)
        print("get ontology %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".onto"), file = outFile)
        print("get training_examples %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".train.pat"), file = outFile)
        print("get test_examples %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".test.pat"), file = outFile)
        print("get network %s" %"examples/"+self.modelName+"_example/"+self.modelName, file = outFile)
        print("set use_ontology %s" %1, file = outFile)
        print("set seed %s" %seed, file = outFile)
        print("set tree_size_limit %s" %treeSizeLimit, file = outFile)
        print("set min_sample %s" %minSample, file = outFile)
        print("lo_mofn %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".fidelity"), file = outFile)
        print("test_fidelity", file = outFile)
        print("test_correctness", file = outFile)
        print("print_tree", file = outFile)
        # print("draw_tree %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".dot"), file = outFile)
        print("draw_tree_revisited %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".dot"), file = outFile)
        print("print_rules %s" %("examples/"+self.modelName+"_example/"+self.modelName + ".rules"), file = outFile)
        print("quit", file = outFile)
        outFile.close()

    def printWeights(self):
        print("\n>> Flatten Weights + Biases")
        print(self.flat_weights)

    def getLayerWeights(self, layerIndex):
        assert(layerIndex >= 0)
        if layerIndex < len(self.layers):
            return self.layers[layerIndex]
        else:
            return self.outputLayer

    def saveWeights(self):
         # concat weights
        for layer in self.layers:
            self.flat_weights = np.concatenate((self.flat_weights, layer.weight.tolist()), axis = None)

        self.flat_weights = np.concatenate((self.flat_weights, self.outputLayer.weight.tolist()), axis = None)
        
        # concat bias
        for layer in self.layers:
            self.flat_weights = np.concatenate((self.flat_weights, layer.bias.tolist()), axis = None)

        self.flat_weights = np.concatenate((self.flat_weights, self.outputLayer.bias.tolist()), axis = None)

        print("\n>> Writing Weights + Biases to file {}".format("../examples/"+self.modelName+"_example/"+str(self.modelName + ".wgt")))
        with open("../examples/"+self.modelName+"_example/"+self.modelName + ".wgt", 'w+') as weights_file:
            for weight in self.flat_weights:
                weights_file.write("%s\n" %weight)


class TrepadDatasetType:
    Train, Validation = range(2)