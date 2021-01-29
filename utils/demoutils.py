import torch
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
from pytorchmodels import FeedForwardNetwork as FFN
import numpy as np
import pandas as pd
import sys, os
from sklearn import preprocessing

import pickle


def binary_conversion(df):
    """Converts nominal values to binary encoding"""
    
    print("Converting nomimals to binary encoding...")
    headers = df.columns.values.tolist()
    print (df.info())
    #NOTE: at this point all nominals are of type np.int64  
    for header in headers:
        if (df[header].dtype == np.int64):
            df = pd.get_dummies(df, columns=[header])
    return df
#end-def


def clean_data(df,unwanted_columns):
    """Cleaning data and replacing missing values by most frequent and mean values"""
    print (df.info())
    # print ('Missing values: ')
    # print (df.isnull().sum())
    headers = df.columns.values.tolist()
    
    if df.isnull().any().any():
        print ('Replacing missing values..')
        for header in headers:
            if (df[header].isnull().sum()>0):
                print('Percent of missing '+header+' records was %.2f%%' %((df[header].isnull().sum()/df.shape[0])*100))
                if (df[header].dtype == np.float64 or df[header].dtype == np.int64):
                    df[header].fillna(df[header].mean(skipna=True), inplace=True)
                    # print('missing '+header+' records replaced with mean') 
                elif (df[header].dtype == np.object):
                    df[header].fillna(df[header].value_counts().idxmax(), inplace=True)  
                    # print('missing '+header+' records replaced with most common value')
        print ('Replacing missing values..DONE')
    else:
        print ('No missing values in dataset..')

    # labels = df[[class_name]]
    # unwanted_columns.append(class_name)
    
    return df.drop(unwanted_columns,1)
#end-def

def normalize_real_values(df):
    '''Normalizing real values to the range [0,1]'''
    
    print("Normalising real values...")
    
    headers = df.columns.values.tolist()
    data_normalized = df.copy()
    real_values_mapping = {}
    for header in headers:
        if (df[header].dtype == np.float64 or df[header].dtype == np.int64):
            max_value = df[header].max()
            min_value = df[header].min()
            data_normalized[header] = (df[header] - min_value) / (max_value - min_value)
            real_values_mapping[header] = {'min':min_value,'max':max_value}

    return data_normalized, real_values_mapping 
#end-def

def replace_categories_with_values(df, class_name):
    """Columns with type object are replaced using 0,1,2 labels"""
    
    #inspired by http://pbpython.com/categorical-encoding.html
   
    print("Converting categories to 0,1,2...,etc. labels...")
    headers = df.columns.values.tolist()
    data_without_objects = df.copy()
    cleanup_nums = {}
    for header in headers:
        if (df[header].dtype == np.object): 
            # print ('Values for '+header+' are:')
            values = df[header].unique()
            
            # print (values)
            cat_values = {}
            cat_id = 0
            
            for value in values:
                cat_values[value] = cat_id
                cat_id += 1
            #end-for
            # print (cat_values)
            cleanup_nums[header] = cat_values
        #end-if
    #end-for   
    # print (cleanup_nums)


    data_without_objects.replace(cleanup_nums, inplace=True)

    labels = data_without_objects[[class_name]]
    data_without_objects = data_without_objects.drop([class_name],1)
    
    return data_without_objects, labels, cleanup_nums
#end-def

def create_tensors(df_dataset,df_labels):
    """Convert DataFrame to Tensor"""

    # print (df_labels.info())
     # converting data frame to numpy array
    np_data = df_dataset.as_matrix()
    np_labels = df_labels.as_matrix()
    # converting numpy to tensor now
    data_torch = torch.from_numpy(np_data).type(torch.FloatTensor)
    labels_torch = torch.from_numpy(np_labels).type(torch.FloatTensor)
    # labels_torch = torch.from_numpy(np_labels).type(torch.FloatTensor)

    return zip(data_torch,labels_torch)
#end-def

def generate_trepan_input_descriptors_and_nominals(float_headers,object_headers,class_name,nominal_values_mapping,real_values_mapping):
    """Creates all structures needed to create trepan descriptors files (.attr) and (.attr.values)"""
    trepan_input_descriptors = []
    trepan_input_value_descriptors = []
    trepan_nominal_input_values = []
    trepan_real_input_values = []

    for float_header in float_headers:
        trepan_input_descriptor = []
        trepan_real_input_value = []
        trepan_input_descriptor.append(float_header)
        trepan_input_descriptor.append("R")
        trepan_input_descriptors.append(trepan_input_descriptor)

        min_value = real_values_mapping[float_header]['min']
        max_value = real_values_mapping[float_header]['max']
        trepan_real_input_value.append('(min,'+str(min_value)+')')
        trepan_real_input_value.append('(max,'+str(max_value)+')')
        trepan_real_input_values.append(trepan_real_input_value)

    for object_header in object_headers:

        if object_header != class_name :
            trepan_input_descriptor = []
            trepan_nominal_input_value = []
            trepan_input_value_descriptor = []
            trepan_input_descriptor.append(object_header)
            trepan_input_descriptor.append("N")
            trepan_input_descriptors.append(trepan_input_descriptor)

            nominal_values = nominal_values_mapping[object_header]
            for key, value in nominal_values.items(): 
                trepan_nominal_input_value.append(value)
                # trepan_real_input_value.append('(min,'+str(min_value)+') (max,'+str(max_value)+')')
                # dependents N   dependents (0,dependents_is_0) (1,dependents_is_1) (2,dependents_is_2) (3,dependents_is_3+)
                trepan_input_value_descriptor.append('('+str(value)+','+object_header+'_is_'+key+')')
            trepan_nominal_input_values.append(trepan_nominal_input_value)
            trepan_input_value_descriptors.append(trepan_input_value_descriptor)

    # print (trepan_input_descriptors) 
    # print (trepan_nominal_input_values)
    # print (trepan_real_input_values)
    # print (trepan_input_value_descriptors)

    return trepan_input_descriptors, trepan_nominal_input_values, trepan_real_input_values, trepan_input_value_descriptors
#end-def

#-----------------
#SCRIPT START HERE
# NOTE: assuming to have column headers in the data

def generate_trepan_network(fname,sep,unwanted_columns,class_name,class_nr):

    # unwanted_columns = ['step']
    # class_name = 'isFraud'
    MAX_ROWS = 5000
    # alpha = 1
    
    df = pd.read_csv('datasets/'+fname+'.csv',sep=sep)
    
    print ('num_samples is '+str(df.shape[0]))
    
    num_samples = df.shape[0]
    # print ('num_samples '+str(num_samples))
    if (num_samples > MAX_ROWS):
        df = df.sample(n=MAX_ROWS, random_state=1)
        df = df.to_csv('datasets/'+fname+'-new.csv', sep=sep, index=False)
        df = pd.read_csv('datasets/'+fname+'-new.csv',sep=sep)
    
    num_samples = df.shape[0]
    print ('num_samples after cutting is '+str(df.shape[0]))

    # print (df.info())
    # print (df.shape)

    #Mathews.Sample Size Calculations:  Practical Methods for Engineers and Scientists.Mathews Malnar and Bailey, Incorporated, 2
    # if (df.shape[0]>MAX_ROWS)

    # sys.exit(-1)

    df_no_missing_values = clean_data(df,unwanted_columns)
    df_normalized, real_values_mapping = normalize_real_values(df_no_missing_values)
   
    df_without_objects, labels, nominal_values_mapping = replace_categories_with_values(df_normalized, class_name)
    # print (df_without_objects.info())
    # print (df_without_objects.head(3))
    class_names = labels[class_name].unique()

    df_with_binary_encoding = binary_conversion(df_without_objects)
    # labels_with_binary_encoding = binary_conversion(labels)
    # print (df_with_binary_encoding.info())
    # print (df_with_binary_encoding.head(3))

    # df_labels_with_binary_encoding = binary_conversion(labels)
    data_set_tensor = create_tensors(df_with_binary_encoding,labels)
    
    # create FFN model on CPU
    # modelName, numInputUnits, numHiddenLayers, numHiddenLayersUnits, numOutputUnits
    num_input_units = df_with_binary_encoding.shape[1]
    if class_nr < 3:
        num_output_units = labels.shape[1]
    else:
        num_output_units = class_nr

    #Nh=Ns/(alpha(Ni+No))
    # num_hidden_neurons = (int) (num_samples/(alpha*(num_input_units+num_output_units)))
    # print ("num_samples "+str(num_samples))
    print ("num_hidden_neurons "+str(num_input_units+num_output_units))
    network = FFN.FeedForwardNetwork(fname, num_input_units, 1, [num_input_units+num_output_units], num_output_units)

    # create training and validation datasets 
    data_set_tensor_list = list(data_set_tensor)
    
    print ('Num_samples: '+str(num_samples))
    train_size = (int) (num_samples*0.8)
   
    # test_size = num_samples-train_size
    trainingSet = data_set_tensor_list[:train_size+1] 
    print ('Training set size: '+str(len(trainingSet)))
    # print (trainingSet)
    validationSet = data_set_tensor_list[train_size+1:] 
    print ('ValidationSet set size: '+str(len(validationSet)))
    # print (validationSet)

    # write the .net file for Trepan
    network.writeTrepanNetFile()
    # specify input types and their nominal values (optionally) 
    obj_df = df_no_missing_values.select_dtypes(include=['object']).copy()
    object_headers = obj_df.columns.values.tolist()

    flat_df = df_with_binary_encoding.select_dtypes(include=['float64']).copy()
    float_headers = flat_df.columns.values.tolist()

    trepan_input_descriptors, trepan_nominal_input_values, trepan_real_input_values, trepan_input_value_descriptors = generate_trepan_input_descriptors_and_nominals(float_headers,object_headers,class_name,
                                                                                    nominal_values_mapping,real_values_mapping)
    # trepanInputDescriptors = [["applicant_income", "R"], ["coapplicant_income", "R"], ["loan_amount", "R"], ["loan_amount_term", "R"],
                            #   ["gender", "N"], ["married", "N"], ["dependents", "N"], ["education", "N"], ["self_employed", "N"], 
                            #   ["credit_history", "N"], ["property_area", "N"]]
    # trepanNominalInputValues = [[0,1], [0,1], [0,1,2,3], [0,1], [0,1], [0,1], [0,1,2]]
    # trepanRealInputValues = [[(min,0),(max,1)], [(min,0),(max,1)], [(min,0),(max,1)], [(min,0),(max,1)]]
    trepanInputDescriptors = trepan_input_descriptors
    trepanNominalInputValues = trepan_nominal_input_values

    # write the .attr file for Trepan
    if class_nr < 3:
        network.writeTrepanAttributesFile(trepanInputDescriptors, trepanNominalInputValues, True, ['false','true'])
        # write the .attr.values file for Trepan
        network.writeTrepanAttributesValuesFile(trepanInputDescriptors, trepan_real_input_values, trepan_input_value_descriptors, True, ['false','true'])
        # write the .train.pat file for Trepan
        network.writeTrepanDatasetFile(0, trainingSet, trepanInputDescriptors, trepanNominalInputValues, True)
        # write the .test.pat file for Trepan
        network.writeTrepanDatasetFile(1, validationSet, trepanInputDescriptors, trepanNominalInputValues, True)
    else:
        network.writeTrepanAttributesFile(trepanInputDescriptors, trepanNominalInputValues, True, class_names)
        # write the .attr.values file for Trepan
        network.writeTrepanAttributesValuesFile(trepanInputDescriptors, trepan_real_input_values, trepan_input_value_descriptors, True, class_names)
        # write the .train.pat file for Trepan
        network.writeTrepanDatasetFile(0, trainingSet, trepanInputDescriptors, trepanNominalInputValues, False)
        # write the .test.pat file for Trepan
        network.writeTrepanDatasetFile(1, validationSet, trepanInputDescriptors, trepanNominalInputValues, False)
    
    # write the .cmd file for Trepan
    network.writeTrepanCommandFile()
    
    # sys.exit(-1)

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

#end-def


