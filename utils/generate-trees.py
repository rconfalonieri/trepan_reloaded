import os
from random import seed
from random import randint
from subprocess import call
from shutil import copyfile
from graphviz import Source
from pathlib import Path
import csv
import sys

# SELECTION_BEST_TREE_CRITERION = 'accuracy'
SELECTION_BEST_TREE_CRITERION = 'fidelity'
RUNS = 20
RATIO = 2
PERCENTAGE = 0.2


def writeTrepanCommandFile(modelName, seed, treeSizeLimit, ontology, minSample = 5000):
        outFile = open(modelName + ".cmd", 'w')
        print("get attributes %s" %("examples/"+modelName+"_example/"+modelName + ".attr"), file = outFile)
        print("get attribute_values %s" %("examples/"+modelName+"_example/"+modelName + ".attr.values"), file = outFile)
        print("get ontofilename %s" %("libs/"+modelName+"_ontology.owl"), file = outFile)
        print("get ontology %s" %("examples/"+modelName+"_example/"+modelName + ".onto"), file = outFile)
        print("get training_examples %s" %("examples/"+modelName+"_example/"+modelName + ".train.pat"), file = outFile)
        print("get test_examples %s" %("examples/"+modelName+"_example/"+modelName + ".test.pat"), file = outFile)
        print("get network %s" %"examples/"+modelName+"_example/"+modelName, file = outFile)
        print("set use_ontology %s" %ontology, file = outFile)
        print("set seed %s" %seed, file = outFile)
        print("set tree_size_limit %s" %treeSizeLimit, file = outFile)
        print("set min_sample %s" %minSample, file = outFile)
        print("lo_mofn %s" %("examples/"+modelName+"_example/"+modelName + ".fidelity"), file = outFile)
        print("test_fidelity", file = outFile)
        print("test_correctness", file = outFile)
        # print("print_tree", file = outFile)
        # print("draw_tree %s" %("examples/"+modelName+"_example/"+modelName + ".dot"), file = outFile)
        print("draw_tree_revisited %s" %("examples/"+modelName+"_example/"+modelName + ".dot"), file = outFile)
        print("quit", file = outFile)
        outFile.close()
        return modelName+".cmd"


def collectAndGenerateResults(id, writer, best_tree_file_name, modelName, treeSizeLimit, ontology):
    """Copies trepan result files in survey folder """
    
    fileName = best_tree_file_name
    dict_to_write = {}
    
    dict_to_write['id'] = id
    dict_to_write['filename'] = best_tree_file_name+".png"
    dict_to_write['tree_size_limit'] = treeSizeLimit
    dict_to_write['ontology'] = ontology
    # dict_to_write['seed'] = seed

    dot_file = "examples/survey/"+modelName+"/"+best_tree_file_name+".dot"
    rule_file = "examples/survey/"+modelName+"/"+best_tree_file_name+".rules"
    fidelity_file = "examples/survey/"+modelName+"/"+best_tree_file_name+".fidelity"
    fidelity_file_pruned = "examples/survey/"+modelName+"/"+best_tree_file_name+".fidelity.pruned" 
    ontology_file = "examples/survey/"+modelName+"/"+best_tree_file_name+".onto"
    trepan_file = "examples/survey/"+modelName+"/"+best_tree_file_name+".cmd" 
    
    copyfile("/tmp/"+best_tree_file_name+".dot", dot_file)
    copyfile("/tmp/"+best_tree_file_name+".rules", rule_file)
    copyfile("/tmp/"+best_tree_file_name+".fidelity", fidelity_file)
    copyfile("/tmp/"+best_tree_file_name+".fidelity.pruned", fidelity_file_pruned)
    copyfile("/tmp/"+best_tree_file_name+".onto", ontology_file)
    copyfile("/tmp/"+best_tree_file_name+".cmd", trepan_file)
    
    dot_file = "examples/survey/"+modelName+"/"+fileName+".dot"
    fidelity_file = "examples/survey/"+modelName+"/"+fileName+".fidelity"
    # pruned_nodes_file = "examples/survey/"+modelName+"/"+fileName+".pruned.nodes"
    # ontology_file = "examples/survey/"+modelName+"/"+fileName+".onto"
    # trepan_file = "examples/survey/"+modelName+"/"+fileName+".cmd"

    with open(fidelity_file_pruned, 'r') as f:
        lines = f.read().splitlines()
        last_line = lines[-1]
        # print (last_line)
        vals = last_line.split("\t")
        dict_to_write['internal_nodes'] = vals[0]
        dict_to_write['train_fidelity'] = vals[1]
        dict_to_write['train_accuracy'] = vals[2]
        dict_to_write['test_fidelity'] = vals[3]
        dict_to_write['test_accuracy'] = vals[4]
        dict_to_write['leaves_nr'] = vals[5]
        dict_to_write['compr_m1'] = vals[6]
        dict_to_write['branches_nr'] = vals[7]
        dict_to_write['compr_m2'] = vals[8]
        
        writer.writerow(dict_to_write)
        s = Source.from_file(dot_file, format="png")
        # s.view()
        s.render()
    
#end-def

# def isGoodTree(treeSizeLimit, ontology, internal_nodes):


#     good_tree = False
#     if (ontology == 0):
#         if (internal_nodes >= (treeSizeLimit/RATIO)) and (internal_nodes <= treeSizeLimit):
            
#             print (treeSizeLimit/RATIO)
#             good_tree = True
#     if (ontology == 1):

#         print (treeSizeLimit*PERCENTAGE)
#         print (treeSizeLimit/RATIO)

#         if (internal_nodes >= (treeSizeLimit*PERCENTAGE)) and (internal_nodes <= (treeSizeLimit/RATIO)):
#             good_tree = True
    
#     return good_tree
# #end-def

def isGoodTreeSameSize(treeSizeLimit, internal_nodes, ontology):
    
    good_tree = False
    # if (internal_nodes >= (treeSizeLimit * PERCENTAGE)) and (internal_nodes <= (treeSizeLimit / RATIO)):
    #     good_tree = True
    # if treeSizeLimit == 6:
    #     if (ontology == 0):
    #         if (internal_nodes >= treeSizeLimit-1) and (internal_nodes <= treeSizeLimit+5):
    #             good_tree = True
    #     elif ontology == 1:
    #         if (internal_nodes >= treeSizeLimit-4) and (internal_nodes <= treeSizeLimit-3):
    #             good_tree = True
    if (internal_nodes >= treeSizeLimit-4) and (internal_nodes <= treeSizeLimit):
            good_tree = True
    return good_tree
#end-def

def sampleDecisionTrees(runs, modelName, treeSizeLimit, ontology):
 
    best_tree_accuracy = -1.0
    best_tree_fidelity = -1.0
    best_tree_name = ''
    
    for i in range(0,runs):

        good_tree = False
        while (not good_tree):

            seed = randint(1,50)
            trepanCommandFile = writeTrepanCommandFile(modelName, seed, treeSizeLimit, ontology)
            call(["./trepan", trepanCommandFile])
            
            fileName = modelName+"_"+str(treeSizeLimit)+"_"+str(ontology)+"_"+str(seed)

            dot_file = "/tmp/"+fileName+".dot"
            rule_file = "/tmp/"+fileName+".rules"
            fidelity_file = "/tmp/"+fileName+".fidelity"
            fidelity_file_pruned = "/tmp/"+fileName+".fidelity.pruned"
            # pruned_nodes_file = "examples/survey/"+modelName+"/"+fileName+".pruned.nodes"
            ontology_file = "/tmp/"+fileName+".onto"
            trepan_file = "/tmp/"+fileName+".cmd"

            copyfile(modelName + ".cmd", trepan_file)
            copyfile("examples/"+modelName+"_example/"+modelName+".dot", dot_file)
            copyfile("examples/"+modelName+"_example/"+modelName+".rules", rule_file)
            copyfile("examples/"+modelName+"_example/"+modelName+".fidelity", fidelity_file)
            copyfile("examples/"+modelName+"_example/"+modelName+".fidelity.pruned", fidelity_file_pruned)
            copyfile("examples/"+modelName+"_example/"+modelName+".onto", ontology_file)

            dict_to_write = {}
            with open("examples/"+modelName+"_example/"+modelName+".fidelity.pruned", 'r') as f:
                lines = f.read().splitlines()
                last_line = lines[-1]
                # print (last_line)
                vals = last_line.split("\t")
                dict_to_write['internal_nodes'] = vals[0]
                print ("INTERNAL NODES ARE "+dict_to_write['internal_nodes'])
                dict_to_write['train_fidelity'] = vals[1]
                dict_to_write['train_accuracy'] = vals[2]
                dict_to_write['test_fidelity'] = vals[3]
                dict_to_write['test_accuracy'] = vals[4]
                dict_to_write['leaves_nr'] = vals[5]
                dict_to_write['compr_m1'] = vals[6]
                dict_to_write['branches_nr'] = vals[7]
                dict_to_write['compr_m2'] = vals[8]
            
            # good_tree = isGoodTree(treeSizeLimit, ontology, int(dict_to_write['internal_nodes']))
            good_tree = isGoodTreeSameSize(treeSizeLimit, int(dict_to_write['internal_nodes']), ontology)
            
            if (good_tree):

                if SELECTION_BEST_TREE_CRITERION == 'accuracy':
                    if float(dict_to_write['test_accuracy']) > best_tree_accuracy:
                        
                        # if (best_tree_name != '' and best_tree_name != fileName):
                            
                        #     best_tree_dot_file = "examples/survey/"+modelName+"/"+best_tree_name+".dot"
                        #     best_tree_fidelity_file = "examples/survey/"+modelName+"/"+best_tree_name+".fidelity"
                        #     best_tree_ontology_file = "examples/survey/"+modelName+"/"+best_tree_name+".onto"
                        #     best_tree_trepan_file = "examples/survey/"+modelName+"/"+best_tree_name+".cmd"
                            
                        #     os.remove(best_tree_dot_file)
                        #     os.remove(best_tree_fidelity_file)
                        #     os.remove(best_tree_ontology_file)
                        #     os.remove(best_tree_trepan_file)

                        best_tree_name = fileName
                        best_tree_accuracy = float(dict_to_write['test_accuracy'])
                    
                if SELECTION_BEST_TREE_CRITERION == 'fidelity':
                    if float(dict_to_write['test_fidelity']) > best_tree_fidelity:

                        # if (best_tree_name != '' and best_tree_name != fileName):
                            
                        #     best_tree_dot_file = "examples/survey/"+modelName+"/"+best_tree_name+".dot"
                        #     best_tree_fidelity_file = "examples/survey/"+modelName+"/"+best_tree_name+".fidelity"
                        #     best_tree_ontology_file = "examples/survey/"+modelName+"/"+best_tree_name+".onto"
                        #     best_tree_trepan_file = "examples/survey/"+modelName+"/"+best_tree_name+".cmd"
                            
                        #     os.remove(best_tree_dot_file)
                        #     os.remove(best_tree_fidelity_file)
                        #     os.remove(best_tree_ontology_file)
                        #     os.remove(best_tree_trepan_file)
                        
                        best_tree_name = fileName
                        best_tree_fidelity = float(dict_to_write['test_fidelity'])
                
            else:
                print ('Not good tree generated trying again...')
                if (fileName != best_tree_name):
                    os.remove(trepan_file)
                    os.remove(dot_file)
                    os.remove(rule_file)
                    os.remove(fidelity_file)
                    os.remove(ontology_file)
        #end-while
    #end-for
    return best_tree_name
#end-def

# def sampleAndCollectDecisionTreesData(runs, writer, modelName, treeSizeLimit, ontology):
 
    
#     for i in range(0,runs):

#         good_tree = False
#         while (not good_tree):

#             seed = randint(1,100)
#             trepanCommandFile = writeTrepanCommandFile(modelName, seed, treeSizeLimit, ontology)
#             call(["./trepan", trepanCommandFile])
            
#             fileName = modelName+"_"+str(treeSizeLimit)+"_"+str(ontology)+"_"+str(seed)

#             dot_file = "/tmp/"+fileName+".dot"
#             fidelity_file = "/tmp/"+fileName+".fidelity"
#             fidelity_file_pruned = "/tmp/"+fileName+".fidelity.pruned"
#             # pruned_nodes_file = "examples/survey/"+modelName+"/"+fileName+".pruned.nodes"
#             ontology_file = "/tmp/"+fileName+".onto"
#             trepan_file = "/tmp/"+fileName+".cmd"

#             copyfile(modelName + ".cmd", trepan_file)
#             copyfile("examples/"+modelName+"_example/"+modelName+".dot", dot_file)
#             copyfile("examples/"+modelName+"_example/"+modelName+".fidelity", fidelity_file)
#             copyfile("examples/"+modelName+"_example/"+modelName+".fidelity.pruned", fidelity_file_pruned)
#             copyfile("examples/"+modelName+"_example/"+modelName+".onto", ontology_file)

#             dict_to_write = {}

#             dict_to_write['id'] = (i+1)
#             dict_to_write['filename'] = fileName+".png"
#             dict_to_write['tree_size_limit'] = treeSizeLimit
#             dict_to_write['ontology'] = ontology

#             with open("examples/"+modelName+"_example/"+modelName+".fidelity.pruned", 'r') as f:
#                 lines = f.read().splitlines()
#                 last_line = lines[-1]
#                 # print (last_line)
#                 vals = last_line.split("\t")
#                 dict_to_write['internal_nodes'] = vals[0]
#                 # print ("INTERNAL NODES ARE "+dict_to_write['internal_nodes'])
#                 dict_to_write['train_fidelity'] = vals[1]
#                 dict_to_write['train_accuracy'] = vals[2]
#                 dict_to_write['test_fidelity'] = vals[3]
#                 dict_to_write['test_accuracy'] = vals[4]
#                 dict_to_write['leaves_nr'] = vals[5]
#                 dict_to_write['compr_m1'] = vals[6]
#                 dict_to_write['branches_nr'] = vals[7]
#                 dict_to_write['compr_m2'] = vals[8]
            
#             good_tree = isGoodTreeSameSize(treeSizeLimit, int(dict_to_write['internal_nodes']),ontology)
            
#             if (good_tree):
#                 writer.writerow(dict_to_write)
                
#             else:
#                 print ('Not good tree generated trying again...')
#                 os.remove(trepan_file)
#                 os.remove(dot_file)
#                 os.remove(fidelity_file)
#                 os.remove(ontology_file)
#         #end-while
#     #end-for
# #end-def

def main():
    """generate trees with different sizes"""
    
    modelNames = ['heart_dataset']#loan_dataset']
    # loan_dataset
    # treeSizeLimits = [10,15,30]
    treeSizeLimits = [6,12,18]
    
    use_ontology = [0,1]

    if not os.path.exists("examples/survey/"):
        os.makedirs("examples/survey/")

    with open("examples/survey/tree_data.csv", mode="w") as csv_file: 
        fieldnames = ['id', 'filename', 'tree_size_limit', 'ontology', 'internal_nodes', 'train_fidelity', 'train_accuracy', 'test_fidelity', 'test_accuracy', 'leaves_nr', 'compr_m1', 'branches_nr', 'compr_m2']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        
        id = 1
        for modelName in modelNames:
            
            if not os.path.exists("examples/survey/"+modelName):
                os.makedirs("examples/survey/"+modelName)
            
            for treeSizeLimit in treeSizeLimits:
                for ontology in use_ontology:
                    
                    best_tree_file_name = sampleDecisionTrees(RUNS, modelName, treeSizeLimit, ontology)
                    collectAndGenerateResults(id, writer, best_tree_file_name, modelName, treeSizeLimit, ontology)
                    id+=1

                #end-for
            #end-for     
        #end-for  
#end-def

# def main2():
#     """generate different trees samples with different sizes"""
    
#     modelNames = ['loan_dataset']
#     treeSizeLimits = [15,22,30]
#     # treeSizeLimits = [10]
#     use_ontology = [0,1]

#     with open("examples/survey/50_samples_same_size_data.csv", mode="w") as csv_file: 
#         fieldnames = ['id', 'filename', 'tree_size_limit', 'ontology', 'internal_nodes', 'train_fidelity', 'train_accuracy', 'test_fidelity', 'test_accuracy', 'leaves_nr', 'compr_m1', 'branches_nr', 'compr_m2']
#         writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
#         writer.writeheader()
        
#         for modelName in modelNames:
            
#             if not os.path.exists("examples/survey/"+modelName):
#                 os.makedirs("examples/survey/"+modelName)
            
#             for treeSizeLimit in treeSizeLimits:
#                 for ontology in use_ontology:
#                     sampleAndCollectDecisionTreesData(RUNS, writer, modelName, treeSizeLimit, ontology)
#                     # collectAndGenerateResults(id, writer, best_tree_file_name, modelName, treeSizeLimit, ontology)
#                 #end-for
#             #end-for     
#         #end-for  
# #end-def

def redraw_decision_trees():

    for file in os.listdir("examples/survey/20190314/heart"):
        if file.endswith(".dot"):
            dot_file = os.path.join("examples/survey/20190314/heart", file)
            print(dot_file)
            # dot_files = os.
            # for dot_file in dot_files:
            s = Source.from_file(dot_file, format="png")
            s.render()

#end-def

# running the script
main()
# redraw_decision_trees()