import os
import csv
from scipy.io import arff 
import pandas as pd
import numpy as np
from config import config_loan
from subprocess import call
from shutil import copyfile
# import torch
# from pytorchmodels import FeedForwardNetwork as FFN

class TrepanWrapper():

    def __init__(self, data_path, dataset, cross_validation_nr):
        super().__init__()

        self.data_path = data_path
        
        #base = loan-kt-num
        self.base = dataset
        # dataset = 'loan-kt-num'
        self.dataset = self.base+'.arff'
        # train_data = 'loan-kt-num.train.X.arff'
        self.train_data = self.base+'.train.X.arff'
        # test_data = 'loan-kt-num.test.X.arff'
        self.test_data = self.base+'.test.X.arff'
        # loan-kt-num.train.X.arff.RandomForest.model'
        self.model_name = self.train_data+'.RandomForest.model'
        self.cross_validation_nr = cross_validation_nr
        
    #end-def

    def writeTrepanAttributesFile(self, trepanInputDescriptors, 
                                    trepanNominalInputValues = [],  
                                    class_values = []):
            """Write Trepan attributes definition file.
            """
            # print(os.listdir())
            outFile = open("examples/"+self.base+"/"+self.base + ".attr", 'w')

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

            #class values
            print("class N ", end = '', file = outFile)
            for class_values in class_values:
                print("%s " %class_values, end = '', file = outFile)
            # new line
            print('', file = outFile)
            
            outFile.close()

    def writeTrepanAttributesValuesFile(self, trepanInputDescriptors, 
                                    trepanRealInputValues = [], 
                                    trepanInputValueDescriptors = [], 
                                    class_values = []):
        """Write Trepan attributes values definition file.
        """

        
        outFile = open("examples/"+self.base+"/"+self.base + ".attr.values", 'w')

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

       
        print("class N class ", end = '', file = outFile)
        i = 0
        for class_value in class_values:
            # print(" ("+str(i)+",%s)" %class_value, end = '', file = outFile)
            print(" ("+class_value+",class_is_"+str(i)+")", end = '', file = outFile)
            i+=1
        # new line
        print('', file = outFile)
        

        outFile.close()
    
    def writeTrepanDatasetFile(self, 
                              dataset_type, 
                              cross_fold_i, 
                              df, 
                              object_headers, 
                              float_headers, 
                              class_name):
        """ Write Trepan attribute files for a training or test set.
        """
        #base = loan-kt-num
        fileName = self.base
        if dataset_type == 0:
            fileName += ".train."+str(cross_fold_i)+".pat"
        elif dataset_type == 1:
            fileName += ".test."+str(cross_fold_i)+".pat"

        outFile = open("examples/"+self.base+"/"+fileName, 'w')

        for index, row in df.iterrows():

            print("p-%s " %index, end = '', file = outFile)

            for float_header in float_headers:
                print("%s " %row[float_header], end = '', file = outFile)
            
            for object_header in object_headers:
                
                if object_header != class_name:
                    print("%s " %int(row[object_header]), end = '', file = outFile)
                else:
                    # print("%s " %int(row[object_header]), file = outFile)
                    if row[object_header] == 1.0:
                        print("false ", file = outFile)
                    else:
                        print("true ", file = outFile)
        

        outFile.close()

    def writeTrepanCommandFile(self, cross_fold_i, seed = 10, treeSizeLimit = 8, minSample = 10):

        trained_model_name = self.model_name.replace('X',str(cross_fold_i))
        outFile = open("examples/"+self.base + "/"+self.base+"."+str(cross_fold_i)+".cmd", 'w')
        print("get attributes %s" %("examples/"+self.base+"/"+self.base + ".attr"), file = outFile)
        print("get attribute_values %s" %("examples/"+self.base+"/"+self.base + ".attr.values"), file = outFile)
        print("get model_name %s" %trained_model_name, file = outFile)
        # print("get ontofilename %s" %("libs/"+self.base+"_ontology.owl"), file = outFile)
        # print("get ontology %s" %("examples/"+self.base+"/"+self.base + ".onto"), file = outFile)
        print("get training_examples %s" %("examples/"+self.base+"/"+self.base + ".train."+str(cross_fold_i)+".pat"), file = outFile)
        print("get test_examples %s" %("examples/"+self.base+"/"+self.base + ".test."+str(cross_fold_i)+".pat"), file = outFile)
        # print("get network %s" %"examples/"+self.base+"/"+self.base + ".net", file = outFile)
        print("set use_ontology %s" %0, file = outFile)
        print("set seed %s" %seed, file = outFile)
        print("set tree_size_limit %s" %treeSizeLimit, file = outFile)
        print("set min_sample %s" %minSample, file = outFile)
        print("lo_mofn %s" %("examples/"+self.base+"/"+self.base +"."+str(cross_fold_i)+".fidelity"), file = outFile)
        print("test_fidelity", file = outFile)
        print("test_correctness", file = outFile)
        print("print_tree", file = outFile)
        print("draw_tree_revisited %s" %("examples/"+self.base+"/"+self.base + "."+str(cross_fold_i)+".dot"), file = outFile)
        # print("draw_tree %s" %("examples/"+self.base+"/"+self.base + ".dot"), file = outFile)
        # print("print_rules %s" %("examples/"+self.base+"/"+self.base + ".rules"), file = outFile)
        print("quit", file = outFile)
        outFile.close()

    def generate_trepan_input_descriptors_and_nominals(self, float_headers,
                                                    object_headers,
                                                    class_name,
                                                    nominal_values_mapping,
                                                    real_values_mapping):
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

            if (real_values_mapping !=  None): 
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

                if (nominal_values_mapping != None):
                    nominal_values = nominal_values_mapping[object_header]
                    for key, value in nominal_values.items(): 
                        trepan_nominal_input_value.append(value)
                        # trepan_real_input_value.append('(min,'+str(min_value)+') (max,'+str(max_value)+')')
                        # dependents N   dependents (0,dependents_is_0) (1,dependents_is_1) (2,dependents_is_2) (3,dependents_is_3+)
                        trepan_input_value_descriptor.append('('+str(value)+','+object_header+'_is_'+str(key)+')')
                    trepan_nominal_input_values.append(trepan_nominal_input_value)
                    trepan_input_value_descriptors.append(trepan_input_value_descriptor)

        # print (trepan_input_descriptors) 
        # print (trepan_nominal_input_values)
        # print (trepan_real_input_values)
        # print (trepan_input_value_descriptors)

        return trepan_input_descriptors, trepan_nominal_input_values, trepan_real_input_values, trepan_input_value_descriptors
    #end-def

    def generate_nominals_trepan_values(self, df):
    
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
        print (cleanup_nums)
        
        return cleanup_nums
    #end-def

    def generate_real_values_mapping(self,df):
        '''Normalising and generating real values mapping'''
        
        # print("Normalising real values...")
        
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

    def convert_column(self, dataset, df, df_train_i, df_test_i):

        # using dictionary to convert specific columns 
        if ('r1' in dataset):
            convert_dict = {
                            'Gender': int, 
                            'Married' : int,
                            'Dependents': int,
                            'Education': int,
                            'Self_Employed': int,
                            'ApplicantIncome': float,
                            'CoapplicantIncome': float,
                            'LoanAmount': float,
                            'Loan_Amount_Term': int,
                            # 'Credit_History': int,
                            'Property_Area': int,
                            'Loan_Status': int
                    }
        elif ('r2' in dataset):
            convert_dict = {
                            # 'Gender': int, 
                            'Married' : int,
                            'Dependents': int,
                            'Education': int,
                            'Self_Employed': int,
                            'ApplicantIncome': float,
                            'CoapplicantIncome': float,
                            'LoanAmount': float,
                            'Loan_Amount_Term': int,
                            # 'Credit_History': int,
                            'Property_Area': int,
                            'Loan_Status': int
                    }
        else:
           convert_dict = {
                            'Gender': int, 
                            'Married' : int,
                            'Dependents': int,
                            'Education': int,
                            'Self_Employed': int,
                            'ApplicantIncome': float,
                            'CoapplicantIncome': float,
                            'LoanAmount': float,
                            'Loan_Amount_Term': int,
                            'Credit_History': int,
                            'Property_Area': int,
                            'Loan_Status': int
                    } 
        
        df = df.astype(convert_dict) 
        df_train_i = df_train_i.astype(convert_dict) 
        df_test_i = df_test_i.astype(convert_dict) 

        if ('r1' in dataset):
            convert_dict = {
                        'Gender': object, 
                        'Married' : object,
                        'Dependents': object,
                        'Education': object,
                        'Self_Employed': object,
                        'ApplicantIncome': float,
                        'CoapplicantIncome': float,
                        'LoanAmount': float,
                        'Loan_Amount_Term': object,
                        # 'Credit_History': object,
                        'Property_Area': object,
                        'Loan_Status': object
                } 
        elif ('r2' in dataset):
            convert_dict = {
                        # 'Gender': object, 
                        'Married' : object,
                        'Dependents': object,
                        'Education': object,
                        'Self_Employed': object,
                        'ApplicantIncome': float,
                        'CoapplicantIncome': float,
                        'LoanAmount': float,
                        'Loan_Amount_Term': object,
                        # 'Credit_History': object,
                        'Property_Area': object,
                        'Loan_Status': object
                } 
        else:
           convert_dict = {
                        'Gender': object, 
                        'Married' : object,
                        'Dependents': object,
                        'Education': object,
                        'Self_Employed': object,
                        'ApplicantIncome': float,
                        'CoapplicantIncome': float,
                        'LoanAmount': float,
                        'Loan_Amount_Term': object,
                        'Credit_History': object,
                        'Property_Area': object,
                        'Loan_Status': object
                } 

        #convert to the above types
        df = df.astype(convert_dict) 
        df_train_i = df_train_i.astype(convert_dict) 
        df_test_i = df_test_i.astype(convert_dict) 

        return df, df_train_i, df_test_i

    #end-def

    def generate_trepan_inputs(self, class_name, class_nr=2):
        
        path_to_dataset = arff.loadarff(self.data_path+'/'+self.dataset)
        df = pd.DataFrame(path_to_dataset[0])
        df.replace({b'1.0': '1', b'2.0': '2'},inplace=True)

        for cross_fold_i in range(self.cross_validation_nr):

            train_data_i = self.train_data.replace('X',str(cross_fold_i))
            test_data_i = self.test_data.replace('X',str(cross_fold_i))

            train_data_i = arff.loadarff(self.data_path+'/'+train_data_i)
            test_data_i = arff.loadarff(self.data_path+'/'+test_data_i)
            
            df_train_i = pd.DataFrame(train_data_i[0])
            df_test_i = pd.DataFrame(test_data_i[0])

            # labels = df[[class_name]]
            df_train_i.replace({b'1.0': '1', b'2.0': '2'},inplace=True)
            df_test_i.replace({b'1.0': '1', b'2.0': '2'},inplace=True)
            
            df, df_train_i, df_test_i = self.convert_column(self.base, df, df_train_i, df_test_i)
            # print(df.dtypes) 
            # print(df_train.dtypes) 
            # print(df_test.dtypes) 

            nominal_values_mapping = self.generate_nominals_trepan_values(df)
            #converting nominals to the type trepan likes
            
            nominal_values_mapping_copy = nominal_values_mapping.copy()
            df_train_i.replace(nominal_values_mapping_copy, inplace=True)
            df_test_i.replace(nominal_values_mapping_copy, inplace=True)

            _ , real_values_mapping = self.generate_real_values_mapping(df)

            # specify input types and their nominal values (optionally) 
            obj_df = df.select_dtypes(include=['object']).copy()
            object_headers = obj_df.columns.values.tolist()

            flat_df = df.select_dtypes(include=['float64']).copy()
            float_headers = flat_df.columns.values.tolist()

            trepan_input_descriptors, trepan_nominal_input_values, trepan_real_input_values, trepan_input_value_descriptors = self.generate_trepan_input_descriptors_and_nominals(float_headers,object_headers,class_name,
                                                                                            nominal_values_mapping,real_values_mapping)
            # # trepanInputDescriptors = [["applicant_income", "R"], ["coapplicant_income", "R"], ["loan_amount", "R"], ["loan_amount_term", "R"],
                                    #   ["gender", "N"], ["married", "N"], ["dependents", "N"], ["education", "N"], ["self_employed", "N"], 
                                    #   ["credit_history", "N"], ["property_area", "N"]]
            # trepanNominalInputValues = [[0,1], [0,1], [0,1,2,3], [0,1], [0,1], [0,1], [0,1,2]]
            # trepanRealInputValues = [[(min,0),(max,1)], [(min,0),(max,1)], [(min,0),(max,1)], [(min,0),(max,1)]]
            # trepanInputDescriptors = trepan_input_descriptors
            # trepanNominalInputValues = trepan_nominal_input_values

            # write the .attr file for Trepan
            #['false','true']
            # class_values = [1,2]
            # // 1.0 is False
            # // 2.0 is true
            self.writeTrepanAttributesFile(trepan_input_descriptors, trepan_nominal_input_values, ['false', 'true'])
            # write the .attr.values file for Trepan
            self.writeTrepanAttributesValuesFile(trepan_input_descriptors, trepan_real_input_values, trepan_input_value_descriptors, ['false', 'true'])
            # write the .train.pat file for Trepan
            self.writeTrepanDatasetFile(0, cross_fold_i, df_train_i, object_headers, float_headers, class_name)
            # write the .test.pat file for Trepan
            self.writeTrepanDatasetFile(1, cross_fold_i, df_test_i, object_headers, float_headers, class_name)
            
            # # write the .cmd file for Trepan
            self.writeTrepanCommandFile(cross_fold_i)

        print("\n>> Done.")
        
    #def 

    def run_cross_validation(self, writer):
        
        internal_nodes = train_fidelity = train_accuracy = test_fidelity = test_accuracy = 0.0
        leaves_nr = compr_m1 = branches_nr = compr_m2 = 0.0

        for cross_fold_i in range(self.cross_validation_nr):

            filename = self.base+"."+str(cross_fold_i)
            command_file = "examples/"+self.base + "/"+filename+".cmd"
            call(["./trepan_reloaded", command_file])

            #parse results and create mean
            dict_to_write = {}
            with open("examples/"+self.base+"/"+filename+".fidelity.pruned", 'r') as f:
                lines = f.read().splitlines()
                last_line = lines[-1]
                vals = last_line.split("\t")
                internal_nodes += float(vals[0])
                train_fidelity += float(vals[1])
                train_accuracy += float(vals[2])
                test_fidelity += float(vals[3])
                test_accuracy += float(vals[4])
                leaves_nr += float(vals[5])
                compr_m1 += float(vals[6])
                branches_nr += float(vals[7])
                compr_m2 += float(vals[8])
            #end-with
        #end-for
        dict_to_write['dataset'] = self.dataset
        dict_to_write['crossval_nr'] = self.cross_validation_nr
        dict_to_write['internal_nodes'] = internal_nodes/self.cross_validation_nr
        dict_to_write['train_fidelity'] = train_fidelity/self.cross_validation_nr
        dict_to_write['train_accuracy'] = train_accuracy/self.cross_validation_nr
        dict_to_write['test_fidelity'] = test_fidelity/self.cross_validation_nr
        dict_to_write['test_accuracy'] = test_accuracy/self.cross_validation_nr
        dict_to_write['leaves_nr'] = leaves_nr/self.cross_validation_nr
        dict_to_write['compr_m1'] = compr_m1/self.cross_validation_nr
        dict_to_write['branches_nr'] = branches_nr/self.cross_validation_nr
        dict_to_write['compr_m2'] = compr_m2/self.cross_validation_nr
        writer.writerow(dict_to_write)
    #end-def


def main():
    """generate results with 'cross-validation' """
    
    # model_name = 'loan'
    tree_sizes = [10]
    use_ontology = [0]
    cross_validation_nr = config_loan['cross_validation_nr']
    use_case = config_loan['use_case']
    datasets = config_loan['datasets']
    data_path = config_loan['data_path']
    class_label = config_loan['class_label']

        
    if not os.path.exists("results/"+use_case):
        os.makedirs("results/"+use_case)

    with open("results/"+use_case+"/"+use_case+"_tree_data.csv", mode="a") as csv_file: 
        fieldnames = ['dataset', 'crossval_nr', 'internal_nodes', 'train_fidelity', 'train_accuracy', 'test_fidelity', 'test_accuracy', 'leaves_nr', 'compr_m1', 'branches_nr', 'compr_m2']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        
        for dataset in datasets:
            if not os.path.exists("examples/"+dataset):
                os.makedirs("examples/"+dataset)
        
            trepanWrapper = TrepanWrapper(data_path, dataset, cross_validation_nr)
            trepanWrapper.generate_trepan_inputs(class_label)
            trepanWrapper.run_cross_validation(writer)
             
    #end-with     
#end-def

main()