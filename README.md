# Trepan Reloaded

An extended version of the Trepan algorithm (Trepan Reloaded) that takes into account ontologies to decide what feature to use when creating conditions in split nodes. 

The decision is based on a modified version of the information gain measure (used in the inductive creation of the extracted decision tree from the neural network) that taked into account the `degree of generality` of features. 

The Trepan Reloaded implementation consists of three parts:

* Python scripts that are used to pre-process a given dataset, build and train a FFNN model, export the network's weights and biases, and create all the files needed by Trepan (quite a few of them!). 

* A Java library `libs/ontology-wrapper.jar` implemented using the OWL API 5.0 (plus other ontology utilities) that computes the `degree of generality` of features associated to concepts defined in an ontology.

* An extended version of the Trepan algorithm taking into account weights associated to the features in a dataset.

## Requirements

### Python scripts

[Only needed if you want to use new datasets]

* graphviz >= 0.10.1
* numpy >= 1.15.4
* pandas >= 0.24.0
* scikit-learn >= 0.20.2
* torch >= 0.4.1

### Java library

[Only needed if you want to use new datasets and new ontologies]

The Java library is called from the C implementation using the ```jni.h``` library. To this end the following dependencies are needed to be made explicit in the makefile of the Trepan C distribution.

* JDK >= 8

### Trepan Reloaded

This version of Trepan has been tested only under Mac OS platform with the following `gcc` compiler

```
gcc --version
Configured with: --prefix=/Library/Developer/CommandLineTools/usr --with-gxx-include-dir=/Library/Developer/CommandLineTools/SDKs/MacOSX10.14.sdk/usr/include/c++/4.2.1
Apple LLVM version 10.0.1 (clang-1001.0.46.3)
Target: x86_64-apple-darwin18.5.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
```

## Running

The current version of Trepan Reloaded can be run by compiling (after having set the java path correctly) 

```
sh trepan-compile.sh 
```

and then running one of the two demos `heart` or `loan` by 

### Running the `heart` example

```
./trepan heart_dataset.cmd
```

### Running the `loan` example

```
./trepan loan_dataset.cmd
```

The results can be found in `examples/heart_dataset_example` and `examples/loan_dataset_example`. They consist of:

* `name_dataset.dot`: a graphviz representation of the decision tree extracted by Trepan.
* `name_dataset.fidelity.pruned`: the accuracy and fidelity of the decision tree extracted by Trepan as well as some understandability measures computed based on the syntactic complexity of the tree (e.g., nr of leaves, nr of branches).



## Reference

* Confalonieri, R., et al. Trepan Reloaded: A Knowledge-driven Approach to Explaining Black-box models. In Proc. of ECAI 2020.
