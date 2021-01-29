# This is a shell archive.  Save it in a file, remove anything before
# this line, and then unpack it by entering "sh file".  Note, it may
# create directories; files and directories will be owned by you and
# have default permissions.
#
# This archive contains:
#
#	ReadMe
#	command-exp.h
#	command-int.h
#	command.c
#	examples-exp.h
#	examples.c
#	main.c
#	mofn-exp.h
#	mofn-int.h
#	mofn.c
#	network-exp.h
#	network-int.h
#	network.c
#	sample-exp.h
#	sample-int.h
#	sample.c
#	stats-exp.h
#	stats-int.h
#	stats.c
#	tree.c
#	tree.h
#	user-command-exp.h
#	user-command.c
#	user-examples-exp.h
#	user-examples-int.h
#	user-examples.c
#	utils-exp.h
#	utils.c
#	heart.attr
#	heart.cmd
#	heart.net
#	heart.test.pat
#	heart.train.pat
#	heart.wgt
#	makefile
#
echo x - ReadMe
sed 's/^X//' >ReadMe << 'END-of-ReadMe'
X
XIntroduction
X------------
X
XGiven a trained neural network, the TREPAN algorithm extracts a decision tree 
Xthat provides a close approximation to the concept represented by the network.
XA brief description of the algorithm appears in [Craven & Shavlik, 1996],
Xand a comprehensive description can be found in [Craven, 1996].
X
XIn order to use TREPAN as is, you will have to set up at least five files:
X  - The "command" file provides a list of commands for TREPAN to execute.
X  - The "network" file describes the topology of the neural network.
X  - The "weight" file lists the weight and bias parameters of the network.
X  - The "attribute" file describes the attributes of the problem domain.
X  - The "example" files provide sets of examples for TREPAN to process.
XThe network and weight files use the same formats as their
Xcounterparts in Rumelhart & McClelland's PDP code.  The command file
Xused by TREPAN also is very similar to that used by the PDP code.
X
XTREPAN is invoked as follows:
X	trepan <command-file-name>
Xwhere <command-file-name> is the name of a file that contains a list
Xof commands for TREPAN to execute.  The following sections describe
Xsome of the commands that can by executed by TREPAN, and the file formats
Xthat it uses.
X
XA set of files (heart.cmd, heart.net, heart.wgt, heart.attr,
Xheart.train.pat, heart.test.pat) for the UC-Irvine heart-disease domain
Xis provided as an example.
X
XThe code should be fairly easy to tailor to other neural-net and
Xexample/attribute representations, as well as additional commands.
XThe interfaces to these aspects of the system are described below.
XFirst, the existing system is described.
X
X
XThe Command File
X----------------
X
XThe command file should list one command per line and be terminated
Xby the command "quit".  Here are descriptions of some of the commands
Xthat can be processed by TREPAN.
X
Xget attributes <file-name>
X   Read the attribute file indicated by <file-name>.  This command
X   should be executed before TREPAN is instructed to read any example
X   files.
X
Xget training_examples <file-name>
Xget test_examples <file-name>
Xget validation_examples <file-name>
X   Read in sets of examples to be used as training, test, or validation
X   sets respectively.
X
Xget network <file-name-stem>
X   Reads the network and weight files specified by <file-name-stem>.
X   TREPAN expects the network file to be called "<file-name-stem>.net"
X   and the weight file to be called either "<file-name-stem>.wgt" or
X   "<file-stem-name>.wts".
X
Xget ensemble <file-name-stem> <number-of-networks>
X   Read in a set of networks to be treated as an ensemble (i.e. a committee
X   of classifiers).  TREPAN expects to find network and weight files
X   called "<file-name-stem>.<N>.net" and either "<file-name-stem>.<N>.wgt"
X   or ""<file-name-stem>.<N>.wts", where <N> ranges from 0 to
X   <number-of-networks> - 1.
X
Xget attribute_mappings <file-name>
X   A crude method for specifying how a nominal attribute's value 
X   should be mapped into input-unit activations.  Each line of the file
X   specifies the mapping for one attribute.  The format of the line is
X   as follows:
X	<attribute-name> <vector-size> <vector>...
X   The first field indicates the name of attribute, the second field
X   indicates the size of the vector (i.e., the number of input units) used 
X   to represent the attribute's value, and subsequent fields specify the
X   vector used to represent each possible value of the attribute.  The order
X   of these vectors should correspond to the order of the values listed in
X   the attribute file.  Currently, this option works only for nominal
X   attributes.
X
X   Here is an example: suppose we had an attribute defined in the attribute
X   file as follows:
X	color	N	red green blue
X   and we used the vectors 1100 0101 0011 to represent these values respectively
X   when training a neural network.  The corresponding line in the 
X   attribute-mapping file should then be:
X	color	4	1 1 0 0   0 1 0 1   0 0 1 1
X
X
Xset seed <number>
X   Set the seed for the random-number generator to <number>.  Setting
X   the seed in this fashion enables a run of TREPAN to be replicated.
X
Xset tree_size_limit <number>
X   Specify the maximum size of the tree to be returned by TREPAN.
X   The value <number> indicates the maximum number of internal nodes
X   that may be in the tree.  The default value is 100.
X
Xset min_sample <number>
X   Specify the minimum sample size (i.e. number of queries) that TREPAN 
X   should use at each node in the decision tree.  The default value is 1000.
X
Xset activation_function logistic | tanh | linear     hidden | output |  all
X   Specify the activation function to use for a subset of the units
X   in the neural network.  The first parameter indicates the function
X   to use, and the second parameter indicates the units for which it
X   is being used.  The default is to use the logistic (sigmoid mapping
X   into [0, 1]) activation function for all hidden and output units.
X
Xset classification_function threshold_half | threshold_zero | one_of_n
X  Specify the function to be used to map the network's output activations
X  into classifications.  The first two options, threshold_half and
X  threshold_zero, threshold the activation of a single output unit and
X  return the class corresponding to the thresholded activation.
X  Threshold_half is intended to be used with logistic activation functions,
X  and therefore thresholds the output on the value 0.5.  It is the default
X  function for networks with one output unit.  Threshold_zero is intended to 
X  be used with hyperbolic-tangent activation functions, and thresholds the 
X  output on the value 0.0.  The one_of_n option is intended for networks that 
X  have more than one output unit.  It returns the class corresponding to the 
X  output with the greatest activation.
X
Xclassify_using_network
X   Classify examples using the network and report its accuracy.  Accuracy
X   is measured and reported for all currently loaded example sets
X   (training, test, and validation).
X
Xpredict_using_network
X   Run all loaded example sets through the network and print the output-unit
X   activations for each example.
X
Xtrepan [ <file-name> ]
X   Extract a tree from the loaded network using the TREPAN algorithm.
X   If an optional file name is provided, TREPAN will print out accuracy
X   and fidelity information for all example sets (training, validation, test)
X   that are currently loaded.
X
Xdisjunctive_trepan [ <file-name> ]
X   Extract a tree from the loaded network using a variant of TREPAN that
X   uses disjunctive (i.e. "or") tests (instead of general m-of-n tests)
X   at the internal nodes of the extracted tree.  If an optional file name 
X   is provided, TREPAN will print out accuracy and fidelity information for 
X   all example sets (training, validation, test) that are currently loaded.
X
Xlo_mofn [ <file-name> ]
X   Extract a tree from the loaded network using a variant of TREPAN
X   that uses only single-attribute tests at the internal nodes of the
X   extracted tree.  If an optional file name is provided, TREPAN will 
X   print out accuracy and fidelity information for all example sets 
X   (training, validation, test) that are currently loaded.
X
Xtest_fidelity
X   Measure the fidelity of the extracted tree with respect to the
X   given network.  Fidelity is defined as the percentage of examples
X   for which the predictions made by the extracted tree agree with the
X   predictions made by the network.  The fidelity of the tree is measured
X   and reported for all of the currently loaded example sets (training,
X   test and validation).
X
Xtest_correctness
X   Measure the accuracy of the extracted tree.  Accuracy is measured
X   and reported for all currently loaded example sets (training, test,
X   and validation).
X
Xprint_tree
X   Print an ASCII depiction of the extracted tree.  The conventions
X   used for printing the tree are similar to those used by Quinlan's
X   C4.5 code.  Next to each leaf node, TREPAN prints the class distribution
X   for training examples that reach the leaf (in the first set of brackets), 
X   and the class distribution of other membership queries it made at the leaf
X   (in the second set of brackets).
X
Xdraw_tree <file-name>
X   Save a representation of the tree that can be used by the "dot" program
X   to make a nice Postscript depiction of the tree.  The dot-readable
X   representation is saved in the file indicated by <file-name>.
X   
Xquit
X   Stop processing commands and exit.
X
X
XThe Attribute File
X------------------
X
XThe attribute file lists the attributes of the problem domain.  Each line
Xof the file should describe one of the attributes in the problem domain.
XEach attribute description should be in the following format:
X
X	<name> <type> [ <allowed values> ]
X
XThe <name> can include any non-whitespace characters.  The <type> should be
Xone of the following: B, N, R, indicating whether the attribute is Boolean,
Xnominal, or real-valued, respectively.  If the attribute is nominal then the
Xallowable values for the attribute should also be listed on the line.  The
Xlast line in the file should be a description of the class attribute.
X
XTREPAN makes the following assumptions about how attributes are mapped to
Xinput-unit activations.  Real-valued and Boolean attributes are assumed to
Xbe represented by one input unit each.  Boolean attributes are mapped to
Xvalues of 0 (false) and 1 (true).  Nominal attributes are assumed to
Xbe represented by one input per value. 
X
XThe order that the attributes are listed in this file should correspond
Xto the order in which they should be mapped into the input vector 
Xfor the neural network.  Moreover, the order in which the allowable
Xvalues for nominal attributes are listed in the file should correspond
Xto the order of their corresponding input units in the network.
X
X
XData Files
X----------
X
XThe data files list the training/test examples for the problem.  Each example
Xis listed on a separate line in the following format:
X
X	<name> <value>... <class-value> 
X
XThe <name> can include any non-whitespace characters.  There should be
Xone <value> listed for each attribute in the problem.  For a real-valued
Xattribute, the corresponding value should be a number.  For a Boolean
Xattribute, the value should be one of the following: t, f, true, false.
XFor a nominal attribute, the value should be one of the allowable values
Xlisted in the attribute file.
X
X
XHints on Running TREPAN
X-----------------------
X
XThe first thing you should do when applying TREPAN to a network is to
Xmake sure that TREPAN is producing the correct outputs for the network.
XDo this by loading a network and a set of examples, and then running
Xclassify_using_network.  This function will report the accuracy of the
Xnetwork and will output a confusion matrix for the task.
X
XIn order to determine a good tree size, provide the trepan command
X(or disjunctive_trepan or lo_mofn) with a file name.  When given a file name,
Xthese commands will record the fidelity of the tree each time TREPAN
Xadds a new node.  Given the fidelity measurements in this file, the 
Xtrade-off between fidelity and tree complexity is readily apparent.
X
XI suggest trying the disjunctive version of TREPAN (called by the
Xdisjunctive_trepan command) in addition to the ordinary one.  It runs slightly
Xfaster than the version which searches for m-of-n tests, and I think
Xthe resulting trees are usually easier to understand.
X
X
XModifying the Network Interface
X-------------------------------
X
XTo use TREPAN with a different neural-network representation (or with a
Xdifferent type of classifier altogether), there are two primary functions 
Xthat need to be changed: get_network and register_network_oracle.
XThe former function reads in a network when called.  The second function
Xis the primary interface between TREPAN and the network.  When called,
Xthis function provides a pointer to a function that TREPAN can use
Xto query the network.  The function supplied by register_network_oracle
Xshould have a prototype as follows:
X	int query_network(Example *example, AttributeInfo *attr_info)
X
X
XModifying the Example/Attribute Interface
X-----------------------------------------
X
XTo use TREPAN with different attribute/example files, there are two
Xprimary functions that need to be modified: read_attributes and
Xread_examples.  Modified versions of these functions should set up the
Xrelevant data structures in the same way as the current versions.
X
X
XModifying the Command Interface
X-------------------------------
X
XNew commands can easily be added to TREPAN.  This is done by placing new calls
Xto install_command_option in the function install_user_commands.
XInstall_command_option takes three arguments: the name of the command,
Xthe "menu" of the command, and the function to be called when the
Xcommand is invoked.  The "menu" of a command simply indicates whether the
Xcommand is preceded by the word "get", "set", ..., or nothing at all.
XThe function install_commands should provide a clear illustration
Xof how commands are installed in TREPAN. 
X
X
X
XReferences
X----------
X
X[Craven, 1996]
X  Extracting Comprehensible Models from Trained Neural Networks.  PhD thesis,
X  Department of Computer Sciences, University of Wisconsin-Madison. 
X  Available as UW Technical Report CS-TR-96-1326, and by
X  ftp://ftp.cs.wisc.edu/machine-learning/shavlik-group/craven.thesis.ps.
X
X
X[Craven & Shavlik, 1996]
X  Extracting Tree-Structured Representations of Trained Networks. 
X  In Touretzky, D., Mozer, M., & Hasselmo, M., editors, Advances
X  in Neural Information Processing Systems (volume 8). MIT Press,
X  Cambridge, MA.
X      
END-of-ReadMe
echo x - command-exp.h
sed 's/^X//' >command-exp.h << 'END-of-command-exp.h'
X/* exported functions */
Xextern void     init_command_handling();
Xextern void	init_data_structures();
Xextern void     run_commands();
X
END-of-command-exp.h
echo x - command-int.h
sed 's/^X//' >command-int.h << 'END-of-command-int.h'
X#define MAX_MENUS       20
X#define ONewMenu        1
X#define OVariable       2
X#define OCommand        3
X#define OShowVariable   4
X 
X#define VInt            1
X#define VFloat          2
X#define VString         4
X 
X
Xtypedef struct option_rec
X{
X   char  name[40];
X   int otype;
X   int menunum;
X   void (*func)();
X   int vartype;
X   int *varptr;
X   struct option_rec *next;
X   struct option_rec *vnext;
X} OptionRec;
X 
X 
X/* variables shared by command.c and user_command.c */
Xextern AttributeInfo active_attributes;
Xextern ExampleInfo train_examples;
Xextern ExampleInfo test_examples;
Xextern ExampleInfo validation_examples;
Xextern Options active_options;
X
Xextern int NoMenuNum;
Xextern int SetMenuNum;
Xextern int GetMenuNum;
Xextern int SaveMenuNum;
Xextern int ShowMenuNum;
X
Xextern char arg_buffer[2048];
Xextern int num_arguments;
Xextern char *arguments[256];
X
Xextern AttributeInfo active_attributes;
Xextern ExampleInfo train_examples;
Xextern float *train_mask;
Xextern ExampleInfo test_examples;
Xextern ExampleInfo validation_examples;
Xextern Options active_options;
Xextern TreeNode *tree;
X
X
X/* functions shared by command.c and user_command.c */
Xextern char	*get_next_string();
Xextern void	install_command_option();
Xextern void     install_user_commands();
Xextern void     install_user_variables();
Xextern void	install_variable_option();
Xextern void	parse_args();
Xextern void	restore_options();
Xextern void	save_options();
X
END-of-command-int.h
echo x - command.c
sed 's/^X//' >command.c << 'END-of-command.c'
X#include <stdio.h>
X#include <stdlib.h>
X#include <string.h>
X#include <math.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "user-examples-exp.h"
X#include "tree.h"
X#include "command-int.h"
X#include "user-command-exp.h"
X#include "network-exp.h"
X#include "mofn-exp.h"
X#include "sample-exp.h"
X
X
X/* variables shared by command.c and user-command.c */
Xint NoMenuNum;
Xint SetMenuNum;
Xint GetMenuNum;
Xint SaveMenuNum;
Xint ShowMenuNum;
Xchar arg_buffer[2048];
Xint num_arguments = 0;
Xchar *arguments[256];
X
X
X/* variables shared by command.c and user-command.c */
XAttributeInfo active_attributes;
XExampleInfo train_examples;
Xfloat *train_mask = NULL;
XExampleInfo test_examples;
XExampleInfo validation_examples;
XOptions active_options;
XTreeNode *tree = NULL;
X
X
Xstatic int num_menus = 0;
Xstatic OptionRec *menu_list[MAX_MENUS];
Xstatic OptionRec *variable_list = NULL;
Xstatic char in_buffer[2048];
X
X
X
Xstatic Options backup_options;
X
X
Xvoid save_options(options)
X   Options *options;
X{
X   memcpy((void *) &backup_options, (void *) options, (int) sizeof(Options));
X}
X
X
Xvoid restore_options(options)
X   Options *options;
X{
X   memcpy((void *) options, (void *) &backup_options, (int) sizeof(Options));
X}
X
X
Xvoid init_data_structures()
X{
X   train_examples.number = 0;
X   train_examples.examples = NULL;
X
X   test_examples.number = 0;
X   test_examples.examples = NULL;
X
X   validation_examples.number = 0;
X   validation_examples.examples = NULL;
X
X   active_attributes.number = 0;
X   active_attributes.class_index = 0;
X   active_attributes.num_classes = 0;
X   active_attributes.attributes = NULL;
X   active_attributes.stratification = NULL;
X
X   active_options.expansion_method = DEPTH_FIRST;
X   active_options.split_search_method = GREEDY;
X   active_options.do_sampling = FALSE;
X   active_options.use_oracle = FALSE;
X   active_options.min_objects = 2;
X   active_options.beam_width = 2;
X   active_options.min_sample = 1000;
X   active_options.oracle = NULL;
X   active_options.distribution_type = LOCAL;
X   active_options.distribution_alpha = 0.10;
X   active_options.min_estimation_fraction = 0.0;
X   active_options.sampling_stop = FALSE;
X   active_options.validation_stop = FALSE;
X   active_options.stop_depth = 10000;
X   active_options.tree_size_limit = 100;
X   active_options.patience_threshold = 0.0;
X   active_options.patience_counter = 1;
X   active_options.stop_z = 2.32;
X   active_options.stop_epsilon = 0.01;
X
X   active_options.num_mofn_ops = 2;
X   active_options.mofn_ops = check_malloc(active_options.num_mofn_ops *
X					  sizeof(*active_options.mofn_ops));
X   active_options.mofn_ops[0] = mofn_plus_1; 
X   active_options.mofn_ops[1] = m_plus_1_of_n_plus_1; 
X   active_options.mofn_level = 0.05;
X
X   active_options.split_method = GAIN;
X
X   active_options.estimation_method = KERNEL;
X   active_options.kernel_width_fn = sqrt;
X   active_options.print_distributions = FALSE;
X}
X
X
Xvoid parse_args(in_stream)
X   FILE *in_stream;
X{
X   char *arg;
X
X   fgets(arg_buffer, BUFSIZ, in_stream);
X
X   num_arguments = 0;
X   arg = strtok(arg_buffer, " \t\n\"");
X   while (arg != NULL)
X   {
X      arguments[num_arguments] = arg;
X      ++num_arguments;
X      arg = strtok((char *) NULL, " \t\n\"");
X   }
X}
X
X
Xstatic int make_new_menu()
X{
X   int mnum = num_menus;
X
X   num_menus++;
X
X   if (mnum >= MAX_MENUS)
X      error(prog_name, "Too many menus", TRUE);
X
X   menu_list[mnum] = NULL;
X   return mnum;
X}
X
X
Xstatic void install_menu_option(name, frommenu, tomenu)
X   char *name;
X   int frommenu;
X   int tomenu;
X{
X   OptionRec *temp;
X   OptionRec *last;
X   OptionRec *after;
X
X   if (frommenu >= num_menus)
X      error(prog_name, "Origin menu does not exist", TRUE);
X   if (tomenu >= num_menus)
X      error(prog_name, "Origin menu does not exist", TRUE);
X
X   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
X   strcpy(temp->name, name);
X   temp->otype = ONewMenu;
X   temp->menunum = tomenu;
X   temp->next = NULL;
X
X   if (menu_list[frommenu] == NULL)
X      menu_list[frommenu] = temp;
X   else if (strcasecmp(temp->name, menu_list[frommenu]->name) < 0)
X   {
X      temp->next = menu_list[frommenu];
X      menu_list[frommenu] = temp;
X   }
X   else
X   {
X      last = menu_list[frommenu];
X      after = menu_list[frommenu]->next;
X      while (after != NULL)
X         if (strcasecmp(temp->name, after->name) < 0)
X            after = NULL;
X         else
X	 {
X            last = after;
X            after = after->next;
X         }
X      temp->next = last->next;
X      last->next = temp;
X   }
X}
X
X
Xvoid install_command_option(name, frommenu, fptr)
X   char *name;
X   int frommenu;
X   void (*fptr)();
X{
X   OptionRec *temp;
X   OptionRec *last;
X   OptionRec *after;
X
X   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
X   strcpy(temp->name, name);
X   temp->otype = OCommand;
X   temp->func = fptr;
X   temp->next = NULL;
X
X   if (menu_list[frommenu] == NULL)
X      menu_list[frommenu] = temp;
X   else if (strcasecmp(temp->name,menu_list[frommenu]->name) < 0)
X   {
X      temp->next = menu_list[frommenu];
X      menu_list[frommenu] = temp;
X   }
X   else
X   {
X      last = menu_list[frommenu];
X      after = menu_list[frommenu]->next;
X      while (after != NULL)
X         if (strcasecmp(temp->name, after->name) < 0)
X            after = NULL;
X         else
X         {
X            last = after;
X            after = after->next;
X         }
X      temp->next = last->next;
X      last->next = temp;
X   }
X}
X
X
Xstatic void install_show_variable_option (name, frommenu, vtype, vptr)
X   char *name;
X   int frommenu;
X   int vtype;
X   int *vptr;
X{
X   OptionRec *temp;
X   OptionRec *last;
X   OptionRec *after;
X   OptionRec *tempvl = variable_list;
X   int vlfound = 0;
X
X   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
X   strcpy(temp->name, name);
X   temp->otype = OShowVariable;
X   temp->vartype = vtype;
X   temp->varptr = vptr;
X   temp->next = NULL;
X
X   while ((tempvl != NULL) && (!vlfound))
X      if (!strcmp(name,tempvl->name))
X         vlfound = 1;
X      else
X         tempvl = tempvl->vnext;
X
X   if (!vlfound)
X   {
X      temp->vnext = variable_list;
X      variable_list = temp;
X   }
X
X   if (menu_list[frommenu] == NULL)
X      menu_list[frommenu] = temp;
X   else if (strcasecmp(temp->name, menu_list[frommenu]->name) < 0)
X   {
X      temp->next = menu_list[frommenu];
X      menu_list[frommenu] = temp;
X   }
X   else
X   {
X      last = menu_list[frommenu];
X      after = menu_list[frommenu]->next;
X      while (after != NULL)
X      if (strcasecmp(temp->name, after->name) < 0)
X         after = NULL;
X      else
X      {
X         last = after;
X         after = after->next;
X      }
X      temp->next = last->next;
X      last->next = temp;
X   }
X}
X
X
Xvoid install_variable_option (name, frommenu, vtype, vptr)
X   char *name;
X   int frommenu;
X   int vtype;
X   int *vptr;
X{
X   OptionRec *temp;
X   OptionRec *last;
X   OptionRec *after;
X
X   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
X   strcpy(temp->name, name);
X   temp->otype = OVariable;
X   temp->vartype = vtype;
X   temp->varptr = vptr;
X   temp->next = NULL;
X   temp->vnext = variable_list;
X   variable_list = temp;
X
X   install_show_variable_option(name, ShowMenuNum, vtype, vptr);
X
X   if (menu_list[frommenu] == NULL)
X      menu_list[frommenu] = temp;
X   else if (strcasecmp(temp->name,menu_list[frommenu]->name) < 0)
X   {
X      temp->next = menu_list[frommenu];
X      menu_list[frommenu] = temp;
X   }
X   else
X   {
X      last = menu_list[frommenu];
X      after = menu_list[frommenu]->next;
X      while (after != NULL)
X         if (strcasecmp(temp->name,after->name) < 0)
X            after = NULL;
X         else
X         {
X            last = after;
X            after = after->next;
X         }
X      temp->next = last->next;
X      last->next = temp;
X   }
X}
X
X
Xstatic OptionRec *find_variable (name, report)
X   char *name;
X   int report;
X{
X   OptionRec *temp = variable_list;
X   int done = 0;
X
X   while ((temp != NULL) && (!done))
X      if (!strcmp(name, temp->name))
X         return temp;
X      else
X         temp = temp->vnext;
X
X   temp = variable_list;
X   while ((temp != NULL) && (!done))
X      if (Startsame(name, temp->name))
X         return temp;
X      else
X         temp = temp->vnext;
X
X   if (report)
X   {
X      sprintf(err_buffer, "No variable %s", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X   return NULL;
X}
X
X
Xstatic OptionRec *find_match(name, olst)
X   char *name;
X   OptionRec *olst;
X{
X   OptionRec *temp = olst;
X
X   while (temp != NULL)
X      if (!strcmp(name, temp->name))
X         return(temp);
X      else
X         temp = temp->next;
X
X   temp = olst;
X   while (temp != NULL)
X      if (Startsame(name, temp->name))
X         return temp;
X      else
X         temp = temp->next;
X
X   sprintf(err_buffer, "No menu option corresponding to %s",name);
X   error(prog_name, err_buffer, TRUE);
X   return NULL;
X}
X
X
Xchar *get_next_string(in_stream)
X   FILE *in_stream;
X{
X   if (fscanf(in_stream, "%s", in_buffer) != EOF)
X      return  in_buffer;
X
X   error(prog_name, "unexpected end of file", TRUE);
X}
X
X
Xstatic void show_variable(vtype, varptr)
X   int vtype;
X   int *varptr;
X{
X   switch (vtype)
X   {
X      case VInt:
X         printf("%d",*varptr);
X         break;
X      case VFloat:
X         printf("%.6f",* (float *) varptr);
X         break;
X      case VString:
X         printf("%s",(char *) varptr);
X         break;
X   }
X}
X
X
Xstatic void cmd_echo(in_stream)
X   FILE *in_stream;
X{
X   char *str;
X   OptionRec *match;
X   char buffer[BUFSIZ];
X
X   fgets(buffer, BUFSIZ, in_stream);
X
X   str = strtok(buffer, " \t\n\"");
X   while (str != NULL)
X   {
X      if (str[0] == '$')
X      {
X         match = find_variable(str + 1,FALSE);
X         if (match == NULL)
X	 {
X            sprintf(err_buffer, "%s is not a registered variable", str + 1);
X	    error("Warning", err_buffer, FALSE);
X	 }
X         else
X            show_variable(match->vartype, match->varptr);
X         printf(" ");
X      }
X      else
X         printf("%s ",str);
X
X     str = strtok((char *) NULL, " \t\n\"");
X  }
X  printf("\n");
X}
X
X
Xstatic void cmd_quit(in_stream)
X   FILE *in_stream;
X{
X   exit(0);
X}
X
X
Xstatic void cmd_get_network(in_stream)
X   FILE *in_stream;
X{
X   char *stem;
X
X   if ((stem = get_next_string(in_stream)) == NULL)
X      error(prog_name, "file stem for network files not specified", TRUE);
X
X   get_network(stem);
X}
X
X
Xstatic void cmd_get_ensemble(in_stream)
X   FILE *in_stream;
X{
X   char stem[BUFSIZ];
X   int number;
X
X   if (fscanf(in_stream, "%s", stem) != 1)
X      error(prog_name, "file stem for network files not specified", TRUE);
X
X   if (fscanf(in_stream, "%d", &number) != 1)
X      error(prog_name, "number of networks in ensemble not specified", TRUE);
X
X/*
X   if (number < 2 || number > 100)
X*/
X   if (number < 1 || number > 100)
X      error(prog_name,
X	    "number of networks in ensemble must be between 2 and 100", TRUE);
X
X   get_ensemble(stem, number);
X}
X
X
Xstatic void cmd_attribute_distributions(in_stream)
X   FILE *in_stream;
X{
X   if (train_examples.number == 0)
X   {
X      error(prog_name,
X	    "attribute_distributions called before training examples loaded",
X	    TRUE);
X   }
X
X   determine_attribute_distributions(&active_attributes, &train_examples,
X				     train_mask);
X   print_attribute_distributions(&active_attributes, &active_options, NULL);
X}
X
X
Xstatic void cmd_lo_mofn(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *fname;
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fname = strtok(buffer, " \t\n\"");
X
X   if (train_examples.number == 0)
X      error(prog_name, "lo_mofn called before training examples loaded", TRUE);
X
X   determine_attribute_distributions(&active_attributes, &train_examples,
X				     train_mask);
X
X   if (active_options.print_distributions)
X      print_attribute_distributions(&active_attributes, &active_options, NULL);
X
X   save_options(&active_options);
X
X   active_options.expansion_method = BEST_FIRST;
X   active_options.split_search_method = GREEDY;
X   active_options.do_sampling = TRUE;
X   active_options.use_oracle = TRUE;
X   active_options.sampling_stop = TRUE;
X
X   register_network_oracle(&active_options.oracle);
X
X   if (tree)
X      free_tree(tree);
X
X   echo_key_parameters("\nParameter settings for lo_mofn", &active_options);
X
X   tree = induce_tree(&active_attributes, &train_examples, train_mask,
X		      &test_examples, &validation_examples, &active_options,
X		      fname); 
X
X   restore_options(&active_options);
X}
X
X
Xstatic void cmd_trepan(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *fname;
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fname = strtok(buffer, " \t\n\"");
X
X   if (train_examples.number == 0)
X      error(prog_name, "TREPAN called before training examples loaded", TRUE);
X
X   determine_attribute_distributions(&active_attributes, &train_examples,
X				     train_mask);
X
X   if (active_options.print_distributions)
X      print_attribute_distributions(&active_attributes, &active_options, NULL);
X
X   save_options(&active_options);
X
X   active_options.expansion_method = BEST_FIRST;
X   active_options.split_search_method = BEAM;
X   active_options.do_sampling = TRUE;
X   active_options.use_oracle = TRUE;
X   active_options.sampling_stop = TRUE;
X
X   register_network_oracle(&active_options.oracle);
X
X   if (tree)
X      free_tree(tree);
X
X   echo_key_parameters("\nParameter settings for TREPAN", &active_options);
X
X   tree = induce_tree(&active_attributes, &train_examples, train_mask,
X		      &test_examples, &validation_examples, &active_options,
X		      fname); 
X
X   restore_options(&active_options);
X}
X
X
Xstatic void cmd_disjunctive_trepan(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *fname;
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fname = strtok(buffer, " \t\n\"");
X
X   if (train_examples.number == 0)
X   {
X      error(prog_name,
X	    "disjunctive_trepan called before training examples loaded",
X	    TRUE);
X   }
X
X   determine_attribute_distributions(&active_attributes, &train_examples,
X				     train_mask);
X
X   if (active_options.print_distributions)
X      print_attribute_distributions(&active_attributes, &active_options, NULL);
X
X   save_options(&active_options);
X
X   active_options.expansion_method = BEST_FIRST;
X   active_options.split_search_method = BEAM;
X   active_options.do_sampling = TRUE;
X   active_options.use_oracle = TRUE;
X   active_options.sampling_stop = TRUE;
X   active_options.num_mofn_ops = 1;
X   active_options.mofn_ops = check_malloc(sizeof(*active_options.mofn_ops));
X   active_options.mofn_ops[0] = mofn_plus_1;
X
X   register_network_oracle(&active_options.oracle);
X
X   if (tree)
X      free_tree(tree);
X
X   echo_key_parameters("\nParameter settings for disjunctive_trepan",
X                       &active_options);
X
X   tree = induce_tree(&active_attributes, &train_examples, train_mask,
X		      &test_examples, &validation_examples, &active_options,
X		      fname); 
X
X   check_free((void *) active_options.mofn_ops);
X   restore_options(&active_options);
X}
X
X
Xstatic void cmd_conjunctive_trepan(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *fname;
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fname = strtok(buffer, " \t\n\"");
X
X   if (train_examples.number == 0)
X   {
X      error(prog_name,
X	    "conjunctive_trepan called before training examples loaded",
X	    TRUE);
X   }
X
X   determine_attribute_distributions(&active_attributes, &train_examples,
X				     train_mask);
X
X   if (active_options.print_distributions)
X      print_attribute_distributions(&active_attributes, &active_options, NULL);
X
X   save_options(&active_options);
X
X   active_options.expansion_method = BEST_FIRST;
X   active_options.split_search_method = BEAM;
X   active_options.do_sampling = TRUE;
X   active_options.use_oracle = TRUE;
X   active_options.sampling_stop = TRUE;
X   active_options.num_mofn_ops = 1;
X   active_options.mofn_ops = check_malloc(sizeof(*active_options.mofn_ops));
X   active_options.mofn_ops[0] = m_plus_1_of_n_plus_1; 
X
X   register_network_oracle(&active_options.oracle);
X
X   if (tree)
X      free_tree(tree);
X
X   echo_key_parameters("\nParameter settings for conjunctive_trepan",
X		       &active_options);
X
X   tree = induce_tree(&active_attributes, &train_examples, train_mask,
X		      &test_examples, &validation_examples, &active_options,
X		      fname); 
X
X   check_free((void *) active_options.mofn_ops);
X   restore_options(&active_options);
X}
X
X
Xstatic void cmd_draw_tree(in_stream)
X   FILE *in_stream;
X{
X   char *fname;
X   char buffer[BUFSIZ];
X
X   if (!tree)
X      error(prog_name, "draw_tree called before tree learned", TRUE);
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fname = strtok(buffer, " \t\n\"");
X
X   if (fname == NULL)
X      error(prog_name, "unable to read file name in draw_tree", TRUE);
X
X   draw_tree(tree, &active_attributes, fname);
X}
X
X
Xstatic void cmd_print_tree(in_stream)
X   FILE *in_stream;
X{
X   if (!tree)
X      error(prog_name, "print_tree called before tree learned", TRUE);
X
X   printf("\nInduced decision tree:");
X   printf("\n----------------------\n");
X   print_tree(tree, &active_attributes, 0);
X   printf("\n\n");
X}
X
X
Xstatic void cmd_test_correctness(in_stream)
X   FILE *in_stream;
X{
X   int **matrix;
X   int **covered_matrix;
X   int (*saved_oracle)();
X
X   if (!tree)
X      error(prog_name, "test_correctness called before tree learned", TRUE);
X
X   matrix = get_confusion_matrix(active_attributes.num_classes);
X   covered_matrix = get_confusion_matrix(2);
X
X   saved_oracle = active_options.oracle;
X   active_options.oracle = NULL;
X
X   if (train_examples.number != 0)
X   {
X      classify_using_tree(tree, &train_examples, &active_attributes,
X		          &active_options, matrix, covered_matrix, FALSE);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Training",
X		    "Correctness");
X      printf("\n");
X   }
X
X   if (validation_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      classify_using_tree(tree, &validation_examples, &active_attributes,
X		          &active_options, matrix, covered_matrix, FALSE);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Validation",
X		    "Correctness");
X   }
X
X   if (test_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      classify_using_tree(tree, &test_examples, &active_attributes,
X		          &active_options, matrix, covered_matrix, FALSE);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Test",
X		    "Correctness");
X   }
X
X/*
X   print_confusion_matrix(covered_matrix, 2, "Correct", "Covered");
X   printf("not covered = 1,  covered = 2   |   incorrect = 1, correct = 2\n");
X*/
X
X   active_options.oracle = saved_oracle;
X   fflush(stdout);
X   free_confusion_matrix(matrix, active_attributes.num_classes);
X   free_confusion_matrix(covered_matrix, 2);
X}
X
X
Xstatic void cmd_test_fidelity(in_stream)
X   FILE *in_stream;
X{
X   int **matrix;
X
X   if (!tree)
X      error(prog_name, "test_fidelity called before tree learned", TRUE);
X
X   matrix = get_confusion_matrix(active_attributes.num_classes);
X
X   if (train_examples.number != 0)
X   {
X      (void) measure_fidelity(tree, &train_examples, &active_attributes,
X		              &active_options, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Oracle", "Tree");
X      print_measure(matrix, active_attributes.num_classes, "Training",
X		    "Fidelity");
X      printf("\n");
X   }
X
X   if (validation_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      (void) measure_fidelity(tree, &validation_examples, &active_attributes,
X		              &active_options, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Oracle", "Tree");
X      print_measure(matrix, active_attributes.num_classes, "Validation",
X		    "Fidelity");
X      printf("\n");
X   }
X
X   if (test_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      (void) measure_fidelity(tree, &test_examples, &active_attributes,
X		              &active_options, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Oracle", "Tree");
X      print_measure(matrix, active_attributes.num_classes, "Test",
X		    "Fidelity");
X      printf("\n");
X   }
X
X   fflush(stdout);
X   free_confusion_matrix(matrix, active_attributes.num_classes);
X}
X
X
Xstatic void cmd_set_seed(in_stream)
X   FILE *in_stream;
X{
X   long int random_seed;
X
X   if (fscanf(in_stream, "%ld", &random_seed) != 1)
X   {
X      error(prog_name, "unable to read value for random seed", FALSE);
X      return;
X   }
X   my_srandom(random_seed);
X}
X
X
Xstatic void cmd_set_distribution_alpha(in_stream)
X   FILE *in_stream;
X{
X   float temp;
X
X   if (fscanf(in_stream, "%f", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for distribution_alpha", FALSE);
X      return;
X   }
X
X   if (temp < 0.0 || temp > 1.0)
X   {
X      error(prog_name, "distribution_alpha must be in [0, 1]", FALSE);
X      return;
X   }
X
X   active_options.distribution_alpha = temp;
X}
X
X
Xstatic void cmd_set_beam_width(in_stream)
X   FILE *in_stream;
X{
X   int temp;
X
X   if (fscanf(in_stream, "%d", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for beam_width", FALSE);
X      return;
X   }
X
X   if (temp < 1)
X   {
X      error(prog_name, "beam_width must be at least 1", FALSE);
X      return;
X   }
X
X   active_options.beam_width = temp;
X}
X
X
Xstatic void cmd_set_min_objects(in_stream)
X   FILE *in_stream;
X{
X   float temp;
X
X   if (fscanf(in_stream, "%f", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for min_objects", FALSE);
X      return;
X   }
X
X   if (temp < 0.0)
X   {
X      error(prog_name, "min_objects must be at least 0.0", FALSE);
X      return;
X   }
X
X   active_options.min_objects = temp;
X}
X
X
Xstatic void cmd_set_min_estimation_fraction(in_stream)
X   FILE *in_stream;
X{
X   float temp;
X
X   if (fscanf(in_stream, "%f", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for min_estimation_fraction",
X	    TRUE);
X      return;
X   }
X
X   if (temp < 0.0 || temp > 1.0)
X   {
X      error(prog_name, "min_estimation_fraction must be between 0.0 and 1.0",
X	    TRUE);
X      return;
X   }
X
X   active_options.min_estimation_fraction = temp;
X}
X
X
Xstatic void cmd_set_stop_epsilon(in_stream)
X   FILE *in_stream;
X{
X   float temp;
X
X   if (fscanf(in_stream, "%f", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for stop_epsilon", TRUE);
X      return;
X   }
X
X   if (temp <= 0.0 || temp >= 0.5)
X   {
X      error(prog_name, "stop_epsilon must be > 0.0 and < 0.5", TRUE);
X      return;
X   }
X
X   active_options.stop_epsilon = temp;
X}
X
X
Xstatic void cmd_set_estimation_method(in_stream)
X   FILE *in_stream;
X{
X   char name[BUFSIZ];
X
X   if (fscanf(in_stream, "%s", name) != 1)
X   {
X      error(prog_name, "unable to read name of estimation method", FALSE);
X      return;
X   }
X
X   if (Startsame(name, "kernel"))
X   {
X      active_options.estimation_method = KERNEL;
X   }
X   else if (Startsame(name, "gaussian"))
X   {
X      active_options.estimation_method = GAUSSIAN;
X   }
X   else if (Startsame(name, "uniform"))
X   {
X      active_options.estimation_method = UNIFORM;
X   }
X   else 
X   {
X      sprintf(err_buffer, "%s is not a valid estimation method", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X
X}
X
X
Xstatic void cmd_set_kernel_width(in_stream)
X   FILE *in_stream;
X{
X   char name[BUFSIZ];
X
X   if (fscanf(in_stream, "%s", name) != 1)
X   {
X      error(prog_name, "unable to read name of kernel_width function", FALSE);
X      return;
X   }
X
X   if (Startsame(name, "log"))
X   {
X      active_options.kernel_width_fn = log;
X   }
X   else if (Startsame(name, "sqrt"))
X   {
X      active_options.kernel_width_fn = sqrt;
X   }
X   else 
X   {
X      sprintf(err_buffer, "%s is not a valid kernel_width function", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X
X}
X
X
Xstatic void cmd_set_min_sample(in_stream)
X   FILE *in_stream;
X{
X   int temp;
X
X   if (fscanf(in_stream, "%d", &temp) != 1)
X   {
X      error(prog_name, "unable to read value for min_sample", FALSE);
X      return;
X   }
X
X   if (temp < 0)
X   {
X      error(prog_name, "min_sample must be at least 0", FALSE);
X      return;
X   }
X
X   active_options.min_sample = temp;
X}
X
X
Xstatic void cmd_set_classification_function(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *name;
X
X   fgets(buffer, BUFSIZ, in_stream);
X
X   if ((name = strtok(buffer, " \t\n")) == NULL)
X   {
X      error(prog_name,
X	    "function type not specified in set_classification_function", TRUE);
X   }
X
X   set_classification_function(name);
X}
X
X
Xstatic void cmd_set_distribution_type(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *name;
X
X   fgets(buffer, BUFSIZ, in_stream);
X
X   if ((name = strtok(buffer, " \t\n")) == NULL)
X      error(prog_name, "type not specified in set_distribution_type", TRUE);
X
X   if (Startsame(name, "local"))
X      active_options.distribution_type = LOCAL;
X   else if (Startsame(name, "global"))
X      active_options.distribution_type = GLOBAL;
X   else
X   {
X      sprintf(err_buffer, "%s is not a valid distribution type", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X}
X
X
Xstatic void cmd_set_split_method(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *name;
X
X   fgets(buffer, BUFSIZ, in_stream);
X
X   if ((name = strtok(buffer, " \t\n")) == NULL)
X      error(prog_name, "method type not specified in set_split_method", TRUE);
X
X   if (Startsame(name, "gain"))
X      active_options.split_method = GAIN;
X   else if (Startsame(name, "gain_ratio"))
X      active_options.split_method = GAIN_RATIO;
X   else if (Startsame(name, "ratio"))
X      active_options.split_method = GAIN_RATIO;
X   else if (Startsame(name, "ORT"))
X      active_options.split_method = ORT;
X   else
X   {
X      sprintf(err_buffer, "%s is not a valid split method", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X}
X
X
Xstatic void cmd_set_activation_function(in_stream)
X   FILE *in_stream;
X{
X   char buffer[BUFSIZ];
X   char *function_type;
X   char *range;
X
X   fgets(buffer, BUFSIZ, in_stream);
X
X   if ((function_type = strtok(buffer, " \t\n")) == NULL)
X   {
X      error(prog_name, "function type not specified in set_activation_function",
X	    TRUE);
X   }
X
X   range = strtok(NULL, " \t\n");
X   set_activation_function(function_type, range);
X}
X
X
Xstatic void cmd_read_attributes(in_stream)
X   FILE *in_stream;
X{
X   char *name;
X
X   if ((name = get_next_string(in_stream)) == NULL)
X      error(prog_name, "file name for attribute file not specified", TRUE);
X
X   if (active_attributes.number)
X      free_attributes(&active_attributes);
X
X   if (train_examples.number)
X   {
X      error("Warning", "freeing loaded training examples", FALSE);
X      free_examples(&train_examples, &active_attributes);
X   }
X
X   if (test_examples.number)
X   {
X      error("Warning", "freeing loaded test examples", FALSE);
X      free_examples(&test_examples, &active_attributes);
X   }
X
X   read_attributes(name, &active_attributes);
X}
X
X
Xstatic void cmd_read_attribute_mappings(in_stream)
X   FILE *in_stream;
X{
X   char *name;
X
X   if ((name = get_next_string(in_stream)) == NULL)
X      error(prog_name, "file name for attribute maps not specified", TRUE);
X
X   if (active_attributes.number == 0)
X   {
X      error(prog_name,
X	    "tried to set attribute maps before attributes loaded", TRUE);
X   }
X
X   read_attribute_mappings(name, &active_attributes);
X}
X
X
Xstatic void cmd_read_train_examples(in_stream)
X   FILE *in_stream;
X{
X   int num_files = 0;
X   char buffer[BUFSIZ];
X   char *fnames[256];
X   int i;
X
X   if (active_attributes.number == 0)
X      error(prog_name,
X            "tried to read examples before attribute information loaded", TRUE);
X
X   if (train_examples.number)
X   {
X      free_examples(&train_examples, &active_attributes);
X      check_free((void *) train_mask);
X   }
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fnames[num_files] = strtok(buffer, " \t\n\"");
X   while (fnames[num_files] != NULL)
X   {
X      ++num_files;
X      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
X   }
X
X   if (num_files == 0)
X      error(prog_name, "file name for examples not specified", TRUE);
X
X   read_examples(fnames, num_files, &active_attributes, &train_examples);
X
X   train_mask = (float *) check_malloc(sizeof(float) * train_examples.number);
X   for (i = 0; i < train_examples.number; ++i)
X      if (train_examples.examples[i].fold == train_examples.test_fold)
X         train_mask[i] = 0.0;
X      else
X         train_mask[i] = 1.0;
X}
X
X
Xstatic void cmd_read_validation_examples(in_stream)
X   FILE *in_stream;
X{
X   int num_files = 0;
X   char buffer[BUFSIZ];
X   char *fnames[256];
X
X   if (active_attributes.number == 0)
X      error(prog_name,
X            "tried to read examples before attribute information loaded", TRUE);
X
X   if (validation_examples.number)
X      free_examples(&validation_examples, &active_attributes);
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fnames[num_files] = strtok(buffer, " \t\n\"");
X   while (fnames[num_files] != NULL)
X   {
X      ++num_files;
X      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
X   }
X
X   if (num_files == 0)
X      error(prog_name, "file name for examples not specified", TRUE);
X
X   read_examples(fnames, num_files, &active_attributes, &validation_examples);
X}
X
X
Xstatic void cmd_read_test_examples(in_stream)
X   FILE *in_stream;
X{
X   int num_files = 0;
X   char buffer[BUFSIZ];
X   char *fnames[256];
X
X   if (active_attributes.number == 0)
X      error(prog_name,
X            "tried to read examples before attribute information loaded", TRUE);
X
X   if (test_examples.number)
X      free_examples(&test_examples, &active_attributes);
X
X   fgets(buffer, BUFSIZ, in_stream);
X   fnames[num_files] = strtok(buffer, " \t\n\"");
X   while (fnames[num_files] != NULL)
X   {
X      ++num_files;
X      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
X   }
X
X   if (num_files == 0)
X      error(prog_name, "file name for examples not specified", TRUE);
X
X   read_examples(fnames, num_files, &active_attributes, &test_examples);
X}
X
X
Xstatic void cmd_predict_using_network(in_stream)
X   FILE *in_stream;
X{
X   register_network_oracle(&active_options.oracle);
X      
X   if (train_examples.number != 0)
X   {
X      predict_using_network(&train_examples, &active_attributes);
X      printf("\n");
X   }
X
X   if (validation_examples.number != 0)
X   {
X      predict_using_network(&validation_examples, &active_attributes);
X      printf("\n");
X   }
X
X   if (test_examples.number != 0)
X   {
X      predict_using_network(&test_examples, &active_attributes);
X      printf("\n");
X   }
X
X   fflush(stdout);
X}
X
X
Xstatic void cmd_classify_using_network(in_stream)
X   FILE *in_stream;
X{
X   int **matrix;
X
X   register_network_oracle(&active_options.oracle);
X   matrix = get_confusion_matrix(active_attributes.num_classes);
X
X   if (train_examples.number != 0)
X   {
X      classify_using_network(&active_options, &train_examples, 
X			     &active_attributes, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Training",
X		    "Correctness");
X      printf("\n");
X   }
X
X   if (validation_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      classify_using_network(&active_options, &validation_examples, 
X			     &active_attributes, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Validation",
X		    "Correctness");
X   }
X
X   if (test_examples.number != 0)
X   {
X      reset_confusion_matrix(matrix, active_attributes.num_classes);
X      classify_using_network(&active_options, &test_examples, 
X			     &active_attributes, matrix);
X      printf("\n");
X      print_confusion_matrix(matrix, active_attributes.num_classes,
X			     "Target", "Predicted");
X      print_measure(matrix, active_attributes.num_classes, "Test",
X		    "Correctness");
X   }
X
X   fflush(stdout);
X   free_confusion_matrix(matrix, active_attributes.num_classes);
X}
X
X
Xstatic void init_menus()
X{
X   NoMenuNum = make_new_menu();
X   SetMenuNum = make_new_menu();
X   GetMenuNum = make_new_menu();
X   SaveMenuNum = make_new_menu();
X   ShowMenuNum = make_new_menu();
X
X   install_menu_option("set/", NoMenuNum, SetMenuNum);
X   install_menu_option("mainmenu", SetMenuNum, NoMenuNum);
X   install_menu_option("get/", NoMenuNum, GetMenuNum);
X   install_menu_option("mainmenu", GetMenuNum, NoMenuNum);
X   install_menu_option("save/", NoMenuNum, SaveMenuNum);
X   install_menu_option("mainmenu", SaveMenuNum, NoMenuNum);
X   install_menu_option("show/", NoMenuNum, ShowMenuNum);
X   install_menu_option("mainmenu", ShowMenuNum, NoMenuNum);
X}
X
X
Xstatic int read_variable(stream, vtype, varptr)
X   FILE *stream;
X   int vtype;
X   int *varptr;
X{
X   switch (vtype)
X   {
X      case VInt:
X         return fscanf(stream,"%d", varptr);
X      case VFloat:
X         return fscanf(stream,"%f", (float *) varptr);
X      case VString:
X         return fscanf(stream,"%s", (char *) varptr);
X      default:
X         error(prog_name, "unknown type of variable to read", TRUE);
X         return(FALSE);
X  }
X}
X
X
Xstatic void install_commands()
X{
X   install_command_option("attributes", GetMenuNum, cmd_read_attributes);
X   install_command_option("test_examples", GetMenuNum,cmd_read_test_examples);
X   install_command_option("validation_examples",
X			  GetMenuNum,cmd_read_validation_examples);
X   install_command_option("training_examples",
X			  GetMenuNum,cmd_read_train_examples);
X   install_command_option("network", GetMenuNum, cmd_get_network);
X   install_command_option("ensemble", GetMenuNum, cmd_get_ensemble);
X   install_command_option("attribute_mappings", GetMenuNum,
X			  cmd_read_attribute_mappings);
X
X   install_command_option("echo", NoMenuNum, cmd_echo);
X   install_command_option("quit", NoMenuNum, cmd_quit);
X   install_command_option("print_tree", NoMenuNum, cmd_print_tree);
X   install_command_option("draw_tree", NoMenuNum, cmd_draw_tree);
X   install_command_option("test_correctness", NoMenuNum, cmd_test_correctness);
X   install_command_option("test_fidelity", NoMenuNum, cmd_test_fidelity);
X   install_command_option("trepan", NoMenuNum, cmd_trepan);
X   install_command_option("disjunctive_trepan", NoMenuNum,
X                          cmd_disjunctive_trepan);
X   install_command_option("conjunctive_trepan", NoMenuNum,
X                          cmd_conjunctive_trepan);
X   install_command_option("lo_mofn", NoMenuNum, cmd_lo_mofn);
X   install_command_option("predict_using_network", NoMenuNum,
X			  cmd_predict_using_network);
X   install_command_option("attribute_distributions", NoMenuNum,
X			  cmd_attribute_distributions);
X   install_command_option("classify_using_network", NoMenuNum,
X			  cmd_classify_using_network);
X
X   install_command_option("seed", SetMenuNum, cmd_set_seed);
X   install_command_option("min_objects", SetMenuNum, cmd_set_min_objects);
X   install_command_option("beam_width", SetMenuNum, cmd_set_beam_width);
X   install_command_option("stop_epsilon", SetMenuNum, cmd_set_stop_epsilon);
X   install_command_option("min_estimation_fraction", SetMenuNum, 
X			  cmd_set_min_estimation_fraction);
X   install_command_option("min_sample", SetMenuNum, cmd_set_min_sample);
X   install_command_option("distribution_alpha", SetMenuNum,
X			  cmd_set_distribution_alpha);
X   install_command_option("activation_function", SetMenuNum,
X			  cmd_set_activation_function);
X   install_command_option("classification_function", SetMenuNum,
X			  cmd_set_classification_function);
X   install_command_option("kernel_width", SetMenuNum, cmd_set_kernel_width);
X   install_command_option("estimation_method", SetMenuNum,
X			  cmd_set_estimation_method);
X   install_command_option("split_method", SetMenuNum, cmd_set_split_method);
X   install_command_option("distribution_type", SetMenuNum, cmd_set_distribution_type);
X}
X
X
Xstatic void install_variables()
X{
X   install_variable_option("patience_threshold", SetMenuNum, VFloat,
X			   (int *) &active_options.patience_threshold);
X   install_variable_option("patience_counter", SetMenuNum, VInt,
X			   (int *) &active_options.patience_counter);
X   install_variable_option("validation_stop", SetMenuNum, VInt,
X			   (int *) &active_options.validation_stop);
X   install_variable_option("tree_size_limit", SetMenuNum, VInt,
X			   (int *) &active_options.tree_size_limit);
X   install_variable_option("stop_depth", SetMenuNum, VInt,
X			   (int *) &active_options.stop_depth);
X   install_variable_option("stop_z", SetMenuNum, VInt,
X			   (int *) &active_options.stop_z);
X   install_variable_option("print_distributions", SetMenuNum, VInt,
X			   (int *) &active_options.print_distributions);
X   install_variable_option("mofn_level", SetMenuNum, VFloat,
X			   (int *) &active_options.mofn_level);
X}
X
X
Xvoid run_commands(in_stream)
X   FILE *in_stream;
X{
X   int mnum = NoMenuNum;
X   OptionRec *match;
X   char *str;
X
X   while (TRUE)
X   {
X      str = get_next_string(in_stream);
X      match = find_match(str, menu_list[mnum]);
X      if (match)
X      {
X	 switch (match->otype)
X	 {
X	    case ONewMenu:
X	       mnum = match->menunum;
X	       break;
X	    case OVariable:
X	       if (!read_variable(in_stream, match->vartype, match->varptr))
X	       {
X		  sprintf(err_buffer, "Failed to read value for %s",
X			  match->name);
X		  error(prog_name, err_buffer, TRUE);
X	       }
X	       mnum = NoMenuNum;
X	       break;
X	    case OCommand:
X	       (*match->func)(in_stream);
X	       mnum = NoMenuNum;
X	       break;
X	    case OShowVariable:
X	       printf("%s = ",match->name);
X	       show_variable(match->vartype, match->varptr);
X	       printf("\n");
X	       mnum = NoMenuNum;
X	       break;
X	 }
X      }
X      else
X	 mnum = NoMenuNum;
X   }
X}
X
X
Xvoid init_command_handling()
X{
X   init_menus();
X   install_commands();
X   install_variables();
X
X   install_user_commands();
X   install_user_variables();
X}
X
X
END-of-command.c
echo x - examples-exp.h
sed 's/^X//' >examples-exp.h << 'END-of-examples-exp.h'
X#define MAX_ATTR_VALUES		256
X#define MEAN_INDEX		0
X#define SIGMA_INDEX		1
X#define NULL_ATTR		-1
X#define NONE			-1
X
X
Xtypedef enum attr_type {NOMINAL_ATTR, REAL_ATTR,
X			BOOLEAN_ATTR, VECTOR_ATTR} AttributeType;
X
X
Xtypedef struct
X{
X   int num_levels;
X   int *level_counts;
X   Order *order;
X} Stratification;
X
X
Xtypedef struct
X{
X   int num_states;
X   int *num_parameters;
X   int *num_examples;
X   float **parameters;
X} Distribution;
X
X
Xtypedef struct
X{
X   float min;
X   float max;
X} Range;
X
X
Xtypedef struct
X{
X   int size;
X   float **vectors;
X} Map;
X
X
Xtypedef struct
X{
X   AttributeType type;			/* type of the attribute */
X   char *name;				/* name of the attribute */
X   int num_values;			/* number of possible values for
X					   discete attribute; should be set
X					   to 1 for real attribute */
X   char **labels;			/* names of values for discrete att */
X   Map *map;				/* input-vector representation of
X					   discrete values */
X   Range *range;
X   int dependency;
X   char relevant;
X   Distribution *distribution;
X} Attribute;
X
X
Xtypedef struct
X{
X   int number;					/* number of attributes */
X   int class_index;				/* index of class attribute */
X   int num_classes;				/* number of classes */
X   Attribute *attributes;			/* attribute descriptors */
X   Stratification *stratification;		/* obsolete field */
X} AttributeInfo;
X
X
Xtypedef union
X{
X   float real;
X   float *vector;
X   int discrete;
X} ValueType;
X
X
Xtypedef struct
X{
X   char missing;
X   ValueType value;
X} Value;
X
X
Xtypedef struct
X{
X   char *name;			/* name of example */
X   Value *values;		/* array of values -- one per attribute */
X   Value oracle;		/* cached value of membership query */
X   int fold;
X} Example;
X
X
Xtypedef struct
X{
X   int number;			/* number of examples actually loaded */
X   int size;			/* size of data structure */ 
X   int test_fold;
X   Example *examples;		/* example descriptors */
X} ExampleInfo;
X
X
X#define Get_Class(ex, attr_info) ((int)(ex)->values[(attr_info)->class_index].value.discrete)
X
X#define ClassIsVector(attr_info) ((attr_info)->attributes[(attr_info)->class_index].type == VECTOR_ATTR)
X  
X
Xextern void		assign_to_folds();
Xextern void		free_attributes();
Xextern void		free_examples();
Xextern void		read_attribute_dependencies();
Xextern void		reset_fold_info();
X
END-of-examples-exp.h
echo x - examples.c
sed 's/^X//' >examples.c << 'END-of-examples.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <string.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X
X
Xextern char *strdup();
X
X
X
Xvoid free_examples(ex_info, attr_info)
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X{
X   int i;
X
X   for (i = 0; i < ex_info->size; ++i)
X   {
X      check_free((void *) ex_info->examples[i].name);
X
X      if (ClassIsVector(attr_info))
X         check_free((void *)
X	      ex_info->examples[i].values[attr_info->class_index].value.vector);
X
X      check_free((void *) ex_info->examples[i].values);
X   }
X
X   check_free((void *) ex_info->examples);
X   ex_info->number = 0;
X   ex_info->test_fold = NONE;
X}
X
X
Xvoid free_attributes(attr_info)
X   AttributeInfo *attr_info;
X{
X   int i, j;
X   Attribute *attribute;
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      if (attribute->type == NOMINAL_ATTR)
X      {
X         for (j = 0; j < attr_info->number; ++j)
X            check_free((void *) attribute->labels[j]);
X         check_free((void *) attribute->labels);
X         check_free((void *) attribute->map);
X      }
X      else if (attribute->type == REAL_ATTR)
X      {
X         check_free((void *) attribute->range);
X      }
X
X      check_free((void *) attribute->name);
X   }
X
X   check_free((void *) attr_info->attributes);
X   attr_info->number = 0;
X}
X
X
Xvoid reset_fold_info(examples)
X   ExampleInfo *examples;
X{
X   int i;
X
X   for (i = 0; i < examples->number; ++i)
X      examples->examples[i].fold = 0;
X
X   examples->test_fold = NONE;
X}
X
X
Xvoid assign_to_folds(examples, num_folds)
X   ExampleInfo *examples;
X   int num_folds;
X{
X   Order *order;
X   int fold;
X   int i;
X
X   order = (Order *) check_malloc(sizeof(Order) * examples->number);
X   for (i = 0; i < examples->number; ++i)
X   {
X      order[i].index = i;
X      order[i].value = my_random();
X   }
X   qsort((char *) order, examples->number, sizeof(Order), order_compare);
X
X   for (i = 0; i < examples->number; ++i)
X   {
X      fold = num_folds * i / examples->number;
X      examples->examples[order[i].index].fold = fold;
X   }
X
X   check_free((void *) order);
X}
X
X
X
END-of-examples.c
echo x - main.c
sed 's/^X//' >main.c << 'END-of-main.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <math.h>
X#include <string.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "tree.h"
X#include "command-exp.h"
X
X
X
Xmain(argc, argv)
X   int argc;
X   char **argv;
X{
X   long int random_seed = DEFAULT_SEED;
X   FILE *in_stream = stdin;
X
X   if (prog_name = strrchr(argv[0], '/'))
X      ++prog_name;
X   else
X      prog_name = argv[0];
X
X   if (argc == 2)
X   {
X      in_stream = check_fopen(argv[1], "r");
X   }
X   else if (argc > 2)
X   {
X      sprintf(err_buffer, "%s [command-file]", prog_name);
X      error("usage", err_buffer, TRUE);
X   }
X
X   my_srandom(random_seed);
X   init_data_structures();
X   init_command_handling();
X   run_commands(in_stream);
X}
X
X
END-of-main.c
echo x - mofn-exp.h
sed 's/^X//' >mofn-exp.h << 'END-of-mofn-exp.h'
X
X/* exported functions */
Xextern Split		*ID2_of_3_beam();
Xextern Split		*ID2_of_3_hill_climb();
Xextern void		mofn_plus_1();
Xextern void		m_plus_1_of_n_plus_1();
END-of-mofn-exp.h
echo x - mofn-int.h
sed 's/^X//' >mofn-int.h << 'END-of-mofn-int.h'
X
Xtypedef struct
X{
X   Split *head;
X   Split *tail;
X   int n;
X   int width;
X} Beam;
X
END-of-mofn-int.h
echo x - mofn.c
sed 's/^X//' >mofn.c << 'END-of-mofn.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <math.h>
X#include <string.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "tree.h"
X#include "sample-exp.h"
X#include "mofn-int.h"
X#include "stats-exp.h"
X
X
X
Xstatic int same_member(a, b)
X   Member *a;
X   Member *b;
X{
X   if (a->attribute != b->attribute)
X      return(FALSE);
X
X   if (a->type == REAL_ATTR)
X   {
X      if (a->value.real != b->value.real)
X	 return(FALSE);
X
X      if (a->negated != b->negated)
X	 return(FALSE);
X   }
X   else if (a->value.discrete != b->value.discrete)
X      return(FALSE);
X
X   return(TRUE);
X}
X
X
Xstatic int same_split(a, b)
X   Split *a;
X   Split *b;
X{
X   Member *a_member, *b_member;
X   int match;
X
X   if (a->type != b->type)
X      return(FALSE);
X   else if (a->type == NOMINAL_SPLIT)
X   {
X      if (Get_Nominal_Attr(a) == Get_Nominal_Attr(b))
X	 return(TRUE);
X      else
X	 return(FALSE);
X   }
X   else if (a->type == M_OF_N_SPLIT)
X   {
X      if (Get_M(a) != Get_M(b))
X         return(FALSE);
X
X      /* check to see if they have the same number of values */
X      a_member = Get_Members(a);
X      b_member = Get_Members(b);
X      while (a_member && b_member)
X      {
X         a_member = a_member->next;
X         b_member = b_member->next;
X      }
X      if (a_member || b_member)
X	 return(FALSE);
X
X      a_member = Get_Members(a);
X      while (a_member)
X      {
X         b_member = Get_Members(b);
X         match = FALSE;
X         while (!match && b_member)
X         {
X            if (same_member(a_member, b_member))
X	       match = TRUE;
X            b_member = b_member->next;
X         }
X         if (!match)
X	    return(FALSE);
X
X         a_member = a_member->next;
X      }
X
X      return(TRUE);
X   }
X   else if (a->type == REAL_SPLIT)
X   {
X      if (Get_Real_Attr(a) == Get_Real_Attr(b) &&
X	  Get_Threshold(a) == Get_Threshold(b))
X	 return(TRUE);
X      else
X	 return(FALSE);
X   }
X   else if (a->type == BOOLEAN_SPLIT)
X   {
X      if (Get_Boolean_Attr(a) == Get_Boolean_Attr(b) &&
X	  Get_Boolean_Value(a) == Get_Boolean_Value(b))
X	 return(TRUE);
X      else
X	 return(FALSE);
X   }
X   else
X   {
X      error("System error", "bad split type in same_split", TRUE);
X   }
X}
X
X
Xstatic Split *split_already_in_list(split, list)
X   Split *split;
X   Split *list;
X{
X   while (list)
X   {
X      if (same_split(split, list))
X	 return(list);
X
X      list = list->next;
X   }
X
X   return(FALSE);
X}
X
X
XSplit *copy_split(attr_info, split)
X   AttributeInfo *attr_info;
X   Split *split;
X{
X   Split *new_one;
X   Member *member, *new_member;
X   Member *list = NULL;
X   Member *last_member = NULL;
X   int i, j;
X
X   new_one = get_new_split(split->type, split->arity, attr_info);
X   new_one->gain = split->gain;
X
X   for (i = 0; i < split->arity; ++i)
X      for (j = 0; j < attr_info->num_classes; ++j)
X	 new_one->class_distr[i][j] = split->class_distr[i][j];
X
X   if (split->type == NOMINAL_SPLIT)
X   {
X      new_one->type_specific.nominal.attribute = Get_Nominal_Attr(split);
X   }
X   else if (split->type == M_OF_N_SPLIT)
X   {
X      new_one->type_specific.mofn.m = split->type_specific.mofn.m;
X      new_one->type_specific.mofn.sample_key = UNINITIALIZED_KEY; 
X      member = split->type_specific.mofn.members;
X      while (member)
X      {
X         new_member = (Member *) check_malloc(sizeof(Member));
X	 memcpy((void *) new_member, (void *) member, sizeof(Member));
X	 /* keep list in same order */
X	 new_member->next = NULL;
X	 if (last_member)
X	    last_member->next = new_member;
X	 else
X	    list = new_member;
X	 last_member = new_member;
X
X         member = member->next;
X      }
X      new_one->type_specific.mofn.members = list;
X   }
X   else if (split->type == REAL_SPLIT)
X   {
X      new_one->type_specific.real.attribute = Get_Real_Attr(split);
X      new_one->type_specific.real.threshold = Get_Threshold(split);
X   }
X   else if (split->type == BOOLEAN_SPLIT)
X   {
X      new_one->type_specific.boolean.attribute = Get_Boolean_Attr(split);
X      new_one->type_specific.boolean.value = Get_Boolean_Value(split);
X      new_one->type_specific.boolean.bool_attr = Is_Boolean_Attr(split);
X   }
X   else
X   {
X      error("system error", "bad split type in copy_split", TRUE);
X   }
X
X   return(new_one);
X}
X
X
Xstatic char **copy_and_update_used_structure(attr_info, source, copy, split)
X   AttributeInfo *attr_info;
X   char **source;
X   char **copy;
X   Split *split;
X{
X   int i, j;
X   Member *member;
X   Attribute *attribute;
X
X   if (!copy)
X   {
X      copy = (char **) check_malloc(sizeof(char *) * attr_info->number);
X      for (i = 0; i < attr_info->number; ++i)
X      {
X         if (source[i])
X	 {
X            attribute = &attr_info->attributes[i];
X	    copy[i] = check_malloc(sizeof(char) * attribute->num_values);
X	 }
X	 else
X	    copy[i] = NULL;
X      }
X   }
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (source[i])
X      {
X         attribute = &attr_info->attributes[i];
X	 for (j = 0; j < attribute->num_values; ++j)
X	    copy[i][j] = source[i][j];
X      }
X
X   if (split->type == M_OF_N_SPLIT)
X   {
X      member = Get_Members(split);
X      while (member)
X      {
X	 if (member->type != REAL_ATTR)
X	    copy[member->attribute][member->value.discrete] = TRUE;
X	 member = member->next;
X      }
X   }
X   else
X   {
X      error("system error",
X	    "only m-of-n splits handled in copy_and_update_used_structure",
X	    TRUE);
X   }
X
X   return(copy);
X}
X
X
Xstatic void free_used_structure(attr_info, used)
X   AttributeInfo *attr_info;
X   char **used;
X{
X   int i;
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (used[i])
X	 check_free((void *) used[i]);
X
X   check_free((void *) used);
X}
X
X
Xstatic Member *remove_attribute(list, index)
X   Member *list;
X   int index;
X{
X   Member *member, *last_member, *temp;
X
X   last_member = NULL;
X   member = list; 
X   while (member)
X   {
X      if (member->attribute == index)
X      {
X         if (last_member)
X            last_member->next = member->next;
X         else
X            list = member->next;
X         temp = member;
X         member = member->next;
X         check_free((void *) temp);
X      }
X      else
X      {
X         last_member = member;
X         member = member->next;
X      }
X   }
X
X   return(list);
X}
X
X
Xstatic int superfluous_real_splits(member)
X   Member *member;
X{
X   Member *temp;
X
X   temp = member->next;
X   while (temp)
X   {
X      if (temp->attribute == member->attribute &&
X          temp->value.real == member->value.real)
X	 return(TRUE);
X
X      temp = temp->next;
X   }
X
X   return(FALSE);
X}
X
X
Xstatic void remove_superfluous_values(attr_info, split, base_used)
X   AttributeInfo *attr_info;
X   Split *split;
X   char **base_used;
X{
X   int all_values_in_split;
X   int i, j;
X   char **used;
X   Attribute *attribute;
X   Member *member, *last_member;
X
X   used = copy_and_update_used_structure(attr_info, base_used,
X					 (char **) NULL, split);
X
X   /* check discrete-valued attributes */
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      if (attribute->type != REAL_ATTR && used[i])
X      {
X	 all_values_in_split = TRUE;
X	 for (j = 0; j < attribute->num_values; ++j)
X	 {
X	    if (!used[i][j])
X	    {
X	       all_values_in_split = FALSE;
X	       break;
X	    }
X	 }
X
X	 if (all_values_in_split)
X	 {
X            --split->type_specific.mofn.m;
X            split->type_specific.mofn.members =
X	       remove_attribute(split->type_specific.mofn.members, i);
X	 }
X      }
X   }
X
X   /* check real-valued attributes */
X   last_member = NULL;
X   member = split->type_specific.mofn.members;
X   while (member)
X   {
X      if (member->type == REAL_ATTR && superfluous_real_splits(member))
X      {
X         --split->type_specific.mofn.m;
X	 member = remove_attribute(member, member->attribute);
X	 if (last_member)
X            last_member->next = member; 
X	 else
X            split->type_specific.mofn.members = member;
X      }
X      else
X      {
X         last_member = member;
X         member = member->next;
X      }
X   }
X
X   free_used_structure(attr_info, used);
X}
X
X
Xstatic void insert_split_in_beam(split, beam)
X   Split *split;
X   Beam *beam;
X{
X   Split *current, *temp;
X
X   if (split->type == M_OF_N_SPLIT)
X      split->type_specific.mofn.expanded = FALSE;
X
X   if (beam->head == NULL)
X   {
X      beam->head = beam->tail = split;
X      beam->n = 1;
X   }
X   else
X   {
X      /* find the right spot in the beam */
X      current = beam->head;
X      while (current && current->gain >= split->gain)
X         current = current->next;
X
X      if (current && !split_already_in_list(split, beam->head))
X      {
X         /* add the split to the beam */
X         split->prev = current->prev;
X         split->next = current;
X         current->prev = split;
X         if (split->prev)
X	    split->prev->next = split;
X         else
X	    beam->head = split;
X
X         /* bump a split out of the beam if necessary */
X         if (beam->n == beam->width)
X         {
X            beam->tail->prev->next = NULL;
X	    temp = beam->tail;
X            beam->tail = beam->tail->prev;
X            free_split(temp);
X         }
X         else
X         {
X            ++beam->n;
X         }
X      }
X      else if (beam->n < beam->width &&
X	       !split_already_in_list(split, beam->head))
X      {
X         split->prev = beam->tail; 
X         split->next = NULL;
X         beam->tail->next = split;
X	 beam->tail = split;
X         ++beam->n;
X      }
X      else
X      {
X         free_split(split);
X      }
X   }
X}
X
X
Xstatic int splits_significantly_different(attr_info, old_split,
X					  new_split, options)
X   AttributeInfo *attr_info;
X   Split *old_split;
X   Split *new_split;
X   Options *options;
X{
X   int degrees;
X   float chi_square_value;
X   float prob;
X
X   chi_square(old_split->class_distr[0], new_split->class_distr[0],
X	      attr_info->num_classes, 0, &degrees, &chi_square_value, &prob);
X
X/*
Xprintf("(%.0f, %.0f) (%.0f, %.0f)\tChi Square value = %f\n",
X       old_split->class_distr[0][0], old_split->class_distr[0][1],
X       new_split->class_distr[0][0], new_split->class_distr[0][1], prob);
X*/
X
X   new_split->type_specific.mofn.chi_square_prob = prob;
X
X   if (prob < options->mofn_level)
X      return(TRUE);
X   else
X      return(FALSE);
X}
X
X
Xstatic void evaluate_candidate(attr_info, ex_info, ex_mask, options,
X			       beam, used, split, old_split)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X   Beam *beam;
X   char **used;
X   Split *split;
X   Split *old_split;
X{
X
X   remove_superfluous_values(attr_info, split, used);
X
X   if (Get_M(split) == 0 || Get_Members(split) == NULL)
X      free_split(split);
X   else
X   {
X      evaluate_splits(attr_info, ex_info, ex_mask, options, split);
X
X      if (!trivial_split(split, options->min_objects) &&
X          splits_significantly_different(attr_info, old_split, split,options) &&
X	  (!options->do_sampling ||
X	   !trivial_split_when_sampling(split, ex_info, ex_mask, options)))
X         insert_split_in_beam(split, beam);
X      else
X         free_split(split);
X   }
X}
X
X
Xstatic int okay_to_add_discrete(to_add, used)
X   Split *to_add;
X   char **used;
X{
X   int attr_index;
X   int value;
X
X   if (to_add->type != BOOLEAN_SPLIT)
X      error("System error", "bad split type in okay_to_add_discrete", TRUE);
X
X   if (!to_add->can_use)
X      return(FALSE);
X
X   attr_index = Get_Boolean_Attr(to_add);
X   value = Get_Boolean_Value(to_add);
X   if (!used[attr_index])
X      return(FALSE);
X   
X   if (!Is_Boolean_Attr(to_add) && used[attr_index][value])
X      return(FALSE);
X
X   return(TRUE);
X}
X
X
Xstatic int okay_to_add_real(current, to_add, used, other)
X   Split *current;
X   Split *to_add;
X   char **used;
X   Member **other;
X{
X   Member *member;
X   int attr_index;
X
X   if (to_add->type != REAL_SPLIT)
X      error("System error", "bad split type in okay_to_add_real", TRUE);
X
X   if (!to_add->can_use)
X      return(FALSE);
X
X   attr_index = Get_Real_Attr(to_add);
X   if (!used[attr_index])
X      return(FALSE);
X
X   /* disallow if there are alreay 2 conditions for this attribute */
X   *other = NULL;
X   for (member = Get_Members(current); member != NULL; member = member->next)
X   {
X      if (member->attribute == attr_index)
X      {
X         if (*other)
X            return(FALSE);
X         else
X            *other = member;
X      }
X   }
X
X   return(TRUE);
X}
X
X
Xstatic int okay_together(to_add, negated, other)
X   Split *to_add;
X   Member *other;
X   char negated;
X{
X   if (!other)
X      return(TRUE);
X
X   /* make sure new condition isn't implied by exisiting one */
X   if (other->negated == FALSE && negated == FALSE)
X   {
X      if (Get_Threshold(to_add) <= other->value.real)
X         return(FALSE);
X   }
X   else if (other->negated == TRUE && negated == TRUE)
X   {
X      if (Get_Threshold(to_add) > other->value.real)
X         return(FALSE);
X   }
X
X   return(TRUE);
X}
X
X
Xvoid mofn_plus_1(attr_info, ex_info, ex_mask, options, 
X		 beam, current, splits, used)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X   Beam *beam;
X   Split *current;
X   Split *splits;
X   char **used;
X{
X   int attr_index;
X   Split *new_split, *to_add;
X   Member *new_member;
X   Member *other;
X
X   to_add = splits;
X   while (to_add)
X   {
X      attr_index = Get_Boolean_Attr(to_add);
X      if (to_add->type == REAL_SPLIT)
X      {
X	 other = NULL;
X	 if (okay_to_add_real(current, to_add, used, &other))
X	 {
X            if (!other || okay_together(to_add, FALSE, other))
X	    {
X               new_split = copy_split(attr_info, current);
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Real_Attr(to_add);
X               new_member->value.real = Get_Threshold(to_add); 
X               new_member->type = REAL_ATTR; 
X               new_member->negated = FALSE; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X
X            if (!other || okay_together(to_add, TRUE, other))
X	    {
X               new_split = copy_split(attr_info, current);
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Real_Attr(to_add);
X               new_member->value.real = Get_Threshold(to_add); 
X               new_member->type = REAL_ATTR; 
X               new_member->negated = TRUE; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X	 }
X      }
X      else if (Is_Boolean_Attr(to_add))
X      {
X	 if (okay_to_add_discrete(to_add, used))
X         {
X	    /* make a new split where boolean is false */
X	    if (!used[attr_index][0])
X	    {
X               new_split = copy_split(attr_info, current);
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Boolean_Attr(to_add);
X               new_member->value.discrete = 0; 
X               new_member->type = BOOLEAN_ATTR; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X
X	    /* make a new split where boolean is true */
X	    if (!used[attr_index][1])
X	    {
X               new_split = copy_split(attr_info, current);
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Boolean_Attr(to_add);
X               new_member->value.discrete = 1; 
X               new_member->type = BOOLEAN_ATTR; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X         }
X      }
X      else
X      {
X	 if (okay_to_add_discrete(to_add, used))
X         {
X            new_split = copy_split(attr_info, current);
X            new_member = (Member *) check_malloc(sizeof(Member));
X            new_member->attribute = Get_Boolean_Attr(to_add);
X            new_member->value.discrete = Get_Boolean_Value(to_add);
X            new_member->type = NOMINAL_ATTR; 
X            new_member->next = new_split->type_specific.mofn.members;
X	    new_split->type_specific.mofn.members = new_member;
X            evaluate_candidate(attr_info, ex_info, ex_mask, options,
X			       beam, used, new_split, current);
X         }
X      }
X
X      to_add = to_add->next;
X   }
X}
X
X
Xvoid m_plus_1_of_n_plus_1(attr_info, ex_info, ex_mask, options,
X		          beam, current, splits, used)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X   Beam *beam;
X   Split *current;
X   Split *splits;
X   char **used;
X{
X   int attr_index;
X   Split *new_split, *to_add;
X   Member *new_member;
X   Member *other;
X
X   to_add = splits;
X   while (to_add)
X   {
X      attr_index = Get_Boolean_Attr(to_add);
X      if (to_add->type == REAL_SPLIT)
X      {
X	 other = NULL;
X	 if (okay_to_add_real(current, to_add, used, &other))
X	 {
X            if (!other || okay_together(to_add, FALSE, other))
X	    {
X               new_split = copy_split(attr_info, current);
X	       new_split->type_specific.mofn.m += 1;
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Real_Attr(to_add);
X               new_member->value.real = Get_Threshold(to_add); 
X               new_member->type = REAL_ATTR; 
X               new_member->negated = FALSE; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X
X            if (!other || okay_together(to_add, TRUE, other))
X	    {
X               new_split = copy_split(attr_info, current);
X	       new_split->type_specific.mofn.m += 1;
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Real_Attr(to_add);
X               new_member->value.real = Get_Threshold(to_add); 
X               new_member->type = REAL_ATTR; 
X               new_member->negated = TRUE; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X	 }
X      }
X      else if (Is_Boolean_Attr(to_add))
X      {
X	 if (okay_to_add_discrete(to_add, used))
X	 {
X	    /* make a new split where boolean is false */
X	    if (!used[attr_index][0])
X	    {
X               new_split = copy_split(attr_info, current);
X	       new_split->type_specific.mofn.m += 1;
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Boolean_Attr(to_add);
X               new_member->value.discrete = 0; 
X               new_member->type = BOOLEAN_ATTR; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X
X	    /* make a new split where boolean is true */
X	    if (!used[attr_index][1])
X	    {
X               new_split = copy_split(attr_info, current);
X	       new_split->type_specific.mofn.m += 1;
X               new_member = (Member *) check_malloc(sizeof(Member));
X               new_member->attribute = Get_Boolean_Attr(to_add);
X               new_member->value.discrete = 1; 
X               new_member->type = BOOLEAN_ATTR; 
X               new_member->next = new_split->type_specific.mofn.members;
X	       new_split->type_specific.mofn.members = new_member;
X               evaluate_candidate(attr_info, ex_info, ex_mask, options,
X				  beam, used, new_split, current);
X	    }
X         }
X      }
X      else
X      {
X	 if (okay_to_add_discrete(to_add, used))
X         {
X            new_split = copy_split(attr_info, current);
X	    new_split->type_specific.mofn.m += 1;
X            new_member = (Member *) check_malloc(sizeof(Member));
X            new_member->attribute = Get_Boolean_Attr(to_add);
X            new_member->value.discrete = Get_Boolean_Value(to_add);
X            new_member->type = NOMINAL_ATTR; 
X            new_member->next = new_split->type_specific.mofn.members;
X	    new_split->type_specific.mofn.members = new_member;
X            evaluate_candidate(attr_info, ex_info, ex_mask, options,
X			       beam, used, new_split, current);
X         }
X      }
X
X      to_add = to_add->next;
X   }
X}
X
X
Xstatic Split *real_to_mofn_split(attr_info, real_split, complement_split)
X   AttributeInfo *attr_info;
X   Split *real_split;
X   int complement_split;
X{
X   Split *mofn_split;
X   Member *member;
X   int i;
X
X   mofn_split = get_new_split(M_OF_N_SPLIT, 2, attr_info);
X   mofn_split->gain = real_split->gain;
X   mofn_split->type_specific.mofn.sample_key = UNINITIALIZED_KEY; 
X   mofn_split->type_specific.mofn.chi_square_prob = 0.0; 
X
X   member = (Member *) check_malloc(sizeof(Member));
X   member->attribute = Get_Real_Attr(real_split);
X   member->value.real = Get_Threshold(real_split); 
X   member->type = REAL_ATTR;
X   member->negated = (char) complement_split;
X   member->next = NULL;
X
X   mofn_split->type_specific.mofn.members = member;
X   mofn_split->type_specific.mofn.m = 1;
X
X   for (i = 0; i < attr_info->num_classes; ++i)
X      if (complement_split)
X      {
X	 mofn_split->class_distr[0][i] = real_split->class_distr[1][i];
X	 mofn_split->class_distr[1][i] = real_split->class_distr[0][i];
X      }
X      else
X      {
X	 mofn_split->class_distr[0][i] = real_split->class_distr[0][i];
X	 mofn_split->class_distr[1][i] = real_split->class_distr[1][i];
X      }
X
X   return(mofn_split);
X}
X
X
Xstatic Split *boolean_to_mofn_split(attr_info, boolean_split, complement_split)
X   AttributeInfo *attr_info;
X   Split *boolean_split;
X   int complement_split;
X{
X   Split *mofn_split;
X   Member *member;
X   Attribute *attribute;
X   int i;
X
X   mofn_split = get_new_split(M_OF_N_SPLIT, 2, attr_info);
X   mofn_split->gain = boolean_split->gain;
X   mofn_split->type_specific.mofn.sample_key = UNINITIALIZED_KEY; 
X   mofn_split->type_specific.mofn.chi_square_prob = 0.0; 
X   attribute = &attr_info->attributes[Get_Boolean_Attr(boolean_split)];
X
X   if (attribute->type == BOOLEAN_ATTR)
X   {
X      member = (Member *) check_malloc(sizeof(Member));
X      member->attribute = Get_Boolean_Attr(boolean_split);
X      member->value.discrete = complement_split ?
X			       1 - Get_Boolean_Value(boolean_split) :
X			       Get_Boolean_Value(boolean_split);
X      member->type = attribute->type;
X      member->next = NULL;
X      mofn_split->type_specific.mofn.members = member;
X   }
X   else
X   {
X      if (complement_split)
X      {
X         mofn_split->type_specific.mofn.members = NULL;
X	 for (i = 0; i < attribute->num_values; ++i)
X	    if (i != Get_Boolean_Value(boolean_split))
X	    {
X               member = (Member *) check_malloc(sizeof(Member));
X               member->attribute = Get_Boolean_Attr(boolean_split);
X               member->value.discrete = i;
X               member->type = attribute->type;
X               member->next = mofn_split->type_specific.mofn.members;
X               mofn_split->type_specific.mofn.members = member;
X	    }
X      }
X      else
X      {
X         member = (Member *) check_malloc(sizeof(Member));
X         member->attribute = Get_Boolean_Attr(boolean_split);
X         member->value.discrete = Get_Boolean_Value(boolean_split);
X         member->type = attribute->type;
X         member->next = NULL; 
X         mofn_split->type_specific.mofn.members = member;
X      }
X   }
X
X   mofn_split->type_specific.mofn.m = 1;
X
X   for (i = 0; i < attr_info->num_classes; ++i)
X      if (complement_split)
X      {
X	 mofn_split->class_distr[0][i] = boolean_split->class_distr[1][i];
X	 mofn_split->class_distr[1][i] = boolean_split->class_distr[0][i];
X      }
X      else
X      {
X	 mofn_split->class_distr[0][i] = boolean_split->class_distr[0][i];
X	 mofn_split->class_distr[1][i] = boolean_split->class_distr[1][i];
X      }
X
X   return(mofn_split);
X}
X
X
Xstatic char **make_used_structure(attr_info, constraints, constrain_attributes)
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   int constrain_attributes;
X{
X   char **used;
X   Constraint *constraint;
X   Split *split;
X   int can_use;
X   int i, j;
X   Attribute *attribute;
X
X   used = (char **) check_malloc(sizeof(char *) * attr_info->number);
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      can_use = TRUE;
X      constraint = constraints[i];
X      while (constraint)
X      {
X	 split = constraint->split;
X	 if ((split->type == M_OF_N_SPLIT && constrain_attributes) ||
X	     (split->type == BOOLEAN_SPLIT && Is_Boolean_Attr(split)))
X	 {
X	    can_use = FALSE;
X	    break;
X	 }
X         constraint = constraint->next;
X      }
X
X      if (can_use)
X      {
X	 attribute = &attr_info->attributes[i];
X	 used[i] = check_malloc(sizeof(char) * attribute->num_values);
X
X	 if (attribute->type == REAL_ATTR)
X	 {
X	    used[i][0] = TRUE;
X	 }
X	 else
X	 {
X	    for (j = 0; j < attribute->num_values; ++j)
X	       used[i][j] = FALSE;
X
X            /* determine which values can't be used */
X            constraint = constraints[i];
X            while (constraint)
X            {
X	       split = constraint->split;
X	       if (split->type == BOOLEAN_SPLIT)
X	          used[i][Get_Boolean_Value(split)] = TRUE;
X	       constraint = constraint->next;
X            }
X	 }
X      }
X      else
X	 used[i] = NULL;
X
X   }
X
X   return(used);
X}
X
X
Xstatic void print_beam(attr_info, beam)
X   AttributeInfo *attr_info;
X   Beam *beam;
X{
X   Split *split;
X   int i;
X
X   printf("========== BEAM HAS %d SPLITS ==========\n\n", beam->n);
X
X   split = beam->head;
X   while (split)
X   {
X      print_split(split, attr_info, 0, stdout);
X      printf(" gain=%f", split->gain);
X      if (split->type == M_OF_N_SPLIT)
X	 printf("  chi=%f\n", split->type_specific.mofn.chi_square_prob);
X      else
X	 printf("\n");
X
X      printf("\tpos\tneg\n");
X      for (i = 0; i < attr_info->num_classes; ++i)
X	 printf("\t%.0f\t%.0f\n", split->class_distr[0][i],
X		split->class_distr[1][i]);
X
X      split = split->next;
X   }
X
X}
X
X
X
Xstatic void merge_beam_levels(beam, next_beam)
X   Beam *beam;
X   Beam *next_beam;
X{
X   Split *current, *next;
X
X   current = next_beam->head;
X   while (current)
X   {
X      next = current->next;
X      insert_split_in_beam(current, beam);
X      current = next;
X   }
X
X   next_beam->n = 0;
X   next_beam->head = next_beam->tail = NULL;
X}
X
X
Xstatic void mofn_beam_search(attr_info, ex_info, ex_mask, options,
X		             splits, beam, base_used)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X   Split *splits;
X   Beam *beam;
X   char **base_used;
X{
X   Split *current;
X   char **used = NULL;
X   int i;
X   int all_expanded;
X   Beam next_beam;
X
X   next_beam.width = beam->width;
X   next_beam.n = 0;
X   next_beam.head = next_beam.tail = NULL;
X
X   do
X   {
X/*
Xprint_beam(attr_info, beam);
X*/
X      all_expanded = TRUE;
X      current = beam->head;
X      while (current)
X      {
X	 if (current->type == M_OF_N_SPLIT &&
X	     !current->type_specific.mofn.expanded)
X	 {
X	    all_expanded = FALSE;
X	    current->type_specific.mofn.expanded = TRUE;
X	    used = copy_and_update_used_structure(attr_info, base_used,
X						  used, current);
X            for (i = 0; i < options->num_mofn_ops; ++i)
X	       (options->mofn_ops[i])(attr_info, ex_info, ex_mask, options,
X				      &next_beam, current, splits, used);
X	 }
X	 current = current->next;
X      }
X
X      merge_beam_levels(beam, &next_beam);
X   } while (!all_expanded);
X
X   if (used)
X      free_used_structure(attr_info, used);
X}
X
X
Xstatic void initialize_beam(attr_info, ex_info, ex_mask, options, splits,
X			    beam, used)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X   Split *splits;
X   Beam *beam;
X   char **used;
X{
X   Split *current, *new_split;
X
X   beam->head = beam->tail = NULL;
X   beam->n = 0;
X
X   evaluate_splits(attr_info, ex_info, ex_mask, options, splits);
X
X/*
Xprint_splits(attr_info, splits, stdout);
X*/
X
X   current = splits;
X   while (current)
X   {
X      if (current->can_use && !trivial_split(current, options->min_objects) &&
X          (!options->do_sampling || !trivial_split_when_sampling(current, ex_info, ex_mask, options)))
X      {
X	 if (current->type == BOOLEAN_SPLIT && used[Get_Boolean_Attr(current)])
X	 {
X            new_split = boolean_to_mofn_split(attr_info, current, FALSE);
X            insert_split_in_beam(new_split, beam);
X            new_split = boolean_to_mofn_split(attr_info, current, TRUE);
X            insert_split_in_beam(new_split, beam);
X	 }
X	 else if (current->type == REAL_SPLIT && used[Get_Real_Attr(current)])
X	 {
X            new_split = real_to_mofn_split(attr_info, current, FALSE);
X            insert_split_in_beam(new_split, beam);
X            new_split = real_to_mofn_split(attr_info, current, TRUE);
X            insert_split_in_beam(new_split, beam);
X	 }
X	 else
X	 {
X	    new_split = copy_split(attr_info, current);
X            insert_split_in_beam(new_split, beam);
X	 }
X      }
X      current = current->next;
X   }
X}
X
X
Xstatic void nth_member(split, n, prev, nth)
X   Split *split;
X   int n;
X   Member **prev;
X   Member **nth;
X{
X   int i;
X
X   *prev = NULL;
X   *nth = Get_Members(split);
X
X   for (i = 0; i < n; ++i)
X   {
X      *prev = *nth;
X      *nth = (*nth)->next;
X   }
X}
X
X
Xstatic void backfit_split(split, attr_info, ex_info, ex_mask, options)
X   Split *split;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Options *options;
X{
X   int count;
X   float best_gain = split->gain;
X   Member *prev, *member;
X   int *value_counts;
X   int improved;
X   int i;
X
X   if (split->next)
X      error("System error", "split is part of a list in backfit_split", TRUE);
X
X   value_counts = (int *) check_malloc(sizeof(int) * attr_info->number);
X   for (i = 0; i < attr_info->number; ++i)
X      value_counts[i] = 0;
X
X   for (count = 0, member = Get_Members(split); member != NULL;
X	++count, member = member->next)
X   {
X      ++value_counts[member->attribute];
X   }
X
X   for (i = count - 1; i >= 0; --i)
X   {
X      improved = FALSE;
X
X      /* find the ith member */
X      nth_member(split, i, &prev, &member);
X
X      /* try deleting the member */
X      if (prev)
X	 prev->next = member->next;
X      else
X	 split->type_specific.mofn.members = member->next;
X
X      /* try new antecedent set with m the same */
X      evaluate_splits(attr_info, ex_info, ex_mask, options, split);
X
X      if (!trivial_split(split, options->min_objects) &&
X	  (!options->do_sampling || !trivial_split_when_sampling(split, ex_info, ex_mask, options)) && split->gain >= best_gain)
X      {
X	 best_gain = split->gain;
X	 improved = TRUE;
X      }
X
X      /* try new antecedent set with m decremented by 1 */
X      --split->type_specific.mofn.m;
X      evaluate_splits(attr_info, ex_info, ex_mask, options, split);
X
X      if (!trivial_split(split, options->min_objects) &&
X	  (!options->do_sampling || !trivial_split_when_sampling(split, ex_info, ex_mask, options)) &&
X	  split->gain >= best_gain)
X      {
X	 best_gain = split->gain;
X	 improved = TRUE;
X      }
X      else
X      {
X         ++split->type_specific.mofn.m;
X      }
X      
X      if (!improved)
X      {
X	 /* put member back on */
X	 if (prev)
X	    prev->next = member;
X	 else
X	    split->type_specific.mofn.members = member;
X      }
X      else
X      {
X	 if (member->type == REAL_ATTR)
X            printf("IMPROVED SPLIT IN BACKFIT by deleting attr=%d, val=%f\n",
X                   member->attribute, member->value.real);
X         else
X            printf("IMPROVED SPLIT IN BACKFIT by deleting attr=%d, val=%d\n",
X                   member->attribute, member->value.discrete);
X      }
X   }
X
X   /* make sure statistics are up to date */
X   evaluate_splits(attr_info, ex_info, ex_mask, options, split);
X
X   check_free((void *) value_counts);
X}
X
X
XSplit *ID2_of_3_beam(attr_info, ex_info, ex_mask, constraints, options, splits)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Constraint **constraints;
X   Options *options;
X   Split *splits;
X{
X   Beam beam;
X   char **used;
X   Split *best_split = NULL;
X
X   beam.width = options->beam_width;
X
X   used = make_used_structure(attr_info, constraints, options->do_sampling);
X
X   initialize_beam(attr_info, ex_info, ex_mask, options, splits, &beam, used);
X   mofn_beam_search(attr_info, ex_info, ex_mask, options, splits, &beam, used);
X
X   free_used_structure(attr_info, used);
X
X   if (!beam.head)
X      return(NULL);
X
X   if (beam.head->type != M_OF_N_SPLIT)
X      best_split = split_already_in_list(beam.head, splits);
X
X   if (best_split)
X   {
X      free_unused_splits(beam.head);
X   }
X   else
X   {
X      free_unused_splits(beam.head->next);
X      best_split = beam.head;
X      best_split->next = NULL;
X   }
X
X   if (best_split && best_split->type == M_OF_N_SPLIT)
X      backfit_split(best_split, attr_info, ex_info, ex_mask, options);
X
X   return(best_split);
X}
X
END-of-mofn.c
echo x - network-exp.h
sed 's/^X//' >network-exp.h << 'END-of-network-exp.h'
X
X
X/* exported functions */
Xextern void		classify_using_network();
Xextern void		get_ensemble();
Xextern void		get_network();
Xextern void		predict_using_network();
Xextern void		register_network_oracle();
Xextern void		set_activation_function();
Xextern void		set_classification_function();
Xextern void		vector_query_network();
END-of-network-exp.h
echo x - network-int.h
sed 's/^X//' >network-int.h << 'END-of-network-int.h'
X
X/* Information about weights in the neural network */
Xtypedef struct 
X{
X   int fromunit;
X   float weight;
X} WeightRec;
X
X
X/* Information about units in the neural network */
Xtypedef struct
X{
X   float bias;
X   float netinput;
X   float activation;
X   int numweights;
X   WeightRec *weights;
X   float (*act_function)();
X} UnitRec;
X
X
X/* Neural network parameters */
Xtypedef struct
X{
X   UnitRec *units;
X   int weights_loaded;
X   int numunits;
X   int numoutputs;
X   int numinputs;
X   int (*classification_function)();
X} NetworkRec;
X
X
Xtypedef struct
X{
X   int number;
X   NetworkRec *nets;
X   float *predictions;	/* one value per network output */
X   float *coeffs;	/* one value per ensemble member */
X   float total;		/* sum of coefficients */
X} Ensemble;
X
X
END-of-network-int.h
echo x - network.c
sed 's/^X//' >network.c << 'END-of-network.c'
X#include <math.h>
X#include <stdio.h>
X#include <stdlib.h>
X#include <string.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "tree.h"
X#include "network-int.h"
X
X
Xstatic NetworkRec active_net = {NULL, FALSE, 0, 0, 0, NULL};
X
Xstatic Ensemble active_ensemble = {0, NULL, NULL, NULL, 0.0};
X
X
X/*
X   The logistic activation function.
X*/
Xstatic float logistic_act(netinput)
X   float netinput;
X{
X   if (netinput > 16.0)
X      return (0.99999989);
X   if (netinput < -16.0)
X      return (0.00000011);
X   return (1.0 / (1.0 + (float) exp((double) ((-1.0) * netinput))));
X}
X
X
Xstatic float linear_act(netinput)
X   float netinput;
X{
X  return(netinput);
X}
X
X
Xstatic float tanh_act(netinput)
X   float netinput;
X{
X  double e_x, e_minus_x;
X  float act;
X
X  e_x = exp((double) netinput);
X  e_minus_x = exp((double) netinput * -1.0);
X
X  act = (e_x - e_minus_x) / (e_x + e_minus_x);
X
X  return(act);
X}
X
X
X
Xstatic int oracle_is_network()
X{
X   if (active_net.numunits)
X      return(TRUE);
X   else
X      return(FALSE);
X}
X
X
Xstatic int oracle_is_ensemble()
X{
X   if (active_ensemble.number)
X      return(TRUE);
X   else
X      return(FALSE);
X}
X
X
Xvoid set_activation_function(name, range)
X   char *name;
X   char *range;
X{
X   int first, last;
X   int i;
X   float (*act_function)();
X
X   if (!oracle_is_network())
X   {
X      error(prog_name,
X	    "activation functions can be set only when oracle is a network",
X	    TRUE);
X   }
X
X   if (range == NULL || Startsame(range, "all"))
X   {
X      first = active_net.numinputs;
X      last = active_net.numunits;
X   }
X   else if (Startsame(range, "hidden"))
X   {
X      first = active_net.numinputs;
X      last = active_net.numunits - active_net.numoutputs;
X   }
X   else if (Startsame(range, "output"))
X   {
X      first = active_net.numunits - active_net.numoutputs;
X      last = active_net.numunits;
X   }
X   else
X   {
X      sprintf(err_buffer, "%s is not a valid range for activation_function",
X	      range);
X      error(prog_name, err_buffer, TRUE);
X   }
X
X   if (Startsame(name, "logistic"))
X      act_function = logistic_act;
X   else if (Startsame(name, "tanh"))
X      act_function = tanh_act;
X   else if (Startsame(name, "linear"))
X      act_function = linear_act;
X   else
X   {
X      sprintf(err_buffer, "%s is not a valid activation function", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X
X   for (i = first; i < last; ++i)
X      active_net.units[i].act_function = act_function;
X}
X
X
Xstatic int one_of_N(network)
X   NetworkRec *network;
X{
X   int i;
X   int first_output = network->numunits - network->numoutputs;
X   int highest;
X
X   highest = first_output;
X   for (i = first_output + 1; i < network->numunits; ++i)
X   {
X      if (network->units[i].activation > network->units[highest].activation)
X	 highest = i;
X   }
X
X   return(highest - first_output);
X}
X
X
Xstatic int threshold_half(network)
X   NetworkRec *network;
X{
X   int first_output = network->numunits - network->numoutputs;
X
X   if (network->units[first_output].activation >= 0.5)
X      return(1);
X   else
X      return(0);
X}
X
X
Xstatic int threshold_zero(network)
X   NetworkRec *network;
X{
X   int first_output = network->numunits - network->numoutputs;
X
X   if (network->units[first_output].activation >= 0.0)
X      return(1);
X   else
X      return(0);
X}
X
X
Xvoid set_classification_function(name)
X   char *name;
X{
X   if (Startsame(name, "threshold_half"))
X      active_net.classification_function = threshold_half;
X   else if (Startsame(name, "threshold_zero"))
X      active_net.classification_function = threshold_zero;
X   else if (Startsame(name, "one_of_N"))
X      active_net.classification_function = one_of_N;
X   else
X   {
X      sprintf(err_buffer, "%s is not a valid classification function", name);
X      error(prog_name, err_buffer, TRUE);
X   }
X}
X
X
Xstatic int determine_ensemble_class(ensemble)
X   Ensemble *ensemble;
X{
X   int i;
X   int num_outputs = ensemble->nets[0].numoutputs;
X   int highest;
X
X   if (num_outputs == 1)
X   {
X      if (ensemble->predictions[0] >= 0.5)
X	 return(1);
X      else
X	 return(0);
X   }
X   else
X   {
X      highest = 0;
X      for (i = 1; i < num_outputs; ++i)
X      {
X         if (ensemble->predictions[i] > ensemble->predictions[highest])
X	    highest = i;
X      }
X
X      return(highest);
X   }
X}
X
X
Xstatic void free_network(network)
X   NetworkRec *network;
X{
X   int i;
X
X   if (!network)
X      return;
X
X   for (i = 0; i < network->numunits; ++i)
X      check_free((void *) network->units[i].weights);
X
X   check_free((void *) network->units);
X
X   bzero((char *) network, (int) sizeof(NetworkRec));
X}
X
X
Xstatic void free_ensemble(ensemble)
X   Ensemble *ensemble;
X{
X   int i;
X
X   if (!ensemble)
X      return;
X
X   for (i = 0; i < ensemble->number; ++i)
X      free_network(&ensemble->nets[i]);
X
X   check_free((void *) ensemble->nets);
X   check_free((void *) ensemble->coeffs);
X   check_free((void *) ensemble->predictions);
X   ensemble->number = 0;
X
X   bzero((char *) ensemble, (int) sizeof(Ensemble));
X}
X
X
Xstatic void free_oracle()
X{
X   if (oracle_is_network())
X      free_network(&active_net);
X   else if (oracle_is_ensemble())
X      free_ensemble(&active_ensemble);
X}
X
X
X/*  Read an integer value from the network file.
X*/
Xstatic void read_def(stream, definition)
X   FILE *stream;
X   int *definition;
X{
X   char string[BUFSIZ];
X
X   if (fscanf(stream, "%s", string) != EOF)
X   {
X      if (!sscanf(string, "%d", definition))
X         error(prog_name, "definition in network file is not an integer", TRUE);
X   }
X   else
X      error(prog_name, "unexpected end of network file encountered", TRUE);
X}
X
X
X/*  Read the definitions part of a network file.
X*/
Xstatic void read_definitions(stream, network)
X   FILE *stream;
X   NetworkRec *network;
X{
X   char string[BUFSIZ];
X   int dummy;
X
X   while (fscanf(stream, "%s", string) != EOF)
X   {
X      if (!strcmp(string, "end"))
X         return;
X
X      if (!strcmp(string, "nunits"))
X         read_def(stream, &(network->numunits));
X      else if (!strcmp(string, "ninputs"))
X         read_def(stream, &(network->numinputs));
X      else if (!strcmp(string, "noutputs"))
X         read_def(stream, &(network->numoutputs));
X      else if (!strcmp(string, "ncopyunits"))
X         read_def(stream, &dummy);
X      else if (!strcmp(string, "noutputstates"))
X         read_def(stream, &dummy);
X      else
X      {
X         sprintf(err_buffer,
X                 "unknown definition - %s - in network file", string);
X         error(prog_name, err_buffer, TRUE);
X      }
X   }
X}
X
X
X/*  Allocate and initialize data structures for network weights.
X*/
Xstatic void make_weights(network, tounitstart, numtounits, fromunitstart,
X                         numfromunits)
X   NetworkRec *network;
X   int tounitstart;
X   int numtounits;
X   int fromunitstart;
X   int numfromunits;
X{
X   int i, j;
X   int offset;
X   WeightRec *new_weights;
X   UnitRec *unit;
X
X   if (numtounits <= 0)
X     error(prog_name, "Negative number of units specifying weights", TRUE);
X   if (numfromunits <= 0)
X     error(prog_name, "Negative number of weights specifying weights", TRUE);
X   if (((tounitstart + numtounits) > network->numunits) || (tounitstart < 0))
X     error(prog_name, "Illegal unit number specifying weights", TRUE);
X   if (((fromunitstart + numfromunits) > network->numunits) ||
X        (fromunitstart < 0))
X     error(prog_name, "Illegal unit number specifying weights", TRUE);
X
X   for (i = 0; i < numtounits; ++i)
X   {
X      unit = &network->units[tounitstart + i];
X
X      if (unit->weights != NULL)
X      {
X         offset = unit->numweights;
X         new_weights = (WeightRec *)
X                      check_malloc(sizeof(WeightRec) * (offset + numfromunits));
X
X         for (j = 0; j < offset; ++j)
X            new_weights[j] = unit->weights[j];
X         check_free((void *) unit->weights);
X         unit->weights = new_weights;
X         unit->numweights = offset + numfromunits;
X
X      }
X      else
X      {
X         offset = 0;
X         unit->weights = (WeightRec *) check_malloc(sizeof(WeightRec) * 
X						    numfromunits);
X         unit->numweights = numfromunits;
X      }
X
X      for (j = 0; j < numfromunits; ++j)
X	 unit->weights[j + offset].fromunit = fromunitstart + j;
X   }
X}
X
X
X/*  Set up a block of network connections.
X*/
Xstatic void read_connections(stream, network)
X   FILE *stream;
X   NetworkRec *network;
X{
X   char string[BUFSIZ];
X   int tou, fru, numto, numfr;
X
X   while (fscanf(stream, "%s", string) != EOF)
X   {
X      if (!strcmp(string, "end"))
X         return;
X
X      if ((string[0] == '%') && (strlen(string) == 2))
X      {
X         if (fscanf(stream,"%d %d %d %d",&tou, &numto, &fru, &numfr) != 4)
X            error(prog_name, "incorrect connection specification", TRUE);
X         make_weights(network, tou, numto, fru, numfr);
X      }
X      else
X      {
X         if (string[0] == '%')
X         {
X            if (fscanf(stream,"%d %d %d %d",&tou,&numto,&fru,&numfr) != 4)
X               error(prog_name, "incorrect connection specification", TRUE);
X            fscanf(stream, "%*s");
X	 }
X         else
X         {
X            tou = fru = 0;
X            numto = numfr = network->numunits;
X         }
X         make_weights(network, tou, numto, fru, numfr);
X      }
X   }
X}
X
X
X
X/*  Allocate data structures for a network.
X*/
Xstatic void make_network(network)
X   NetworkRec *network;
X{
X   int i;
X
X   if (network->numunits <= 0)
X     error(prog_name, "Number of units must be a positive integer", TRUE);
X
X   if (network->numinputs <= 0)
X     error(prog_name, "Number of input units must be positive integer", TRUE);
X
X   if (network->numoutputs <= 0)
X     error(prog_name, "Number of output units must be positive integer", TRUE);
X
X   network->units = (UnitRec *)
X                       check_malloc(sizeof(UnitRec) * network->numunits);
X
X   bzero((char *) network->units, 
X	 (int) sizeof(UnitRec) * network->numunits);
X
X   for (i = 0; i < network->numinputs; ++i)
X      network->units[i].act_function = NULL;
X   for ( ; i < network->numunits; ++i)
X      network->units[i].act_function = logistic_act;
X}
X
X
X/*
X   Read a PDP-format network file.
X*/
Xstatic void read_network(fname, network)
X   char *fname;
X   NetworkRec *network;
X{
X   FILE *stream;
X   char string[BUFSIZ];
X
X   stream = check_fopen(fname, "r");
X
X   while (fscanf(stream, "%s", string) != EOF)
X   {
X      if (!strcmp(string, "definitions:"))
X      {
X         read_definitions(stream, network);
X         make_network(network);
X      }
X      else if (!strcmp(string, "constraints:"))
X      {
X        while ((fscanf(stream, "%s", string) != EOF) && (strcmp(string, "end")))
X            ;
X      }
X      else if (!strcmp(string, "network:"))
X      {
X         read_connections(stream, network);
X      }
X      else if (!strcmp(string, "biases:"))
X      {
X        while ((fscanf(stream, "%s", string) != EOF) && (strcmp(string, "end")))
X            ;
X      }
X      else
X      {
X         sprintf(err_buffer, "unknown network option %s", string);
X         error(prog_name, err_buffer, TRUE);
X      }
X   }
X
X   fclose(stream);
X}
X
X
X/*
X   Read the network weights from a file.
X*/
Xstatic void read_weights(stream, network)
X   FILE *stream;
X   NetworkRec *network;
X{
X   int i;
X   int j;
X
X   if (network != NULL) 
X   {
X      for (i = 0; i < network->numunits; i++)
X         for (j = 0; j < network->units[i].numweights; j++)
X            if (fscanf(stream, "%f", &network->units[i].weights[j].weight) 
X		!= 1) 
X               error(prog_name, "too few weights in weights file", TRUE);
X
X      for (i = 0; i < network->numunits; i++)
X         if (fscanf(stream,"%f",&network->units[i].bias) != 1)
X            error(prog_name, "too few weights in weights file", TRUE);
X
X     if (fscanf(stream,"%*f") != EOF)
X        error(prog_name, "too many weights in weights file", TRUE);
X   }
X
X   network->weights_loaded = TRUE;
X}
X
X
X
X/*
X   Propagate activations through network.
X*/
Xstatic void compute_output(network)
X   NetworkRec *network;
X{
X   int i, j;
X   UnitRec *uniti;
X   WeightRec *weight;
X
X   for (i = network->numinputs; i < network->numunits; i++) 
X   {
X      uniti = &network->units[i];
X      uniti->netinput = uniti->bias;
X
X      for (j = 0; j < uniti->numweights; j++) 
X      {
X         weight = &uniti->weights[j];
X         uniti->netinput += network->units[weight->fromunit].activation * 
X                            weight->weight;
X      }
X      uniti->activation = (*uniti->act_function)(uniti->netinput);
X   }
X}
X
X
X/*
X   Set the activations of the input units of the network.
X*/
Xstatic void set_input(network, example, attr_info)
X   NetworkRec *network;
X   Example *example;
X   AttributeInfo *attr_info;
X{
X   int i, j, k;
X   Attribute *attribute;
X   Value *value;
X   int start;
X
X   start = 0;
X   for (i = 0; i < attr_info->number; ++i)
X      if (i != attr_info->class_index)
X      {
X         attribute = &attr_info->attributes[i];
X         value = &example->values[i];
X
X	 if (start >= network->numinputs)
X	    error(prog_name, "network has too few inputs", TRUE);
X
X         switch (attribute->type)
X         {
X	    case NOMINAL_ATTR:
X	       if (attribute->map)
X	       {
X		  if (value->missing)
X		  {
X	             for (j = 0, k = start; j < attribute->map->size; ++j, ++k)
X                        network->units[k].activation =
X			   1.0 / attribute->map->size;
X		  }
X		  else
X		  {
X	             for (j = 0, k = start; j < attribute->map->size; ++j, ++k)
X                        network->units[k].activation = 
X			   attribute->map->vectors[value->value.discrete][j];
X		  }
X	          start += attribute->map->size;
X	       }
X	       else
X	       {
X		  if (value->missing)
X		  {
X	             for (j = 0, k = start; j < attribute->num_values; ++j, ++k)
X                        network->units[k].activation =
X			   1.0 / attribute->num_values;
X		  }
X		  else
X		  {
X	             for (j = 0, k = start; j < attribute->num_values; ++j, ++k)
X		        if (j == value->value.discrete)
X                           network->units[k].activation = 1.0;
X		        else
X                           network->units[k].activation = 0.0;
X		  }
X	          start += attribute->num_values;
X	       }
X	       break;
X	    case REAL_ATTR:
X	       if (attribute->map)
X	       {
X	          if (value->missing)
X	             error(prog_name, "missing value for real attribute", TRUE);
X
X/* COMPLETE HACK FOR THE ELEVATOR TASK */
X	          if (value->value.real == 0.0)
X		  {
X	             network->units[start].activation = 1.0;
X	             network->units[start + 1].activation = 0.0; 
X		  }
X		  else
X		  {
X	             network->units[start].activation = 0.0;
X	             network->units[start + 1].activation = value->value.real;
X		  }
X	          start += 2;
X	       }
X	       else
X	       {
X	          if (value->missing)
X	             error(prog_name, "missing value for real attribute", TRUE);
X
X	          network->units[start].activation = value->value.real;
X	          ++start;
X	       }
X	       break;
X	    case BOOLEAN_ATTR:
X	       if (value->missing)
X	          network->units[start].activation = 0.5;
X	       else
X	          network->units[start].activation = value->value.discrete;
X	       ++start;
X	       break;
X         }
X      }
X
X   if (start != network->numinputs)
X   {
X      error("system error", "failed to correctly set input vector", TRUE);
X   }
X}
X
X
Xstatic void read_coefficients(fname, ensemble)
X   char *fname;
X   Ensemble *ensemble;
X{
X   FILE *stream;
X   int i;
X
X   stream = check_fopen(fname, "r");
X
X   ensemble->total = 0.0;
X   for (i = 0; i < ensemble->number; ++i)
X   {
X      if (fscanf(stream, "%f", &ensemble->coeffs[i]) != 1)
X	 error(prog_name,
X	       "coefficients file for ensemble is not in correct format", TRUE);
X      ensemble->total += ensemble->coeffs[i];
X   }
X
X   fclose(stream);
X}
X
X
Xstatic void check_ensemble_networks(ensemble)
X   Ensemble *ensemble;
X{
X   int i;
X
X   for (i = 1; i < ensemble->number; ++i)
X   {
X      if (ensemble->nets[i].numoutputs != ensemble->nets[0].numoutputs)
X	 error(prog_name, "all ensemble nets must have same number of outputs",
X	       TRUE);
X
X      if (ensemble->nets[i].numinputs != ensemble->nets[0].numinputs)
X	 error(prog_name, "all ensemble nets must have same number of inputs",
X	       TRUE);
X   }
X}
X
X
Xstatic FILE *open_weight_file(stem)
X   char *stem;
X{
X   char fname[BUFSIZ];
X   FILE *stream;
X
X   sprintf(fname, "%s.wgt", stem);
X   if ((stream = fopen(fname, "r")) != NULL)
X      return(stream);
X
X   sprintf(fname, "%s.wts", stem);
X   if ((stream = fopen(fname, "r")) != NULL)
X      return(stream);
X
X   sprintf(err_buffer, "unable to open either %s.wgt or %s.wts", stem, stem);
X   error(prog_name, err_buffer, TRUE);
X}
X
X
Xvoid get_ensemble(stem, number)
X   char *stem;
X   int number;
X{
X   char fname[BUFSIZ];
X   FILE *stream;
X   int i;
X
X   free_oracle();
X
X   active_ensemble.number = number;
X
X   active_ensemble.nets = (NetworkRec *)
X			  check_malloc(sizeof(NetworkRec) * number);
X   for (i = 0; i < number; ++i)
X   {
X      sprintf(fname, "%s.%d.net", stem, i);
X      read_network(fname, &active_ensemble.nets[i]);
X
X      sprintf(fname, "%s.%d", stem, i);
X      stream = open_weight_file(fname);
X      read_weights(stream, &active_ensemble.nets[i]);
X   }
X   check_ensemble_networks(&active_ensemble);
X
X   active_ensemble.coeffs = (float *) check_malloc(sizeof(float) * number);
X   sprintf(fname, "%s.coeffs", stem);
X   read_coefficients(fname, &active_ensemble);
X
X   active_ensemble.predictions = (float *) check_malloc(sizeof(float) *
X					   active_ensemble.nets[0].numoutputs);
X}
X
X
Xvoid get_network(stem)
X   char *stem;
X{
X   char fname[BUFSIZ];
X   FILE *stream;
X
X   free_oracle();
X
X   sprintf(fname, "%s.net", stem);
X   read_network(fname, &active_net);
X
X   stream = open_weight_file(stem);
X   read_weights(stream, &active_net);
X
X   if (active_net.numoutputs == 1)
X      set_classification_function("threshold_half");
X   else
X      set_classification_function("one_of_N");
X}
X
X
Xstatic int query_network(example, attr_info)
X   Example *example;
X   AttributeInfo *attr_info;
X{
X   int predicted;
X
X   set_input(&active_net, example, attr_info);
X   compute_output(&active_net);
X   predicted = (*active_net.classification_function)(&active_net);
X
X   return(predicted);
X}
X
X
Xstatic int query_ensemble(example, attr_info)
X   Example *example;
X   AttributeInfo *attr_info;
X{
X   int i, j;
X   int predicted;
X   int num_outputs = active_ensemble.nets[0].numoutputs;
X   int first_output;
X
X   for (j = 0; j < num_outputs; ++j)
X      active_ensemble.predictions[j] = 0.0;
X
X   for (i = 0; i < active_ensemble.number; ++i)
X   {
X      set_input(&active_ensemble.nets[i], example, attr_info);
X      compute_output(&active_ensemble.nets[i]);
X      first_output = active_ensemble.nets[i].numunits - num_outputs;
X      for (j = 0; j < num_outputs; ++j)
X	 active_ensemble.predictions[j] += active_ensemble.coeffs[i] *
X	    active_ensemble.nets[i].units[j + first_output].activation;
X   }
X
X   for (j = 0; j < num_outputs; ++j)
X      active_ensemble.predictions[j] /= active_ensemble.total;
X
X   predicted = determine_ensemble_class(&active_ensemble);
X   return(predicted);
X}
X
X
Xvoid register_network_oracle(oracle)
X   int (**oracle)();
X{
X   if (oracle_is_network())
X      *oracle = query_network;
X   else if (oracle_is_ensemble())
X      *oracle = query_ensemble;
X   else
X      error(prog_name, "tried to use an oracle when no network loaded", TRUE);
X}
X
X
Xvoid classify_using_network(options, ex_info, attr_info, matrix)
X   Options *options;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   int **matrix;
X{
X   int i;
X   int predicted;
X   int actual;
X   Example *example;
X
X   if (ClassIsVector(attr_info))
X   {
X      error("system error",
X            "tried to use classify_using_network for class vectors", TRUE);
X   }
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      predicted = options->oracle(example, attr_info);
X      actual = Get_Class(&ex_info->examples[i], attr_info);
X      ++matrix[predicted][actual];
X   }
X}
X
X
Xvoid predict_using_network(ex_info, attr_info)
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X{
X   int i, j;
X   Example *example;
X
X   if (!oracle_is_network())
X      error(prog_name, "predict_using_network called when no network loaded",
X	    TRUE);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      set_input(&active_net, example, attr_info);
X      compute_output(&active_net);
X      for (j = active_net.numunits - active_net.numoutputs;
X	   j < active_net.numunits; ++j)
X      {
X	 printf("%f ", active_net.units[j].activation);
X      }
X      printf("\n");
X   }
X}
X
X
Xvoid vector_query_network(example, attr_info, values)
X   Example *example;
X   AttributeInfo *attr_info;
X   float *values;
X{
X   int i, j;
X
X   set_input(&active_net, example, attr_info);
X   compute_output(&active_net);
X   for (i = 0, j = active_net.numunits - active_net.numoutputs;
X	i < active_net.numoutputs; ++i, ++j)
X   {
X      values[i] = active_net.units[j].activation;
X   }
X}
X
X
END-of-network.c
echo x - sample-exp.h
sed 's/^X//' >sample-exp.h << 'END-of-sample-exp.h'
X#define UNINITIALIZED_KEY	1
X
X
X/*exported functions */
Xextern void		check_sample();
Xextern void		determine_attribute_distributions();
Xextern Distribution	**determine_local_distributions();
Xextern int		generate_discrete_attribute_value();
Xextern float		generate_real_attribute_value();
Xextern void		get_new_sample();
Xextern Example		*get_sample_instance();
Xextern void		print_attribute_distributions();
Xextern void		reset_sample_index();
Xextern int		sample();
X
END-of-sample-exp.h
echo x - sample-int.h
sed 's/^X//' >sample-int.h << 'END-of-sample-int.h'
X#define UNINITIALIZED_KEY	1
X#define SAMPLING_EPSILON	1.0e-6
X
X
Xtypedef union
X{
X   struct
X   {
X      float *probs;
X   } discrete;
X   struct
X   {
X      float min;
X      float max;
X   } real;
X} Posterior;
X
X
END-of-sample-int.h
echo x - sample.c
sed 's/^X//' >sample.c << 'END-of-sample.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <string.h>
X#include <math.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "tree.h"
X#include "stats-exp.h"
X#include "sample-int.h"
X
X
Xstatic ExampleInfo samples = {0, 0, NONE, NULL};
Xstatic int sample_index = 0;
X
X
X/*
X   John & Langley use 1/sqrt(n) but this doesn't seem to smooth enough
X   with large data sets.  1/log(n) seems to work better.
X*/
Xstatic float kernel_width(distribution, index, kernel_width_fn)
X   Distribution *distribution;
X   int index;
X   double (*kernel_width_fn)();
X{
X   float width;
X
X   width = 1.0 / (*kernel_width_fn)((double)
X				    distribution->num_parameters[index]);
X
X   return(width);
X}
X
X
Xstatic void plot_real_attribute_pdf(attribute, distribution, kernel_width_fn)
X   Attribute *attribute;
X   Distribution *distribution;
X   double (*kernel_width_fn)();
X{
X   char fname[BUFSIZ];
X   FILE *stream;
X   float increment = 0.005;
X   float x, y;
X   float sigma, normalizer, temp;
X   int i, j;
X
X   for (i = 0; i < distribution->num_states; ++i)
X   {
X      sprintf(fname, "%s.%d.pdf", attribute->name, i);
X      stream = check_fopen(fname, "w");
X
X      sigma = kernel_width(distribution, i, kernel_width_fn);
X      normalizer = 1.0 / sqrt(2.0 * M_PI) / sigma;
X      for (x = attribute->range->min; x <= attribute->range->max;
X	   x += increment)
X      {
X         y = 0.0;
X         for (j = 0; j < distribution->num_parameters[i]; ++j)
X         {
X	    temp = (x - distribution->parameters[i][j]) / sigma;
X	    y += normalizer * exp(-0.5 * temp * temp);
X         }
X         y /= distribution->num_parameters[i];
X         fprintf(stream, "%f\t%f\n", x, y);
X      }
X
X      fclose(stream);
X   }
X}
X
X
Xvoid print_attribute_distributions(attr_info, options, local_distributions)
X   AttributeInfo *attr_info;
X   Options *options;
X   Distribution **local_distributions;
X{
X   int i, j, k;
X   Attribute *attribute;
X   Distribution *distribution;
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      distribution = (local_distributions == NULL) ? attribute->distribution:
X		                                     local_distributions[i];
X
X      if (attribute->type == VECTOR_ATTR)
X      {
X         error("System error",
X	   "vector attributes not handled in print_attribute_distributions",
X	   TRUE);
X      }
X      else if (attribute->type == REAL_ATTR)
X      {
X	 if (options->estimation_method == GAUSSIAN)
X	 {
X            printf("%-20s mean = %f  stddev = %f\n", attribute->name,
X		   attribute->distribution[MEAN_INDEX],
X		   attribute->distribution[SIGMA_INDEX]);
X/*
X*/
X	 }
X	 else
X	 {
X            printf("%-20s: using kernel method to estimate density\n",
X		   attribute->name);
X/*
X            plot_real_attribute_pdf(attribute, distribution,
X				    options->kernel_width_fn);
X*/
X	 }
X      }
X      else
X      {
X	 for (j = 0; j < distribution->num_states; ++j)
X	 {
X	    if (j == 0)
X               printf("%-20s  ", attribute->name);
X	    printf("\t");
X            for (k = 0; k < attribute->num_values; ++k)
X	       printf("  %.2f", distribution->parameters[j][k]);
X            printf("\n");
X	 }
X      }
X   }
X}
X
X
Xstatic void free_attribute_stratification(attr_info)
X   AttributeInfo *attr_info;
X{
X   if (attr_info->stratification)
X   {
X      check_free((void *) attr_info->stratification->level_counts);
X      check_free((void *) attr_info->stratification->order);
X      check_free((void *) attr_info->stratification);
X      attr_info->stratification = NULL;
X   }
X}
X
X
Xstatic Stratification *determine_attribute_stratification(attr_info)
X   AttributeInfo *attr_info;
X{
X   Stratification *strat;
X   int *levels;
X   int prev;
X   int index;
X   int i, j;
X
X   strat = (Stratification *) check_malloc(sizeof(Stratification));
X
X   /* determine the level of each attribute */
X   levels = (int *) check_malloc(sizeof(int) * attr_info->number);
X   strat->num_levels = 0;
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      levels[i] = 0;
X      prev = attr_info->attributes[i].dependency;
X      while (prev != NULL_ATTR)
X      {
X	 ++levels[i];
X         prev = attr_info->attributes[prev].dependency;
X      }
X
X      if (levels[i] > strat->num_levels)
X	 strat->num_levels = levels[i];
X   }
X   ++strat->num_levels;
X
X   /* determine the number of attributes at each level */
X   strat->level_counts = (int *) check_malloc(sizeof(int) * strat->num_levels);
X   for (i = 0; i < strat->num_levels; ++i)
X      strat->level_counts[i] = 0;
X   for (i = 0; i < attr_info->number; ++i)
X      ++strat->level_counts[ levels[i] ];
X
X   /* order the attributes according to level */
X   index = 0;
X   strat->order = (Order *) check_malloc(sizeof(Order) * attr_info->number);
X   for (i = 0; i < strat->num_levels; ++i)
X      for (j = 0; j < attr_info->number; ++j)
X	 if (levels[j] == i)
X	    strat->order[index++].index = j;
X
X   check_free((void *) levels);
X
X   return(strat);
X}
X
X
Xvoid free_attribute_distributions(attribute)
X   Attribute *attribute;
X{
X   int i;
X   Distribution *distribution = attribute->distribution;
X
X   for (i = 0; i < distribution->num_states; ++i)
X      check_free((void *) distribution->parameters[i]);
X   check_free((void *) distribution->parameters);
X   check_free((void *) distribution->num_parameters);
X
X   check_free((void *) distribution);
X   attribute->distribution = NULL;
X}
X
X
Xstatic Distribution *set_attribute_distribution(distribution)
X   Distribution *distribution;
X{
X   int i, j;
X   Distribution *distr;
X
X   distr = check_malloc(sizeof(Distribution));
X   distr->num_states = distribution->num_states;
X   distr->num_parameters = (int *) check_malloc(sizeof(int) *
X						distribution->num_states);
X   distr->num_examples = (int *) check_malloc(sizeof(int) *
X				              distribution->num_states);
X   distr->parameters = (float **) check_malloc(sizeof(float *) *
X					       distribution->num_states);
X
X   for (i = 0; i < distribution->num_states; ++i)
X   {
X      distr->num_parameters[i] = distribution->num_parameters[i]; 
X      distr->num_examples[i] = distribution->num_examples[i]; 
X      distr->parameters[i] = (float *) check_malloc(sizeof(float) *
X						    distr->num_parameters[i]);
X      for (j = 0; j < distribution->num_parameters[i]; ++j)
X	 distr->parameters[i][j] = distribution->parameters[i][j];
X   }
X
X   return(distr);
X}
X
X
X/*
X   Doesn't worry if some values of an attribute have zero occurrences.
X*/
Xstatic void discrete_attribute_distribution(index, attr_info, ex_info, ex_mask,
X					    distribution)
X   int index;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Distribution *distribution;
X{
X   Attribute *attribute = &attr_info->attributes[index];
X   int depend_index = attribute->dependency;
X   int dist_index;
X   int num_states;
X   int d_value;
X   int i, j;
X
X   num_states = (depend_index == NULL_ATTR) ? 1 : 
X                attr_info->attributes[depend_index].num_values;
X   distribution->num_states = num_states;
X
X   /* initialize distributions, counts */
X   for (i = 0; i < num_states; ++i)
X   {
X      distribution->num_parameters[i] = attribute->num_values;
X      distribution->num_examples[i] = 0.0;
X      for (j = 0; j < attribute->num_values; ++j)
X         distribution->parameters[i][j] = 0.0;
X   }
X
X   for (i = 0; i < ex_info->number; ++i)
X      if (!ex_info->examples[i].values[index].missing && ex_mask[i] > 0.0)
X      {
X	 dist_index = (depend_index == NULL_ATTR) ? 0 :
X		      ex_info->examples[i].values[depend_index].value.discrete;
X	 d_value = ex_info->examples[i].values[index].value.discrete;
X	 distribution->parameters[dist_index][d_value] += ex_mask[i];
X	 distribution->num_examples[dist_index] += ex_mask[i];
X      }
X
X   for (i = 0; i < num_states; ++i)
X      for (j = 0; j < attribute->num_values; ++j)
X      {
X	 if (distribution->num_examples[i] != 0.0)
X            distribution->parameters[i][j] /= distribution->num_examples[i];
X	 else
X            distribution->parameters[i][j] = 0.0; 
X      }
X}
X
X
X/*
X   FOR NOW, PARTIAL EXAMPLES (EX_MASK[I] < 1.0) ARE TREATED AS WHOLE EXAMPLES.
X*/
Xstatic void real_attribute_distribution(index, attr_info, ex_info, ex_mask,
X					distribution)
X   int index;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Distribution *distribution;
X{
X   Attribute *attribute = &attr_info->attributes[index];
X   int depend_index = attribute->dependency;
X   int dist_index;
X   float value;
X   int num_states;
X   int i;
X
X   num_states = (depend_index == NULL_ATTR) ? 1 : 
X                attr_info->attributes[depend_index].num_values;
X   distribution->num_states = num_states;
X
X   for (i = 0; i < num_states; ++i)
X   {
X      distribution->num_parameters[i] = 0;
X      distribution->num_examples[i] = 0.0;
X   }
X
X   for (i = 0; i < ex_info->number; ++i)
X      if (!ex_info->examples[i].values[index].missing && ex_mask[i] > 0.0)
X      {
X	 dist_index = (depend_index == NULL_ATTR) ? 0 :
X		      ex_info->examples[i].values[depend_index].value.discrete;
X
X         value = ex_info->examples[i].values[index].value.real;
X
X	 distribution->parameters[dist_index][distribution->num_parameters[dist_index]] = value; 
X	 ++distribution->num_parameters[dist_index];
X         distribution->num_examples[dist_index] += ex_mask[i];
X      }
X
X   for (i = 0; i < num_states; ++i)
X   {
X      qsort((void *) distribution->parameters[i],
X            (size_t) distribution->num_parameters[i], sizeof(float),
X	    float_compare);
X   }
X}
X
X
Xstatic void real_attribute_ranges(index, attr_info, ex_info)
X   int index;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X{
X   float value;
X   Attribute *attribute = &attr_info->attributes[index];
X   int i;
X
X   for (i = 0; i < ex_info->number; ++i)
X      if (!ex_info->examples[i].values[index].missing)
X      {
X         value = ex_info->examples[i].values[index].value.real;
X
X	 if (value < attribute->range->min)
X	    attribute->range->min = value;
X	 else if (value > attribute->range->max)
X	    attribute->range->max = value;
X      }
X}
X
X
Xvoid real_attribute_distribution_gaussian(index, attr_info, ex_info,
X					  distribution)
X   int index;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   Distribution *distribution;
X{
X   Attribute *attribute = &attr_info->attributes[index];
X   int depend_index = attribute->dependency;
X   float *sum_values;
X   float *sum_squares;
X   float *counts;
X   int dist_index;
X   float r_value, variance;
X   int num_states;
X   int i;
X
X   num_states = (depend_index == NULL_ATTR) ? 1 : 
X                attr_info->attributes[depend_index].num_values;
X
X   sum_values = (float *) check_malloc(sizeof(float) * num_states);
X   sum_squares = (float *) check_malloc(sizeof(float) * num_states);
X   counts = (float *) check_malloc(sizeof(float) * num_states);
X   for (i = 0; i < num_states; ++i)
X   {
X      sum_values[i] = 0.0;
X      sum_squares[i] = 0.0;
X      counts[i] = 0.0;
X   }
X
X   for (i = 0; i < ex_info->number; ++i)
X      if (!ex_info->examples[i].values[index].missing)
X      {
X	 dist_index = (depend_index == NULL_ATTR) ? 0 :
X		      ex_info->examples[i].values[depend_index].value.discrete;
X
X         r_value = ex_info->examples[i].values[index].value.real;
X         sum_values[dist_index] += r_value; 
X         sum_squares[dist_index] += r_value * r_value; 
X         ++counts[dist_index];
X      }
X
X   for (i = 0; i < num_states; ++i)
X   {
X      distribution->num_parameters[i] = 2;
X
X      if (counts[i] == 0.0)
X      {
X         sprintf(err_buffer, "real-valued distribution (%s)with no values",
X                 attribute->name);
X         error(prog_name, err_buffer, TRUE);
X      }
X
X      variance = (sum_squares[i] - sum_values[i] * sum_values[i] / counts[i]) /
X		 counts[i];
X      variance = (variance < 0.0) ? 0.0 : variance;
X      distribution->parameters[i][MEAN_INDEX] = sum_values[i] / counts[i];
X      distribution->parameters[i][SIGMA_INDEX] = sqrt((double) variance);
X   }
X
X
X   check_free((void *) sum_values);
X   check_free((void *) sum_squares);
X   check_free((void *) counts);
X}
X
X
X/*
X   Ensure that each value is assigned at least 1%
X*/
Xvoid determine_attribute_distributions(attr_info, ex_info, ex_mask)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X{
X   Attribute *attribute;
X   Distribution distribution;
X   int i;
X
X   free_attribute_stratification(attr_info);
X   attr_info->stratification = determine_attribute_stratification(attr_info);
X
X   /* make this big enough for max # of parameters for kernel method */
X   distribution.parameters = (float **) check_malloc(sizeof(float **));
X   distribution.parameters[0] = (float *) check_malloc(sizeof(float) *
X                                                       ex_info->number);
X   distribution.num_parameters = (int *) check_malloc(sizeof(int));
X   distribution.num_examples = (int *) check_malloc(sizeof(int));
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X
X      if (attribute->type == VECTOR_ATTR)
X      {
X         error("System error",
X	   "vector attributes not handled in determine_attribute_distributions",
X	   TRUE);
X      }
X      else if (attribute->type == REAL_ATTR)
X      {
X         real_attribute_distribution(i, attr_info, ex_info, ex_mask,
X				     &distribution);
X         real_attribute_ranges(i, attr_info, ex_info);
X      }
X      else
X      {
X         discrete_attribute_distribution(i, attr_info, ex_info, ex_mask,
X				         &distribution);
X      }
X
X      attribute->distribution = set_attribute_distribution(&distribution);
X   }
X
X   check_free((void *) distribution.parameters[0]);
X   check_free((void *) distribution.parameters);
X   check_free((void *) distribution.num_parameters);
X   check_free((void *) distribution.num_examples);
X}
X
X
Xstatic void free_distributions(distributions, attr_info)
X   Distribution **distributions;
X   AttributeInfo *attr_info;
X{
X   int i, j;
X   Distribution *distribution;
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      distribution = distributions[i];
X      check_free((void *) distribution->num_parameters);
X      check_free((void *) distribution->num_examples);
X      for (j = 0; j < distribution->num_states; ++j)
X         check_free((void *) distribution->parameters[j]);
X      check_free((void *) distribution->parameters);
X      check_free((void *) distribution);
X   }
X
X   check_free((void *) distributions);
X}
X
X
Xstatic int use_local_distributions(attr_info, local_distributions,
X			           ancestor_distributions, constraints, alpha)
X   AttributeInfo *attr_info;
X   Distribution **local_distributions;
X   Distribution **ancestor_distributions;
X   Constraint **constraints;
X   float alpha;
X{
X   float prob;
X   float bonf_alpha;
X   int num_tests;
X   int dummy1;
X   float dummy2;
X   Attribute *attribute;
X   Distribution *local;
X   Distribution *ancestor;
X   float local_values[MAX_ATTR_VALUES], ancestor_values[MAX_ATTR_VALUES];
X   int i, j;
X
X   if (ancestor_distributions == NULL)
X      return(TRUE);
X
X   num_tests = 0;
X   for (i = 0; i < attr_info->number; ++i)
X      if (i != attr_info->class_index)
X      {
X	 if (local_distributions[i]->num_examples[0] == 0.0)
X	    return(FALSE);
X      
X         if (attr_info->attributes[i].relevant && constraints[i] == NULL)
X	    ++num_tests;
X      }
X
X   bonf_alpha = alpha / num_tests;
X
X/*
Xprintf("===  alpha = %.3f\tBonferroni alpha = %.3f  ====\n", alpha, bonf_alpha);
X*/
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      if (attribute->relevant && i != attr_info->class_index &&
X	  constraints[i] == NULL)
X      {
X         local = local_distributions[i];
X         ancestor = ancestor_distributions[i];
X
X         if (attribute->type == REAL_ATTR)
X         {
X	    kolomogorov_smirnov(local->parameters[0], local->num_parameters[0],
X			        ancestor->parameters[0],
X			        ancestor->num_parameters[0], &dummy2, &prob);
X         }
X         else
X         {
X
X            for (j = 0; j < attribute->num_values; ++j)
X	    {
X	       local_values[j] = local->parameters[0][j] *
X				 local->num_examples[0];
X	       ancestor_values[j] = ancestor->parameters[0][j] *
X				    ancestor->num_examples[0];
X/*
Xprintf("\t%.2f\t%.2f\n", local_values[j], ancestor_values[j]);
X*/
X	    }
X
X	    chi_square_unequal(local_values, ancestor_values, 
X			       attribute->num_values, 0, &dummy1, 
X			       &dummy2, &prob);
X         }
X
X/*
Xprintf("\t\tp = %.2f\n", prob);
X*/
X
X         if (prob <= bonf_alpha)
X	    return(TRUE);
X      }
X   }
X
X   return(FALSE);
X}
X
X
XDistribution **determine_local_distributions(attr_info, ex_info, ex_mask,
X					     constraints, 
X					     ancestor_distributions, options)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *ex_mask;
X   Constraint **constraints;
X   Distribution **ancestor_distributions;
X   Options *options;
X{
X   Attribute *attribute;
X   Distribution distribution;
X   Distribution **local_distributions;
X   int i;
X
X   /* make this big enough for max # of parameters for kernel method */
X   distribution.parameters = (float **) check_malloc(sizeof(float **));
X   distribution.parameters[0] = (float *) check_malloc(sizeof(float) *
X                                                       ex_info->number);
X   distribution.num_parameters = (int *) check_malloc(sizeof(int));
X   distribution.num_examples = (int *) check_malloc(sizeof(int));
X
X   local_distributions = (Distribution **) check_malloc(sizeof(Distribution *) *
X				                        attr_info->number);
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      if (attribute->type == VECTOR_ATTR)
X      {
X         error("System error",
X	   "vector attributes not handled in determine_local_distributions",
X	   TRUE);
X      }
X      else if (attribute->type == REAL_ATTR)
X      {
X         real_attribute_distribution(i, attr_info, ex_info, ex_mask,
X				     &distribution);
X      }
X      else
X      {
X         discrete_attribute_distribution(i, attr_info, ex_info, ex_mask,
X				         &distribution);
X      }
X
X      local_distributions[i] = set_attribute_distribution(&distribution);
X   }
X
X   check_free((void *) distribution.parameters[0]);
X   check_free((void *) distribution.parameters);
X   check_free((void *) distribution.num_parameters);
X   check_free((void *) distribution.num_examples);
X
X   if (use_local_distributions(attr_info, local_distributions,
X			       ancestor_distributions, constraints,
X			       options->distribution_alpha))
X   {
X      return(local_distributions);
X   }
X   else
X   {
X      free_distributions(local_distributions, attr_info);
X      return(NULL);
X   }
X}
X
X
X
X/*
X   Uses the "polarity method" from B. D. Ripley, "Computer Generation
X   of Random Variables: A Tutorial", International Statistics Review,
X   51 (1983), page 310.  This method generates two values at a time
X   so the function runs the method every other call.
X*/
Xstatic float new_generate_using_gaussian()
X{
X   static float run_method = TRUE;
X   static float x, y;
X   float v1, v2;
X   double w, c;
X
X   if (run_method)
X   {
X      do
X      {
X         v1 = 2 * my_random() - 1.0;
X         v2 = 2 * my_random() - 1.0;
X         w = v1 * v1 + v2 * v2;
X      } while (w > 1.0);
X
X      c = sqrt(-2.0 * log(w) / w);
X      x = c * v1;
X      y = c * v2;
X
X      run_method = FALSE;
X      return(x);
X   }
X   else
X   {
X      run_method = TRUE;
X      return(y);
X   }
X}
X
X
X/*
X   Uses the "rejection method" from p. 290 of _Numerical Recipes in C_.
X   Assume that the attribute distribution is normal; bound it above by
X   a constant function.
X*/
Xstatic float generate_using_gaussian(mean, sigma, lower, upper)
X   float mean;
X   float sigma;
X   float lower;
X   float upper;
X{
X   float ceiling;
X   float temp, pdf_value;
X   float x, y;
X   int rejected;
X   float normalizer; 
X
X   normalizer = 1.0 / sqrt(2.0 * M_PI);
X
X   if (mean >= lower && mean <= upper)
X      ceiling = normalizer / sigma;
X   else if (mean < lower)
X   {
X      temp = (lower - mean) / sigma;
X      ceiling = normalizer / sigma * exp(-0.5 * temp * temp);
X   }
X   else
X   {
X      temp = (upper - mean) / sigma;
X      ceiling = normalizer / sigma * exp(-0.5 * temp * temp);
X   }
X
X   do
X   {
X      x = lower + my_random() * (upper - lower);
X      y = ceiling * my_random();
X
X      temp = (x - mean) / sigma;
X      pdf_value = normalizer / sigma * exp(-0.5 * temp * temp);
X      rejected =  (y > pdf_value) ? TRUE : FALSE;
X   } while (rejected);
X
X   return(x);
X}
X
X#define MAX_TRIES	100
X
X/*
X   Adapted from p. 143 of _Density Estimation for Statistics and Data
X   Analysis_, by B. W. Silverman.
X*/
Xstatic float generate_using_kernel(attr_distr, index, lower, upper,
X				   kernel_width_fn)
X   Distribution *attr_distr;
X   int index;
X   float lower;
X   float upper;
X   double (*kernel_width_fn)();
X{
X   int first, last;
X   int which;
X   float epsilon, perturbation;
X   float x;
X   float width;
X   int tries = 0;
X
X   width = kernel_width(attr_distr, index, kernel_width_fn);
X
X   do
X   {
X      epsilon = new_generate_using_gaussian();
X      perturbation = epsilon * width; 
X
X      for (first = 0; first < attr_distr->num_parameters[index] &&
X           attr_distr->parameters[index][first] + perturbation < lower; ++first)
X         ;
X
X      ++tries;
X   } while (tries < MAX_TRIES && (first == attr_distr->num_parameters[index] || 
X	    attr_distr->parameters[index][first] + perturbation > upper));
X
X   if (tries == MAX_TRIES)
X   {
X      x = lower + my_random() * (upper - lower);
X/*
X      printf("Reached %d tries in generate_using_kernel:\n", MAX_TRIES);
X      printf("\tlower = %f, upper = %f, x = %f\n", lower, upper, x);
X*/
X   }
X   else
X   {
X      for (last = first; last < attr_distr->num_parameters[index] - 1 &&
X	   attr_distr->parameters[index][last + 1] + perturbation <= upper;
X	   ++last)
X         ;
X
X      which = first + (int) (my_random() * (last - first));
X      if (which == attr_distr->num_parameters[index])
X         --which;
X
X      x = attr_distr->parameters[index][which] + perturbation;
X   }
X
X   if (x < lower || x > upper)
X   {
X      error("System error", "bad value in generate_using_kernel", TRUE);
X   }
X
X   return(x);
X}
X
X
Xstatic float generate_using_uniform(lower, upper)
X   float lower;
X   float upper;
X{
X   float x;
X
X   x = lower + my_random() * (upper - lower);
X   return(x);
X}
X
X
Xfloat generate_real_attribute_value(distribution, index, lower, upper,
X					   options)
X   Distribution *distribution;
X   int index;
X   float lower;
X   float upper;
X   Options *options;
X{
X   float value;
X
X   if (options->estimation_method == GAUSSIAN)
X   {
X      value =
X	 generate_using_gaussian(distribution->parameters[index][MEAN_INDEX],
X				 distribution->parameters[index][SIGMA_INDEX],
X				 lower, upper); 
X   }
X   else if (options->estimation_method == UNIFORM)
X   {
X      value = generate_using_uniform(lower, upper);
X   }
X   else
X   {
X      value = generate_using_kernel(distribution, index, lower, upper,
X				    options->kernel_width_fn);
X   }
X
X   return(value);
X}
X
X
X
Xint generate_discrete_attribute_value(probs, num_values)
X   float *probs;
X   int num_values;
X{
X   int i;
X   float sum;
X   float value;
X
X   sum = 0.0;
X   for (i = 0; i < num_values; ++i)
X      sum += probs[i];
X
X   if (sum == 0.0)
X      error("system error", "bad vector in generate_discrete_attribute_value",
X	    TRUE);
X
X   do { value = my_random() * sum; } while (value == sum);
X
X   sum = 0.0;
X   for (i = 0; i < num_values; ++i)
X   {
X      if (probs[i] != 0.0 && value >= sum && value < sum + probs[i])
X	 return(i);
X      sum += probs[i];
X   }
X
X   error("system error",
X	 "failed to generate value in generate_discrete_attribute_value", TRUE);
X}
X
X
Xstatic void print_example(example, attr_info)
X   Example *example;
X   AttributeInfo *attr_info;
X{
X   int i;
X   Attribute *attribute;
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (i != attr_info->class_index)
X      {
X         attribute = &attr_info->attributes[i];
X         switch (attribute->type)
X         {
X	    case NOMINAL_ATTR:
X	       printf("%s ",
X		      attribute->labels[example->values[i].value.discrete]);
X	       break;
X	    case BOOLEAN_ATTR:
X	       if (example->values[i].value.discrete)
X	          printf("true ");
X	       else
X	          printf("false ");
X	       break;
X	    case REAL_ATTR:
X	       printf("%f ", example->values[i].value.real);
X	       break;
X         }
X      }
X   printf("\n\n");
X}
X
X
Xstatic int node_in_subtree(root, node)
X   TreeNode *root;
X   TreeNode *node;
X{
X   int i;
X
X   if (root == node)
X      return(TRUE);
X   else if (root->type == LEAF)
X      return(FALSE);
X   else
X   {
X      for (i = 0; i < root->type_specific.internal.split->arity; ++i)
X	 if (Get_Nth_Child(root, i) && 
X	     node_in_subtree(Get_Nth_Child(root, i), node))
X	    return(TRUE);
X   }
X
X   return(FALSE);
X}
X
X
Xstatic void print_path(attr_info, root, node)
X   AttributeInfo *attr_info;
X   TreeNode *root;
X   TreeNode *node;
X{
X   TreeNode *current = root;
X   int depth = 0;
X   int i, j;
X
X   while (current != node)
X   {
X      for (i = 0; i < current->type_specific.internal.split->arity &&
X	   !node_in_subtree(Get_Nth_Child(current, i), node); ++i)
X	 ;
X
X      if (i == current->type_specific.internal.split->arity)
X	 error("System error", "couldn't find path in print_path", TRUE);
X
X      for (j = 0; j < depth; ++j)
X	 printf("|   ");
X      print_split(Get_Split(current), attr_info, i, stdout);
X      printf("\n");
X
X      current = Get_Nth_Child(current, i);
X      ++depth;
X   }
X}
X
X
X/*  Assumes that children pointers are initialized to NULL */ 
Xvoid check_sample(attr_info, root, node, example, constraints, number)
X   AttributeInfo *attr_info;
X   TreeNode *root;
X   TreeNode *node;
X   Example *example;
X   Constraint **constraints;
X   int number;
X{
X   TreeNode *current = root;
X   int branch;
X   int i, j;
X   int depth = 0;
X   int branch_trace[BUFSIZ];
X   TreeNode *node_trace[BUFSIZ];
X
X   /* descend tree until we (a) reach the correct node, (b) reach
X      an incorrect leaf, or (c) reach an incomplete node */ 
X   while (current != node)
X   {
X      if (current->type == LEAF)
X      {
X	 printf("\nCONSTRAINTS:\n");
X	 print_constraints(constraints, attr_info);
X	 printf("\nEXAMPLE:\n");
X	 print_example(example, attr_info);
X	 printf("\nBRANCH TRACE:\n");
X	 for (i = 0; i < depth; ++i)
X	 {
X	    for (j = 0; j < i; ++j)
X	       printf("|   ");
X	    print_split(Get_Split(node_trace[i]), attr_info,
X			branch_trace[i], stdout);
X	    printf("\n");
X	 }
X	 printf("\n");
X	 printf("\nPATH TO NODE:\n");
X         print_path(attr_info, root, node);
X	 sprintf(err_buffer,
X		 "problem on example (%d) in check_sample: reached leaf",
X		 number);
X	 error("System Error", err_buffer, TRUE);
X      }
X
X      branch = which_branch(Get_Split(current), example);
X      node_trace[depth] = current;
X      branch_trace[depth++] = branch;
X      current  = Get_Nth_Child(current, branch);
X      if (!current)
X      {
X	 printf("\nCONSTRAINTS:\n");
X	 print_constraints(constraints, attr_info);
X	 printf("\nEXAMPLE:\n");
X	 print_example(example, attr_info);
X	 printf("\nBRANCH TRACE:\n");
X	 for (i = 0; i < depth; ++i)
X	 {
X	    for (j = 0; j < i; ++j)
X	       printf("|   ");
X	    print_split(Get_Split(node_trace[i]), attr_info,
X			branch_trace[i], stdout);
X	    printf("\n");
X	 }
X	 printf("\n");
X	 printf("\nPATH TO NODE:\n");
X         print_path(attr_info, root, node);
X	 sprintf(err_buffer,
X		 "problem on example (%d) in check_sample: reached null branch",
X		 number);
X	 error("System Error", err_buffer, TRUE);
X      }
X   }
X}
X
X
Xvoid reset_sample_index()
X{
X   sample_index = 0;
X}
X
X
XExample *get_sample_instance()
X{
X   Example *sample;
X
X   if (sample_index >= samples.number)
X      return(NULL);
X
X   sample = &samples.examples[sample_index++];
X
X   return(sample);
X}
X
X
X/*
X	node is needed only for debugging
X*/
Xvoid get_new_sample(attr_info, constraints, options, number,
X		    local_distributions, node)
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   Options *options;
X   int number;
X   Distribution **local_distributions;
X   TreeNode *node;
X{
X   int success = TRUE;
X   int i;
X   int counter = 0;
X
X   if (number > samples.size)
X   {
X      free_examples(&samples, attr_info);
X      samples.examples = (Example *) check_malloc(sizeof(Example) * number);
X      for (i = 0; i < number; ++i)
X      {
X	 samples.examples[i].name = NULL;
X	 samples.examples[i].values =
X	    (Value *) check_malloc(sizeof(Value) * attr_info->number);
X      }
X      samples.size = number;
X   }
X
X   for (i = 0; i < number && success; ++i)
X   {
X      success = sample(attr_info, &samples.examples[i], constraints, options,
X	               local_distributions);
X
Xif (success)
X{
X   check_sample(attr_info, tree_root, node, &samples.examples[i], constraints,
X                counter);
X   ++counter;
X}
X
X   }
X   samples.number = success ? number : i - 1;
X   sample_index = 0;
X
X   cache_oracle_classifications(&samples, attr_info, options);
X}
X
X
Xstatic int bad_discrete_distribution(attribute, posterior)
X   Attribute *attribute;
X   Posterior *posterior;
X{
X   int i;
X
X   for (i = 0; i < attribute->num_values; ++i)
X      if (posterior->discrete.probs[i] != 0.0)
X	 return(FALSE);
X
X   return(TRUE);
X}
X
X
Xstatic void initialize_posterior_with_constraints(attribute, constraints, posterior)
X   Attribute *attribute;
X   Constraint *constraints;
X   Posterior *posterior;
X{
X   Split *split;
X   float threshold;
X   int i;
X
X   if (attribute->type == REAL_ATTR)
X   {
X      while (constraints)
X      {
X         split = constraints->split;
X         if (split->type == REAL_SPLIT)
X         {
X            threshold = Get_Threshold(constraints->split);
X            if (constraints->branch)
X               posterior->real.min = Max(posterior->real.min, threshold);
X            else
X               posterior->real.max = Min(posterior->real.max, threshold);
X         }
X         constraints = constraints->next;
X      }
X   }
X   else if (attribute->type == BOOLEAN_ATTR)
X   {
X      while (constraints)
X      {
X         split = constraints->split;
X         if (split->type == BOOLEAN_SPLIT)
X            posterior->discrete.probs[constraints->branch] = 0.0; 
X         constraints = constraints->next;
X      }
X   }
X   else /* NOMINAL_ATTR */
X   {
X      while (constraints)
X      {
X         split = constraints->split;
X         if (split->type == BOOLEAN_SPLIT)
X         {
X            if (constraints->branch == 0)
X            {
X               for (i = 0; i < attribute->num_values; ++i)
X                  if (i != Get_Boolean_Value(split))
X                     posterior->discrete.probs[i] = 0.0; 
X            }
X            else
X            {
X               posterior->discrete.probs[Get_Boolean_Value(split)] = 0.0; 
X            }
X         }
X         else if (split->type == NOMINAL_SPLIT)
X         {
X            for (i = 0; i < attribute->num_values; ++i)
X               if (i != constraints->branch)
X                  posterior->discrete.probs[i] = 0.0; 
X         }
X         constraints = constraints->next;
X      }
X   }
X}
X
X
Xstatic Posterior *initialize_posteriors(attr_info, constraints,
X					local_distributions, options)
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   Distribution **local_distributions;
X   Options *options;
X{
X   int i, j;
X   Posterior *posteriors;
X   Posterior *post;
X   Attribute *attribute;
X   Distribution *distribution;
X
X   posteriors = (Posterior *) check_malloc(sizeof(Posterior) *
X					   attr_info->number);
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      post = &posteriors[i];
X      distribution = (local_distributions == NULL) ? attribute->distribution :
X                                                     local_distributions[i];
X
X      if (attribute->type == REAL_ATTR)
X      {
X	 post->real.min = attribute->range->min - SAMPLING_EPSILON;
X	 post->real.max = attribute->range->max;
X         initialize_posterior_with_constraints(attribute, constraints[i], post);
X      }
X      else if (attribute->type == BOOLEAN_ATTR)
X      {
X	 post->discrete.probs = (float *) check_malloc(sizeof(float) * 2);
X	 if (options->estimation_method == UNIFORM)
X	 {
X	    for (j = 0; j < 2; ++j)
X	       post->discrete.probs[j] = 0.5; 
X	 }
X	 else
X	 {
X	    for (j = 0; j < 2; ++j)
X	       post->discrete.probs[j] = distribution->parameters[0][j];
X	 }
X         initialize_posterior_with_constraints(attribute, constraints[i], post);
X
X         if (bad_discrete_distribution(attribute, post))
X	 {
X	    for (j = 0; j < 2; ++j)
X	       post->discrete.probs[j] = 0.5; 
X            initialize_posterior_with_constraints(attribute, constraints[i], post);
X	 }
X      }
X      else /* NOMINAL_ATTR */
X      {
X	 post->discrete.probs = (float *) check_malloc(sizeof(float) * 
X						       attribute->num_values);
X	 if (options->estimation_method == UNIFORM)
X	 {
X	    for (j = 0; j < attribute->num_values; ++j)
X	       post->discrete.probs[j] = 1.0 / attribute->num_values; 
X	 }
X	 else
X	 {
X	    for (j = 0; j < attribute->num_values; ++j)
X	       post->discrete.probs[j] = distribution->parameters[0][j];
X	 }
X         initialize_posterior_with_constraints(attribute, constraints[i], post);
X
X         if (bad_discrete_distribution(attribute, post))
X	 {
X	    for (j = 0; j < attribute->num_values; ++j)
X	       post->discrete.probs[j] = 1.0 / attribute->num_values; 
X            initialize_posterior_with_constraints(attribute, constraints[i], post);
X	 }
X      }
X   }
X
X   return(posteriors);
X}
X
X
X/*
X	USES EMPIRICAL DISTRIBUTION FOR REAL-VALUED PARAMETERS
X*/
Xstatic float calculate_posterior(member, posteriors, attr_info,
X				 local_distributions)
X   Member *member;
X   Posterior *posteriors;
X   AttributeInfo *attr_info;
X   Distribution **local_distributions;
X{
X   float sum;
X   float prob;
X   Attribute *attribute;
X   Posterior *post;
X   Distribution *distribution;
X   int i;
X   int n;
X   int satisfy;
X
X   if (member->type == NOMINAL_ATTR || member->type == BOOLEAN_ATTR)
X   {
X      sum = 0.0;
X      attribute = &attr_info->attributes[member->attribute];
X      post = &posteriors[member->attribute];
X      for (i = 0; i < attribute->num_values; ++i)
X	 sum += post->discrete.probs[i];
X
X      prob = post->discrete.probs[member->value.discrete] / sum;
X   }
X   else
X   {
X      attribute = &attr_info->attributes[member->attribute];
X      distribution = (local_distributions == NULL) ? attribute->distribution :
X		     local_distributions[member->attribute];
X      post = &posteriors[member->attribute];
X      n = 0;
X      satisfy = 0;
X      for (i = 0; i < distribution->num_parameters[0]; ++i)
X      {
X	 if (distribution->parameters[0][i] > post->real.min &&
X	     distribution->parameters[0][i] <= post->real.max)
X	 {
X	    ++n;
X
X	    if ((member->negated &&
X	         distribution->parameters[0][i] <= post->real.max &&
X	         distribution->parameters[0][i] > member->value.real) ||
X                (!member->negated &&
X	         distribution->parameters[0][i] > post->real.min &&
X	         distribution->parameters[0][i] <= member->value.real))
X	       ++satisfy;
X	 }
X      }
X
X      if (n == 0)
X      {
X	 /* no data for empirical distribution: assume uniform */
X	 if (member->negated)
X	    prob = (post->real.max - member->value.real) /
X		   (post->real.max - post->real.min);
X	 else
X	    prob = (member->value.real - post->real.min) /
X		   (post->real.max - post->real.min);
X      }
X      else
X         prob = 1.0 * satisfy / n;
X   }
X
X   if (prob < 0.0 || prob > 1.0)
X      error("system error", "bad probability in calculate_posterior", TRUE);
X
X   return(prob);
X}
X
X
Xstatic void update_posterior(member, posterior, attr_info, negated)
X   Member *member;
X   Posterior *posterior;
X   AttributeInfo *attr_info;
X   char negated;
X{
X   int i;
X
X   if (member->type == NOMINAL_ATTR || member->type == BOOLEAN_ATTR)
X   {
X      if (negated)
X      {
X	 posterior->discrete.probs[member->value.discrete] = 0.0;
X      }
X      else
X      {
X         for (i = 0; i < attr_info->attributes[member->attribute].num_values;
X	      ++i)
X	    if (i != member->value.discrete)
X	       posterior->discrete.probs[i] = 0.0;
X      }
X   }
X   else
X   {
X      if (member->negated != negated)
X	 posterior->real.min = Max(posterior->real.min, member->value.real);
X      else
X	 posterior->real.max = Min(posterior->real.max, member->value.real);
X   }
X}
X
X
Xstatic void satisfy_mofn_split(split, posteriors, attr_info,
X			       local_distributions)
X   Split *split;
X   Posterior *posteriors;
X   AttributeInfo *attr_info;
X   Distribution **local_distributions;
X{
X   Member *member;
X   float sum;
X   float value;
X   float satisfied;
X
X   do
X   {
X      satisfied = 0;
X      /* determine posterior of each condition */
X      sum = 0.0;
X      member = Get_Members(split);
X      while (member != NULL)
X      {
X         member->posterior = calculate_posterior(member, posteriors,
X						 attr_info,
X						 local_distributions);
X	 if (member->posterior == 1.0)
X	 {
X	    ++satisfied;
X
X	    /* HACK TO ACCOUNT FOR USING EMPIRICAL DISTRIBUTIONS */
X	    if (member->type == REAL_ATTR)
X	       update_posterior(member, &posteriors[member->attribute],
X		                attr_info, FALSE);
X	 }
X	 else
X	    sum += member->posterior;
X
X	 member = member->next;
X      }
X
X      if (satisfied < Get_M(split))
X      {
X         if (sum == 0.0)
X         {
X	    error("system error",
X	          "unable to set condition in satisfy_mofn_split", TRUE);
X         }
X
X         /* pick a condition */
X         do { value = my_random() * sum; } while (value == sum);
X         sum = 0.0;
X         member = Get_Members(split);
X         while (member != NULL)
X         {
X	    if (member->posterior != 1.0)
X	    {
X	       if (member->posterior != 0.0 && value >= sum &&
X	           value < sum + member->posterior)
X	       {
X	          break;
X	       }
X	       sum += member->posterior;
X	    }
X	    member = member->next;
X         }
X
X         if (member == NULL)
X         {
X	    error("system error",
X	          "failed to set a condition in satisfy_mofn_split", TRUE);
X         }
X
X         /* adjust posterior of selected attribute */
X         update_posterior(member, &posteriors[member->attribute],
X		          attr_info, FALSE);
X      }
X
X   } while (satisfied < Get_M(split));
X}
X
X
Xstatic void negated_satisfy_mofn_split(split, posteriors, attr_info,
X				       local_distributions)
X   Split *split;
X   Posterior *posteriors;
X   AttributeInfo *attr_info;
X   Distribution **local_distributions;
X{
X   Member *member;
X   float sum;
X   float value;
X   int satisfiable;
X
X   do
X   {
X      satisfiable = 0;
X      /* determine posterior of each condition */
X      sum = 0.0;
X      member = Get_Members(split);
X      while (member != NULL)
X      {
X	 member->posterior = 1.0 - calculate_posterior(member, posteriors,
X						       attr_info,
X						       local_distributions);
X	 if (member->posterior < 1.0)
X	 {
X	    ++satisfiable;
X	    sum += member->posterior;
X         }
X	 else if (member->type == REAL_ATTR)
X	 {
X	    /* HACK TO ACCOUNT FOR USING EMPIRICAL DISTRIBUTIONS */
X	    update_posterior(member, &posteriors[member->attribute],
X		             attr_info, TRUE);
X	 }
X
X	 member = member->next;
X      }
X
X      if (satisfiable >= Get_M(split))
X      {
X         if (sum == 0.0)
X         {
X	    error("system error",
X	          "unable to set condition in satisfy_mofn_split", TRUE);
X         }
X
X         /* pick a condition */
X         do { value = my_random() * sum; } while (value == sum);
X         sum = 0.0;
X         member = Get_Members(split);
X         while (member != NULL)
X         {
X	    if (member->posterior != 1.0)
X	    {
X	       if (member->posterior != 0.0 && value >= sum &&
X	           value < sum + member->posterior)
X	       {
X	          break;
X	       }
X	       sum += member->posterior;
X	    }
X	    member = member->next;
X         }
X
X         if (member == NULL)
X         {
X	    error("system error",
X	          "failed to set a condition in negated_satisfy_mofn_split",
X		  TRUE);
X         }
X   
X         /* adjust posterior of selected attribute */
X         update_posterior(member, &posteriors[member->attribute],
X			  attr_info, TRUE);
X      }
X
X   } while (satisfiable >= Get_M(split));
X}
X
X
Xstatic void set_attribute_values(example, attr_info, posteriors,
X			         local_distributions, options)
X   Example *example;
X   AttributeInfo *attr_info;
X   Posterior *posteriors;
X   Distribution **local_distributions;
X   Options *options;
X{
X   int i;
X   Posterior *post;
X   Attribute *attribute;
X   Distribution *distribution;
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (i != attr_info->class_index)
X      {
X	 attribute = &attr_info->attributes[i];
X         distribution = (local_distributions == NULL) ?
X			attribute->distribution : local_distributions[i];
X	 post = &posteriors[i];
X	 example->values[i].missing = FALSE;
X
X	 if (attribute->type == REAL_ATTR)
X	 {
X	    if (options->estimation_method == UNIFORM)
X	    {
X	       example->values[i].value.real =
X	       generate_using_uniform(post->real.min + SAMPLING_EPSILON,
X				      post->real.max);
X	    }
X	    else
X	    {
X	       example->values[i].value.real =
X	       generate_using_kernel(distribution, 0,
X				  post->real.min + SAMPLING_EPSILON,
X				  post->real.max, options->kernel_width_fn);
X	    }
X	 }
X	 else
X	 {
X	    example->values[i].value.discrete =
X	    generate_discrete_attribute_value(post->discrete.probs,
X					      attribute->num_values);
X	 }
X      }
X}
X
X
Xstatic void free_posteriors(posteriors, attr_info)
X   Posterior *posteriors;
X   AttributeInfo *attr_info;
X{
X   int i;
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (attr_info->attributes[i].type != REAL_ATTR)
X      {
X	 check_free((void *) posteriors[i].discrete.probs);
X      }
X
X   check_free((void *) posteriors);
X}
X
X
X/*
X	WOULD BE MORE EFFICIENT IF PASSED SPLITS INSTEAD OF CONSTRAINTS
X	TO SAMPLE WITH GAUSSIAN METHOD, EXTEND DETERMINE CALCULATE_POSTERIOR
X*/
Xint sample(attr_info, example, constraints, options, local_distributions)
X   AttributeInfo *attr_info;
X   Example *example;
X   Constraint **constraints;
X   Options *options;
X   Distribution **local_distributions;
X{
X   Posterior *posteriors;
X   static unsigned int sample_key = UNINITIALIZED_KEY + 1;
X   Constraint *constraint;
X   Split *split;
X   int i;
X
X   if (options->estimation_method == GAUSSIAN)
X      error(prog_name, "cannot sample with gaussian method yet", TRUE);
X
X   posteriors = initialize_posteriors(attr_info, constraints,
X				      local_distributions, options);
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      constraint = constraints[i];
X      while (constraint)
X      {
X	 split = constraint->split;
X	 if (split->type == M_OF_N_SPLIT &&
X	     split->type_specific.mofn.sample_key != sample_key)
X	 {
X	    if (constraint->branch)
X	    {
X               negated_satisfy_mofn_split(split, posteriors, attr_info,
X					  local_distributions);
X	    }
X            else
X	    {
X               satisfy_mofn_split(split, posteriors, attr_info,
X				  local_distributions);
X	    }
X
X	    split->type_specific.mofn.sample_key = sample_key;
X	 }
X	 constraint = constraint->next;
X      }
X   }
X   set_attribute_values(example, attr_info, posteriors,
X		        local_distributions, options);
X
X   ++sample_key;
X
X   free_posteriors(posteriors, attr_info);
X
X   return(TRUE);
X}
X
X
END-of-sample.c
echo x - stats-exp.h
sed 's/^X//' >stats-exp.h << 'END-of-stats-exp.h'
X
X/* exported functions */
Xextern void	chi_square();
Xextern void	chi_square_unequal();
Xextern void	kolomogorov_smirnov();
END-of-stats-exp.h
echo x - stats-int.h
sed 's/^X//' >stats-int.h << 'END-of-stats-int.h'
X/* used for chi-square test */
X#define EPS	3.0e-7
X#define ITMAX	100
X#define FPMIN	1.0e-30
X
X/* used for Kolomogorov-Smirnov test */
X#define EPS1	0.001
X#define EPS2	1.0e-8
X
END-of-stats-int.h
echo x - stats.c
sed 's/^X//' >stats.c << 'END-of-stats.c'
X#include <stdio.h>
X#include <stdlib.h>
X#include <math.h>
X#include "utils-exp.h"
X#include "stats-int.h"
X
X
X/* From _Numerical Recipes in C_, p. 626 */
Xstatic float probks(alam)
Xfloat alam;
X{
X   int j;
X   float a2, fac = 2.0, sum = 0.0, term, termbf = 0.0;
X
X   a2 = -2.0 * alam * alam;
X   for (j = 1; j <= 100; ++j)
X   {
X      term = fac * exp(a2 * j * j);
X      sum += term;
X      if (fabs((double) term) <= EPS1 * termbf || 
X	  fabs((double) term) <= EPS2 * sum)
X	 return(sum);
X      fac = - fac;
X      termbf = fabs((double) term);
X   }
X
X   /* failed to converge */
X   return(1.0);
X}
X
X
X/* From _Numerical Recipes in C_, p. 625 */
Xvoid  kolomogorov_smirnov(data1, n1, data2, n2, d, prob)
Xfloat data1[];
Xint n1;
Xfloat data2[];
Xint n2;
Xfloat *d;
Xfloat *prob;
X{
X   int j1 = 0, j2 = 0;
X   float d1, d2, dt, en1, en2, en, fn1 = 0.0, fn2 = 0.0;
X
X   qsort((char *) data1, n1, sizeof(float), float_compare);
X   qsort((char *) data2, n2, sizeof(float), float_compare);
X
X   en1 = n1;
X   en2 = n2;
X   *d = 0.0;
X
X   while (j1 < n1 && j2 < n2)
X   {
X      if ((d1 = data1[j1]) <= (d2 = data2[j2]))
X      {
X	 fn1 = 1.0 * (j1 + 1) / en1;
X	 ++j1;
X      }
X
X      if (d2 <= d1)
X      {
X	 fn2 = 1.0 * (j2 + 1) / en2;
X	 ++j2;
X      }
X
X      if ((dt = fabs(fn2 - fn1)) > *d)
X	 *d = dt;
X   }
X
X   en = sqrt(en1 * en2 / (en1 + en2));
X   *prob = probks((en + 0.12 + 0.11 / en) * (*d));
X}
X
X
X/* From _Numerical Recipes in C_, p. 214 */
Xstatic float gammln(z)
Xfloat z;
X{
X   double x, y, temp, ser;
X   int i;
X   static double cof[6] = {76.18009172947146, -86.50532032941677,
X			   24.01409824083091, -1.231739572450155,
X			   0.1208650973866179e-2, -0.5395239384953e-5};
X
X   y = x = z;
X   temp = x + 5.5;
X   temp -= (x + 0.5) * log(temp);
X   ser = 1.000000000190015;
X   for (i = 0; i < 6; ++i)
X      ser += cof[i] / ++y;
X   return(-temp + log(2.5066282746310005 * ser / x));
X}
X
X
X/* From _Numerical Recipes in C_, p. 218 */
Xstatic void gser(gamser, a, x, gln)
Xfloat *gamser;
Xfloat a;
Xfloat x;
Xfloat *gln;
X{
X   int n;
X   float sum, del, ap;
X
X   *gln = gammln(a);
X   if (x <= 0.0)
X   {
X      if (x < 0.0)
X	 error("system error", "x less than 0 in gser", TRUE);
X      *gamser = 0.0;
X      return;
X   }
X   else
X   {
X      ap = a;
X      del = sum = 1.0 / a;
X      for (n = 0; n < ITMAX; ++n)
X      {
X	 ++ap;
X	 del *= x / ap;
X	 sum += del;
X	 if (fabs(del) < fabs(sum) * EPS)
X	 {
X	    *gamser = sum * exp(-x + a * log(x) - (*gln));
X	    return;
X	 }
X      }
X
X      error("system error", "a too large, ITMAX too small in gser", TRUE);
X      return;
X   }
X}
X
X
X/* From _Numerical Recipes in C_, p. 219 */
Xstatic void gcf(gammcf, a, x, gln)
Xfloat *gammcf;
Xfloat a;
Xfloat x;
Xfloat *gln;
X{
X   int i;
X   float an, b, c, d, del, h;
X
X   *gln = gammln(a);
X   b = x + 1.0 - a;
X   c = 1.0 / FPMIN;
X   d = 1.0 / b;
X   h = d;
X   for (i = 0; i < ITMAX; ++i)
X   {
X      an = -i * (i - a);
X      b += 2.0;
X      d = an * d + b;
X      if (fabs(d) < FPMIN)
X	 d = FPMIN;
X      c = b + an / c;
X      if (fabs(c) < FPMIN)
X	 c = FPMIN;
X      d = 1.0 / d;
X      del = d * c;
X      h *= del;
X      if (fabs(del - 1.0) < EPS)
X	 break;
X   }
X
X   if (i > ITMAX)
X      error("system error", "a too large, ITMAX too small in gcf", TRUE);
X
X   *gammcf = exp(-x + a * log(x) - (*gln)) * h;
X}
X
X
X/* From _Numerical Recipes in C_, p. 218 */
Xstatic float gammq(a, x)
Xfloat a;
Xfloat x;
X{
X   float gamser, gammcf, gln;
X
X   if (x < 0.0 || a <= 0.0)
X      error("system error", "gammq called with bad arguments", TRUE);
X
X   if (x < (a + 1.0))
X   {
X      gser(&gamser, a, x, &gln);
X      return(1.0 - gamser);
X   }
X   else
X   {
X      gcf(&gammcf, a, x, &gln);
X      return(gammcf);
X   }
X}
X
X
X/* From _Numerical Recipes in C_, p. 622 */
Xvoid chi_square(bins_1, bins_2, num_bins, constraints, degrees,
X		chi_square_value, prob)
Xfloat bins_1[];
Xfloat bins_2[];
Xint num_bins;
Xint constraints;
Xint *degrees;
Xfloat *chi_square_value;
Xfloat *prob;
X{
X   int i;
X   float temp;
X
X   *degrees = num_bins - constraints;
X   *chi_square_value = 0.0;
X
X   for (i = 0; i < num_bins; ++i)
X   {
X      if (bins_1[i] == 0.0 && bins_2[i] == 0.0)
X         --*degrees;
X      else
X      {
X	 temp = bins_1[i] - bins_2[i];
X	 *chi_square_value += temp * temp / (bins_1[i] + bins_2[i]);
X      }
X   }
X
X   *prob = gammq(0.5 * *degrees, 0.5 * *chi_square_value);
X}
X
X
X
X
X/* From _Numerical Recipes in C_, p. 623 */
Xvoid chi_square_unequal(bins_1, bins_2, num_bins, constraints, degrees,
X		        chi_square_value, prob)
Xfloat bins_1[];
Xfloat bins_2[];
Xint num_bins;
Xint constraints;
Xint *degrees;
Xfloat *chi_square_value;
Xfloat *prob;
X{
X   int i;
X   float temp;
X   float sum_bins_1, sum_bins_2;
X   float a, b;
X
X   *degrees = num_bins - constraints;
X   *chi_square_value = 0.0;
X
X   sum_bins_1 = sum_bins_2 = 0.0;
X   for (i = 0; i < num_bins; ++i)
X   {
X      sum_bins_1 += bins_1[i];
X      sum_bins_2 += bins_2[i];
X   }
X   a = sqrt((double) sum_bins_2 / sum_bins_1);
X   b = sqrt((double) sum_bins_1 / sum_bins_2);
X
X   for (i = 0; i < num_bins; ++i)
X   {
X      if (bins_1[i] == 0.0 && bins_2[i] == 0.0)
X         --*degrees;
X      else
X      {
X	 temp = a * bins_1[i] - b * bins_2[i];
X	 *chi_square_value += temp * temp / (bins_1[i] + bins_2[i]);
X      }
X   }
X
X   *prob = gammq(0.5 * *degrees, 0.5 * *chi_square_value);
X}
X
END-of-stats.c
echo x - tree.c
sed 's/^X//' >tree.c << 'END-of-tree.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <math.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "network-exp.h"
X#include "tree.h"
X#include "sample-exp.h"
X#include "mofn-exp.h"
X
X
XTreeNode *tree_root = NULL;		/* for debugging purposes */
X
X
XDistribution **get_local_distributions(node)
X   TreeNode *node;
X{
X   while (node != NULL && node->distributions == NULL)
X      node = node->parent;
X
X   if (node == NULL)
X      return(NULL);
X
X   return(node->distributions);
X}
X
X
XValueType get_class(example, attr_info, options)
X   Example *example;
X   AttributeInfo *attr_info;
X   Options *options;
X{
X   ValueType class;
X
X   if (options->use_oracle)
X   {
X      if (example->oracle.missing)
X      {
X	 class.discrete = options->oracle(example, attr_info);
X         return(class);
X      }
X      else
X	 return(example->oracle.value);
X   }
X   else
X      return(example->values[attr_info->class_index].value);
X}
X
X
Xvoid cache_oracle_classifications(ex_info, attr_info, options)
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X{
X   int i;
X   Example *example;
X
X   if (attr_info->attributes[attr_info->class_index].type == VECTOR_ATTR)
X      error(prog_name, "Oracle stuff doesn't support class vectors yet", TRUE);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      example->oracle.missing = FALSE;
X      example->oracle.value.discrete = (*options->oracle)(example, attr_info);
X   }
X}
X
X
Xvoid print_split(split, attr_info, branch, stream)
X   Split *split;
X   AttributeInfo *attr_info;
X   int branch;
X   FILE *stream;
X{
X   int index;
X   Attribute *attr;
X   char *temp_label;
X   Member *member;
X
X   switch (split->type)
X   {
X      case NOMINAL_SPLIT:
X         index = Get_Nominal_Attr(split);
X         attr = &attr_info->attributes[index];
X         temp_label = attr->labels[branch];
X         fprintf(stream, "%s = %s", attr->name, temp_label);
X         break;
X      case BOOLEAN_SPLIT:
X         index = Get_Boolean_Attr(split);
X         attr = &attr_info->attributes[index];
X         if (attr->type == BOOLEAN_ATTR)
X         {
X            temp_label = branch ? "false" : "true";
X            fprintf(stream, "%s = %s", attr->name, temp_label);
X         }
X         else
X         {
X            temp_label = branch ? "!=" : "=";
X            fprintf(stream, "%s %s %s", attr->name, temp_label,
X                   attr->labels[Get_Boolean_Value(split)]);
X         }
X         break;
X      case M_OF_N_SPLIT:
X         if (branch) fprintf(stream, "NOT ");
X         fprintf(stream, "%d of {", split->type_specific.mofn.m);
X         member = Get_Members(split);
X         while (member)
X         {
X            if (member != Get_Members(split))
X                     fprintf(stream, ", ");
X            attr = &attr_info->attributes[member->attribute];
X            if (attr->type == BOOLEAN_ATTR)
X            {
X               temp_label = member->value.discrete ? "true" : "false";
X               fprintf(stream, "%s=%s", attr->name, temp_label);
X            }
X            else if (attr->type == NOMINAL_ATTR)
X            {
X               fprintf(stream, "%s=%s", attr->name,
X                      attr->labels[member->value.discrete]);
X            }
X            else if (attr->type == REAL_ATTR)
X	    {
X	       if (!member->negated)
X		  fprintf(stream, "%s <= %f", attr->name, member->value.real);
X	       else
X		  fprintf(stream, "%s > %f", attr->name, member->value.real);
X	    }
X
X            member = member->next;
X         }
X         fprintf(stream, "}");
X         break;
X      case REAL_SPLIT:
X         index = Get_Real_Attr(split);
X         attr = &attr_info->attributes[index];
X         temp_label = branch ? ">" : "<=";
X         fprintf(stream, "%s %s %.6f", attr->name, temp_label,
X                Get_Threshold(split));
X         break;
X   }
X}
X
X
Xvoid print_splits(attr_info, list, stream)
X   AttributeInfo *attr_info;
X   Split *list;
X   FILE *stream;
X{
X   int count = 0;
X
X   printf("========== SPLIT LIST ==========\n\n");
X
X   while (list)
X   {
X      ++count;
X      print_split(list, attr_info, 0, stream);
X      printf(" %f\n", list->gain);
X      list = list->next;
X   }
X
X   printf("%d splits in list\n", count);
X}
X
X
Xvoid free_split(split)
X   Split *split;
X{
X   Member *member, *temp_mem;
X   int i;
X
X   if (split->type == M_OF_N_SPLIT)
X   {
X      member = Get_Members(split);
X      while (member)
X      {
X         temp_mem = member;
X         member = member->next;
X         check_free((void *) temp_mem);
X      }
X   }
X
X   for (i = 0; i < split->arity; ++i)
X      check_free((void *) split->class_distr[i]);
X   check_free((void *) split->class_distr);
X   check_free((void *) split->branch_distr);
X   check_free((void *) split);
X}
X
X
Xvoid free_tree(node)
X   TreeNode *node;
X{
X   int i;
X   Split *split;
X
X   if (node->type == INTERNAL)
X   {
X      split = Get_Split(node);
X      for (i = 0; i < split->arity; ++i)
X         free_tree(Get_Nth_Child(node, i));
X      if (--split->reference_count == 0)
X	 free_split(split);
X      check_free((void *) Get_Children(node));
X      check_free((void *) Get_Probs(node));
X   }
X
X   check_free((void *) node->e_distribution);
X   check_free((void *) node->s_distribution);
X   check_free((void *) node);
X}
X
X
Xvoid example_distribution(node, ex_info, attr_info, options, mask)
X   TreeNode *node;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X   float *mask;
X{
X   ValueType class;
X   int i, j;
X   int class_is_vector = ClassIsVector(attr_info);
X
X   node->e_distribution = (float *) check_malloc(sizeof(float) * 
X					         attr_info->num_classes);
X   node->s_distribution = (float *) check_malloc(sizeof(float) * 
X					         attr_info->num_classes);
X   for (i = 0; i < attr_info->num_classes; ++i)
X   {
X      node->e_distribution[i] = 0.0;
X      node->s_distribution[i] = 0.0;
X   }
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      class = get_class(&ex_info->examples[i], attr_info, options);
X      if (class_is_vector)
X      {
X	 for (j = 0; j < attr_info->num_classes; ++j)
X	    node->e_distribution[j] += mask[i] * class.vector[j];
X      }
X      else
X         node->e_distribution[class.discrete] += mask[i];
X   }
X
X   node->class = NO_CLASS;
X   node->e_total = 0.0;
X   node->s_total = 0.0;
X   for (i = 0; i < attr_info->num_classes; ++i)
X   {
X      node->e_total += node->e_distribution[i];
X      if (node->e_distribution[i] > 0.0)
X      {
X	 if (node->class == NO_CLASS || 
X	     node->e_distribution[i] > node->e_distribution[node->class])
X	    node->class = i;
X      }
X   }
X}
X
X
Xstatic void sample_distribution(node, number, attr_info, options)
X   TreeNode *node;
X   int number;
X   AttributeInfo *attr_info;
X   Options *options;
X{
X   ValueType class;
X   Example *example;
X   int i, j;
X   int class_is_vector = ClassIsVector(attr_info);
X   int done = FALSE;
X
X   node->s_total = (float) number;
X   reset_sample_index();
X   for (i = 0 ; i < number && done == FALSE; ++i)
X   {
X      example = get_sample_instance();
X      if (example != NULL)
X      {
X         class = get_class(example, attr_info, options);
X         if (class_is_vector)
X         {
X	    for (j = 0; j < attr_info->num_classes; ++j)
X	       node->s_distribution[j] += class.vector[j];
X         }
X         else
X            node->s_distribution[class.discrete] += 1.0;
X      }
X      else
X	 done = TRUE;
X   }
X
X   for (j = 0; j < attr_info->num_classes; ++j)
X      if (Get_Class_Total(node, j) > 0.0)
X      {
X	 if (node->class == NO_CLASS ||
X	     Get_Class_Total(node, j) > Get_Class_Total(node, node->class))
X	    node->class = j;
X      }
X}
X
X
Xstatic float possible_information(split)
X   Split *split;
X{
X   float sum = 0.0;
X   float info;
X   int i;
X
X   for (i = 0; i < split->arity; ++i)
X   {
X      if (split->branch_distr[i] != 0.0)
X         sum += split->branch_distr[i] * Log2((double) split->branch_distr[i]);
X   }
X
X   if (split->missing != 0.0)
X      sum += split->missing * Log2((double) split->missing);
X
X   info = (split->total * Log2((double) split->total) - sum) / split->total;
X
X   return(info);
X}
X
X
Xstatic float base_information(split, num_classes)
X   Split *split;
X   int num_classes;
X{
X   float sum = 0.0;
X   float info;
X   float known;
X   float count;
X   int i, j;
X
X   known = split->total - split->missing;
X   if (known == 0.0)
X      return(0.0);
X
X   for (i = 0; i < num_classes; ++i)
X   {
X      count = 0.0;
X      for (j = 0; j < split->arity; ++j)
X	 count += split->class_distr[j][i];
X
X      if (count != 0.0)
X         sum += count * Log2((double) count);
X   }
X
X   info = (known * Log2((double) known) - sum) / known;
X
X   return(info);
X}
X
X
Xstatic float split_information(split, num_classes)
X   Split *split;
X   int num_classes;
X{
X   int i, j;
X   float info = 0.0;
X   float sum = 0.0;
X
X   if (split->total == split->missing)
X      return(0.0);
X
X   for (i = 0; i < split->arity; ++i)
X   {
X      if (split->branch_distr[i] != 0.0)
X      {
X         sum = 0.0;
X         for (j = 0; j < num_classes; ++j)
X	    if (split->class_distr[i][j] != 0.0)
X	       sum += split->class_distr[i][j] * 
X		      Log2((double) split->class_distr[i][j]);
X
X         info += split->branch_distr[i] * 
X		 Log2((double) split->branch_distr[i]) - sum;
X      }
X   }
X
X   info /= (split->total - split->missing);
X   return(info);
X}
X
X
X/*
X   Make sure at least 2 of the branches have at least `min_objects'
X   assigned to them.
X*/
Xint trivial_split(split, min_objects)
X   Split *split;
X   float min_objects;
X{
X   int i;
X   int count = 0;
X
X   for (i = 0; i < split->arity; ++i)
X      if (split->branch_distr[i] >= min_objects)
X      {
X	 ++count;
X
X	 if (count == 2)
X	    return(FALSE);
X      }
X
X   return(TRUE);
X}
X
X
X/*
X   This could use a smarter algorithm for handling missing values
X   in m-of-n splits.
X*/
Xint which_branch(split, example)
X   Split *split;
X   Example *example;
X{
X   int attr;
X   int value;
X   float r_value;
X   Member *member;
X   int satisfied, unknown;
X
X   switch (split->type)
X   {
X      case NOMINAL_SPLIT:
X	 attr = Get_Nominal_Attr(split);
X	 if (example->values[attr].missing)
X	    return(MISSING);
X	 return(example->values[attr].value.discrete);
X      case M_OF_N_SPLIT:
X	 satisfied = 0;
X	 unknown = 0;
X	 member = Get_Members(split);
X	 while (member)
X	 {
X	    attr = member->attribute; 
X	    if (!example->values[attr].missing)
X	    {
X	       if (member->type == BOOLEAN_ATTR || member->type == NOMINAL_ATTR)
X	       {
X	          value = member->value.discrete; 
X	          if (value == example->values[attr].value.discrete)
X	             ++satisfied;
X	       }
X	       else if (member->type == REAL_ATTR)
X	       {
X	          r_value = example->values[attr].value.real;
X	          if (!member->negated && r_value <= member->value.real)
X	             ++satisfied;
X	          else if (member->negated && r_value > member->value.real)
X	             ++satisfied;
X	       }
X
X	       if (satisfied >= Get_M(split))
X	          return(0);
X	    }
X	    else
X	       ++unknown;
X	    member = member->next;
X	 }
X
X	 /* May return MISSING when it can be determined that a split
X	    is not satisfiable (because multiple unknowns may be for
X	    one attribute).
X	 */
X	 if (satisfied >= Get_M(split))
X	    return(0);
X	 else if (satisfied + unknown >= Get_M(split))
X	    return(MISSING);
X	 else
X	    return(1);
X      case REAL_SPLIT:
X	 attr = Get_Real_Attr(split);
X	 if (example->values[attr].missing)
X	    return(MISSING);
X	 r_value = example->values[attr].value.real;
X	 if (r_value <= Get_Threshold(split))
X	    return(0);
X	 else
X	    return(1);
X      case BOOLEAN_SPLIT:
X	 attr = Get_Boolean_Attr(split);
X	 if (example->values[attr].missing)
X	    return(MISSING);
X	 value = Get_Boolean_Value(split);
X	 if (value == example->values[attr].value.discrete)
X	    return(0);
X	 else
X	    return(1);
X      default:
X	 error("System error", "bad split type in which_branch", TRUE);
X   }
X}
X
X
Xvoid reset_statistics(split, num_classes)
X   Split *split;
X   int num_classes;
X{
X   int i, j;
X
X   split->total = 0.0;
X   split->missing = 0.0;
X   split->gain = 0.0;
X   for (i = 0; i < split->arity; ++i)
X   {
X      split->branch_distr[i] = 0.0;
X      for (j = 0; j < num_classes; ++j)
X         split->class_distr[i][j] = 0.0;
X   }
X
X}
X
X
Xvoid update_statistics(split, attr_info, example, class, weight)
X   Split *split;
X   AttributeInfo *attr_info;
X   Example *example;
X   ValueType class;
X   float weight;
X{
X   int branch;
X   int i;
X   int class_is_vector = ClassIsVector(attr_info);
X
X   split->total += weight;
X   branch = which_branch(split, example);
X
X   if (branch == MISSING)
X   {
X      split->missing += weight;
X   }
X   else
X   {
X      split->branch_distr[branch] += weight;
X      if (class_is_vector)
X      {
X	 for (i = 0; i < attr_info->num_classes; ++i)
X	    split->class_distr[branch][i] += weight * class.vector[i];
X      }
X      else
X         split->class_distr[branch][class.discrete] += weight;
X   }
X}
X
X
Xstatic Split *put_split_back(list, element)
X   Split *list;
X   Split *element;
X{
X   if (element->prev == NULL)
X   {
X      if (element->next != NULL)
X         element->next->prev = element;
X      else if (list != NULL)
X	 error(prog_name, "bad list elements in put_split_back", TRUE);
X	
X      return(element);
X   }
X   else
X   {
X      element->prev->next = element;
X
X      if (element->next != NULL)
X         element->next->prev = element;
X
X      return(list);
X   }
X}
X
X
XSplit *add_split(list, element)
X   Split *list;
X   Split *element;
X{
X   element->prev = NULL;
X   element->next = list;
X   if (list)
X      list->prev = element;
X   return(element);
X}
X
X
Xstatic Split *remove_split(list, element)
X   Split *list;
X   Split *element;
X{
X   if (element->next)
X      element->next->prev = element->prev;
X
X   if (element->prev != NULL)
X      element->prev->next = element->next;
X   else
X      list = element->next;
X
X   return(list);
X}
X
X
Xfloat **make_masks(node, ex_info, parent)
X   TreeNode *node;
X   ExampleInfo *ex_info;
X   float *parent;
X{
X   float **masks;
X   int i;
X   int ex;
X   int branch;
X   int number = node->type_specific.internal.split->arity;
X
X   masks = (float **) check_malloc(sizeof(float *) * number);
X   for (i = 0; i < number; ++i)
X      masks[i] = (float *) check_malloc(sizeof(float) * ex_info->number);
X
X   for (ex = 0; ex < ex_info->number; ++ex)
X   {
X      branch = which_branch(Get_Split(node), &ex_info->examples[ex]);
X
X      for (i = 0; i < number; ++i)
X      {
X	 if (branch == MISSING)
X	    masks[i][ex] = Get_Nth_Prob(node, i) * parent[ex];
X	 else if (branch == i)
X	    masks[i][ex] = parent[ex];
X	 else
X	    masks[i][ex] = 0.0;
X      }
X   }
X
X   return(masks);
X}
X
X
Xint trivial_split_when_sampling(split, ex_info, mask, options)
X   Split *split;
X   ExampleInfo *ex_info;
X   float *mask;
X   Options *options;
X{
X   float *weight;
X   int i;
X   int ex;
X   int branch;
X   int count;
X
X   weight = (float *) check_malloc(sizeof(float) * split->arity);
X   for (i = 0; i < split->arity; ++i)
X      weight[i] = 0.0; 
X
X   for (ex = 0; ex < ex_info->number; ++ex)
X   {
X      branch = which_branch(split, &ex_info->examples[ex]);
X      if (branch == MISSING)
X      {
X         for (i = 0; i < split->arity; ++i)
X	    weight[i] += mask[ex] * split->branch_distr[i] /
X                         (split->total - split->missing);
X      }
X      else
X         weight[branch] += mask[ex];
X
X      count = 0;
X      for (i = 0; i < split->arity; ++i)
X	 if (weight[i] >= options->min_objects)
X         {
X	    ++count;
X	    if (count == 2)
X	    {
X               check_free((void *) weight);
X	       return(FALSE);
X	    }
X         }
X   }
X
X   check_free((void *) weight);
X
X   return(TRUE);
X}
X
X
Xstatic void free_masks(masks, number)
X   float **masks;
X   int number;
X{
X   int i;
X
X   for (i = 0; i < number; ++i)
X      check_free((void *) masks[i]);
X
X   check_free((void *) masks);
X}
X
X
Xvoid free_unused_splits(split)
X   Split *split;
X{
X   Split *temp_split;
X
X   while (split)
X   {
X      temp_split = split;
X      split = split->next;
X      temp_split->next = temp_split->prev = NULL;
X      if (--temp_split->reference_count == 0)
X	 free_split(temp_split);
X   }
X}
X
X
XSplit *get_new_split(type, arity, attr_info)
X   SplitType type;
X   int arity;
X   AttributeInfo *attr_info;
X{
X   int i;
X   Split *split;
X
X   split = (Split *) check_malloc(sizeof(Split));
X
X   split->type = type;
X   split->arity = arity;
X   split->reference_count = 1;
X   split->can_use = TRUE;
X   split->next = split->prev = NULL;
X
X   /* allocate & initialize distribution information */
X   split->branch_distr = (float *) check_malloc(sizeof(float) * arity);
X   split->class_distr = (float **) check_malloc(sizeof(float *) * arity);
X   for (i = 0; i < arity; ++i)
X   {
X      split->class_distr[i] = 
X	 (float *) check_malloc(sizeof(float) * attr_info->num_classes);
X   }
X
X   return(split);
X}
X
X
Xstatic Split *make_real_valued_splits(attr_info, ex_info, example_mask,
X				      options, constraints, index, list)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Options *options;
X   Constraint **constraints;
X   int index;
X   Split *list;
X{
X   int num_candidates;
X   Order *candidates;
X   Example *example;
X   ValueType class;
X   int class_index = attr_info->class_index;
X   int low_index, high_index;
X   int low_class;
X   Split *split;
X   int n = 0;
X   int added = 0;
X   int i;
X
X   if (ClassIsVector(attr_info))
X   {
X      for (i = 0; i < ex_info->number; ++i)
X      {
X         example = &ex_info->examples[i];
X         if (example_mask[i] != 0.0 && !example->values[index].missing)
X         {
X            split = get_new_split(REAL_SPLIT, 2, attr_info);
X            split->type_specific.real.attribute = index;
X            split->type_specific.real.threshold =
X	       example->values[index].value.real;
X	    list = add_split(list, split);
X	 }
X      }
X      return(list);
X   }
X
X   num_candidates = Max(ex_info->number, options->min_sample);
X   candidates = (Order *) check_malloc(sizeof(Order) * num_candidates);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      if (example_mask[i] != 0.0 && !example->values[index].missing)
X      {
X         candidates[n].value = example->values[index].value.real;
X         candidates[n].index = example->values[class_index].value.discrete;
X         ++n;
X      }
X   }
X
X   /* Now do sampling if necessary */
X/*
X   if (options->min_sample)
X   {
X      example = check_malloc(sizeof(Example));
X      example->oracle.missing = TRUE;
X      example->values = (Value *)
X                           check_malloc(sizeof(Value) * attr_info->number);
X      for ( ; n < options->min_sample; ++n)
X      {
X         sample(attr_info, example, constraints, options);
X         class = get_class(example, attr_info, options);
X         candidates[n].value = example->values[index].value.real;
X         candidates[n].index = class.discrete;
X      }
X      check_free((void *) example->values);
X      check_free((void *) example);
X   }
X*/
X
X   qsort((void *) candidates, (size_t) n, sizeof(Order), order_compare);
X
X   low_index = 0;
X   do
X   {
X      low_class = candidates[low_index].index;
X      high_index = low_index + 1;
X      while (high_index < n &&
X	     candidates[high_index].value == candidates[low_index].value)
X      {
X	 if (candidates[high_index].index != low_class)
X	    low_class = MIXED_CLASS;
X         ++high_index;
X      }
X
X      if (high_index < n && low_class != candidates[high_index].index)
X      {
X         split = get_new_split(REAL_SPLIT, 2, attr_info);
X         split->type_specific.real.attribute = index;
X
X	 /* putting threshold between two values works better for sampling */
X         split->type_specific.real.threshold = (candidates[low_index].value +
X			                    candidates[high_index].value) / 2.0;
X/* for debugging */
Xsplit->gain = 0.0;
X	 list = add_split(list, split);
X	 ++added;
X      }
X      low_index = high_index;
X   } while (high_index < n);
X   
X   check_free((void *) candidates);
X
X/*
X   printf("\tadded %d splits for attribute %s\n", added,
X	  attr_info->attributes[index].name);
X*/
X
X   return(list);
X}
X
X
Xstatic Split *add_real_valued_splits(attr_info, ex_info, example_mask, options,
X			             constraints, list)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Options *options;
X   Constraint **constraints;
X   Split *list;
X{
X   Attribute *attribute;
X   int i;
X
X   for (i = attr_info->number - 1; i >= 0; --i)
X      if (i != attr_info->class_index)
X      {
X         attribute = &attr_info->attributes[i];
X         if (attribute->type == REAL_ATTR && attribute->relevant)
X	 {
X           list = make_real_valued_splits(attr_info, ex_info, example_mask,
X					  options, constraints, i, list);
X	 }
X      }
X
X   return(list);
X}
X
X
Xstatic Split *make_candidate_splits(attr_info, options)
X   AttributeInfo *attr_info;
X   Options *options;
X{
X   Split *list = NULL;
X   Split *split;
X   Attribute *attribute;
X   int i, j;
X
X   for (i = attr_info->number - 1; i >= 0; --i)
X   {
X      attribute = &attr_info->attributes[i];
X      if (i != attr_info->class_index && attribute->relevant)
X      {
X         if (attribute->type == NOMINAL_ATTR)
X         {
X	    if (options->split_search_method == BEAM) 
X	    {
X               for (j = 0; j < attribute->num_values; ++j)
X               {
X                  split = get_new_split(BOOLEAN_SPLIT, 2, attr_info);
X                  split->type_specific.boolean.attribute = i;
X                  split->type_specific.boolean.value = j;
X                  split->type_specific.boolean.bool_attr = FALSE;
X		  list = add_split(list, split);
X               }
X	    }
X	    else
X	    {
X	       split = get_new_split(NOMINAL_SPLIT, attribute->num_values,
X				     attr_info);
X	       split->type_specific.nominal.attribute = i;
X	       list = add_split(list, split);
X	    }
X         }
X         else if (attribute->type == BOOLEAN_ATTR)
X         {
X            split = get_new_split(BOOLEAN_SPLIT, 2, attr_info);
X            split->type_specific.boolean.attribute = i;
X            split->type_specific.boolean.value = 1;
X            split->type_specific.boolean.bool_attr = TRUE;
X	    list = add_split(list, split);
X         }
X      }
X   }
X
X   return(list);
X}
X
X
Xvoid print_constraint(constraint, attr_info)
X   Constraint *constraint;
X   AttributeInfo *attr_info;
X{
X   Attribute *attribute;
X   int value;
X   float threshold;
X   char *label;
X
X   switch (constraint->split->type)
X   {
X      case NOMINAL_SPLIT:
X	attribute = &attr_info->attributes[Get_Nominal_Attr(constraint->split)];
X	value = constraint->branch;
X	printf("\t%s = %s\n", attribute->name, attribute->labels[value]);
X	break;
X      case M_OF_N_SPLIT:
X	attribute = &attr_info->attributes[constraint->member->attribute];
X	if (attribute->type == BOOLEAN_ATTR)
X	{
X	   label = constraint->member->value.discrete ? "true" : "false";
X	   if (constraint->branch)
X	      printf("\tmofn(%s != %s)\n", attribute->name, label);
X	   else
X	      printf("\tmofn(%s = %s)\n", attribute->name, label);
X	}
X	else if (attribute->type == NOMINAL_ATTR)
X	{
X	   value = constraint->member->value.discrete;
X	   label = attribute->labels[value];
X	   if (constraint->branch)
X	      printf("\tmofn(%s != %s)\n", attribute->name, label);
X	   else
X	      printf("\tmofn(%s = %s)\n", attribute->name, label);
X	}
X	else if (attribute->type == REAL_ATTR)
X	{
X	   threshold = constraint->member->value.real;
X	   if (constraint->branch == (int) constraint->member->negated)
X	      printf("\tmofn(%s <= %f)\n", attribute->name, threshold); 
X	   else
X	      printf("\tmofn(%s > %f)\n", attribute->name, threshold); 
X	}
X	break;
X      case REAL_SPLIT:
X	attribute = &attr_info->attributes[Get_Real_Attr(constraint->split)];
X	threshold = Get_Threshold(constraint->split);
X	if (constraint->branch)
X	   printf("\t%s > %f\n", attribute->name, threshold);
X	else
X	   printf("\t%s <= %f\n", attribute->name, threshold);
X	break;
X      case BOOLEAN_SPLIT:
X	attribute = &attr_info->attributes[Get_Boolean_Attr(constraint->split)];
X	if (attribute->type == BOOLEAN_ATTR)
X	{
X	   label = (constraint->branch) ? "false" : "true";
X	   printf("\t%s = %s\n", attribute->name, label);
X	}
X	else
X	{
X	   label = attribute->labels[Get_Boolean_Value(constraint->split)];
X	   if (constraint->branch)
X	      printf("\t%s != %s\n", attribute->name, label);
X	   else
X	      printf("\t%s = %s\n", attribute->name, label);
X	}
X	break;
X   }
X}
X
X
Xvoid print_constraints(constraints, attr_info)
X   Constraint **constraints;
X   AttributeInfo *attr_info;
X{
X   Constraint *constraint;
X   int i;
X
X   for (i = 0; i < attr_info->number; ++i)
X      if (constraints[i] != NULL)
X      {
X	 printf("%s:\n", attr_info->attributes[i].name);
X	 constraint = constraints[i];
X	 while (constraint)
X	 {
X	    print_constraint(constraint, attr_info);
X	    constraint = constraint->next;
X	 }
X      }
X}
X
X
Xvoid unset_constraint(split, constraints)
X   Split *split;
X   Constraint **constraints;
X{
X   int attribute;
X   Constraint *temp, *prev;
X   Member *member;
X
X   switch (split->type)
X   {
X      case NOMINAL_SPLIT:
X	 attribute = Get_Nominal_Attr(split);
X	 prev = NULL;
X	 temp = constraints[attribute];
X	 while (temp->split != split)
X	 {
X	    prev = temp;
X	    temp = temp->next;
X	 }
X	 if (prev)
X	    prev->next = temp->next;
X	 else
X	    constraints[attribute] = temp->next; 
X	 check_free((void *) temp);
X	 break;
X      case M_OF_N_SPLIT:
X	 member = Get_Members(split);
X	 while (member)
X	 {
X	    attribute = member->attribute;
X	    prev = NULL;
X	    temp = constraints[attribute];
X	    while (temp != NULL)
X	    {
X	       if (temp->split == split)
X	       {
X	          if (prev)
X	             prev->next = temp->next;
X	          else
X	             constraints[attribute] = temp->next; 
X	          check_free((void *) temp);
X		  temp = (prev == NULL) ? constraints[attribute] : prev->next;
X	       }
X	       else
X	       {
X		  prev = temp;
X		  temp = temp->next;
X	       }
X	    }
X	    member = member->next;
X	 }
X	 break;
X      case REAL_SPLIT:
X	 attribute = Get_Real_Attr(split);
X	 prev = NULL;
X	 temp = constraints[attribute];
X	 while (temp->split != split)
X	 {
X	    prev = temp;
X	    temp = temp->next;
X	 }
X	 if (prev)
X	    prev->next = temp->next;
X	 else
X	    constraints[attribute] = temp->next; 
X	 check_free((void *) temp);
X	 break;
X      case BOOLEAN_SPLIT:
X	 attribute = Get_Boolean_Attr(split);
X	 prev = NULL;
X	 temp = constraints[attribute];
X	 while (temp->split != split)
X	 {
X	    prev = temp;
X	    temp = temp->next;
X	 }
X	 if (prev)
X	    prev->next = temp->next;
X	 else
X	    constraints[attribute] = temp->next; 
X	 check_free((void *) temp);
X	 break;
X   }
X}
X
X
Xvoid set_constraint(split, branch, constraints)
X   Split *split;
X   int branch;
X   Constraint **constraints;
X{
X   int attribute;
X   Constraint *new_one;
X   Member *member;
X
X   switch (split->type)
X   {
X      case NOMINAL_SPLIT:
X	 attribute = Get_Nominal_Attr(split);
X	 new_one = (Constraint *) check_malloc(sizeof(Constraint));
X	 new_one->split = split;
X	 new_one->branch = branch;
X	 new_one->next = constraints[attribute];
X	 constraints[attribute] = new_one;
X	 break;
X      case M_OF_N_SPLIT:
X	 member = Get_Members(split);
X	 while (member)
X	 {
X	    attribute = member->attribute;
X	    new_one = (Constraint *) check_malloc(sizeof(Constraint));
X	    new_one->split = split;
X	    new_one->branch = branch;
X	    new_one->member = member;
X	    new_one->next = constraints[attribute];
X	    constraints[attribute] = new_one;
X	    member = member->next;
X	 }
X	 break;
X      case REAL_SPLIT:
X	 attribute = Get_Real_Attr(split);
X	 new_one = (Constraint *) check_malloc(sizeof(Constraint));
X	 new_one->split = split;
X	 new_one->branch = branch;
X	 new_one->next = constraints[attribute];
X	 constraints[attribute] = new_one;
X	 break;
X      case BOOLEAN_SPLIT:
X	 attribute = Get_Boolean_Attr(split);
X	 new_one = (Constraint *) check_malloc(sizeof(Constraint));
X	 new_one->split = split;
X	 new_one->branch = branch;
X	 new_one->next = constraints[attribute];
X	 constraints[attribute] = new_one;
X	 break;
X   }
X}
X
X
Xstatic void make_leaf(node, parent, options, attr_info, constraints,
X		      covered, stop_reason)
X   TreeNode *node;
X   TreeNode *parent;
X   Options *options;
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   char covered;
X   StopReason stop_reason;
X{
X   node->type = LEAF;
X   node->type_specific.leaf.covered = covered;
X   node->type_specific.leaf.stop_reason = stop_reason;
X
X   if (node->class == NO_CLASS)
X      node->class = parent->class;
X
X}
X
X
Xstatic int sampling_stop(node, options, attr_info, constraints)
X   TreeNode *node;
X   Options *options;
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X{
X   Example example;
X   float prop;
X   int needed;
X   int success;
X   Distribution **local_distributions;
X   ValueType class;
X   int instance = 0;
X   int i;
X
X   if (!options->oracle)
X      return(FALSE);
X
X   prop = Get_Predicted_Class_Total(node) / Get_Total(node);
X   if (prop != 1.0)
X      return(FALSE);
X
X   if (node->class == NO_CLASS)
X      node->class = 0;
X
X   needed = (int) (options->stop_z * options->stop_z *
X		  (1.0 - options->stop_epsilon) / options->stop_epsilon);
X
X   if (Get_Total(node) > needed)
X      return(TRUE);
X
X   example.oracle.missing = TRUE;
X   example.values = (Value *) check_malloc(sizeof(Value) * attr_info->number);
X   local_distributions = (options->distribution_type == LOCAL) ?
X			 get_local_distributions(node) : NULL;
X
X   for (i = (int) Get_Total(node); i < needed; ++i)
X   {
X      success = sample(attr_info, &example, constraints, options,
X		       local_distributions);
X      if (success)
X      {
X         class = get_class(&example, attr_info, options);
X         check_sample(attr_info, tree_root, node, &example, constraints,
X		      instance);
X         ++instance;
X
X         node->s_distribution[class.discrete] += 1.0;
X         node->s_total += 1.0;
X         if (Get_Class_Total(node, class.discrete) >
X	     Get_Predicted_Class_Total(node))
X            node->class = class.discrete;
X
X         prop = Get_Predicted_Class_Total(node) / Get_Total(node);
X      }
X
X      if (!success || prop != 1.0)
X      {
X         check_free((void *) example.values);
X         return(FALSE);
X      }
X   }
X
X   check_free((void *) example.values);
X   return(TRUE);
X}
X
X
Xstatic int children_predict_same(node)
X   TreeNode *node;
X{
X   Split *split;
X   TreeNode *child;
X   int i;
X
X   split = Get_Split(node);
X   for (i = 0; i < split->arity; ++i)
X   {
X      child = Get_Nth_Child(node, i);
X      if (child->type != LEAF || child->class != node->class)
X	 return(FALSE);
X   }
X
X   return(TRUE);
X}
X
X
Xstatic void validation_prune(node, best)
X   TreeNode *node;
X   int best;
X{
X   int num_children;
X   int i;
X
X   if (node->type == INTERNAL)
X   {
X      num_children = node->type_specific.internal.split->arity;
X      if (node->number > best)
X      {
X	 for (i = 0; i < num_children; ++i)
X	    free_tree(Get_Nth_Child(node, i));
X
X         node->type = LEAF;
X         node->type_specific.leaf.covered = FALSE;
X         node->type_specific.leaf.stop_reason = S_GLOBAL;
X      }
X      else
X      {
X         for (i = 0; i < num_children; ++i)
X            validation_prune(Get_Nth_Child(node, i), best);
X      }
X   }
X}
X
X
Xstatic void unnecessary_node_prune(node)
X   TreeNode *node;
X{
X   int num_children;
X   int i;
X
X   if (node->type == INTERNAL)
X   {
X      num_children = node->type_specific.internal.split->arity;
X      for (i = 0; i < num_children; ++i)
X      {
X         unnecessary_node_prune(Get_Nth_Child(node, i));
X      }
X
X      if (children_predict_same(node))
X      {
X	 for (i = 0; i < num_children; ++i)
X	    free_tree(Get_Nth_Child(node, i));
X
X         node->type = LEAF;
X         node->type_specific.leaf.covered = FALSE;
X         node->type_specific.leaf.stop_reason = S_SIMPLIFIED;
X      }
X   }
X}
X
X
Xstatic float split_ORT(attr_info, split)
X   AttributeInfo *attr_info;
X   Split *split;
X{
X   float dot_product = 0.0;
X   float magnitude_0 = 0.0;
X   float magnitude_1 = 0.0;
X   float ORT;
X   int i;
X
X   if (split->arity != 2)
X      error("System error", "cannot use ORT measure for non-binary splits",
X	    TRUE);
X
X   for (i = 0; i < attr_info->num_classes; ++i)
X   {
X      magnitude_0 += split->class_distr[0][i] * split->class_distr[0][i];
X      magnitude_1 += split->class_distr[1][i] * split->class_distr[1][i];
X      dot_product += split->class_distr[0][i] * split->class_distr[1][i];
X   }
X
X   magnitude_0 = sqrt((double) magnitude_0);
X   magnitude_1 = sqrt((double) magnitude_1);
X
X   if (magnitude_0 == 0.0 || magnitude_1 == 0.0)
X      return(0.0);
X
X   ORT = 1.0 - (dot_product / (magnitude_0 * magnitude_1));
X
X   return(ORT);
X}
X
X
Xvoid evaluate_splits(attr_info, ex_info, example_mask, options, splits)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Options *options;
X   Split *splits;
X{
X   Example *example;
X   Split *split;
X   ValueType class;
X   float info, base_info;
X   float avg_gain, possible_info;
X   int counted;
X   int done = FALSE;
X   int i;
X   int ex;
X
X   split = splits;
X   while (split)
X   {
X      if (split->can_use)
X         reset_statistics(split, attr_info->num_classes);
X      split = split->next;
X   }
X
X   for (i = 0, ex = 0; i < ex_info->number; ++i)
X      if (example_mask[i] != 0.0)
X      {
X         ++ex;
X         class = get_class(&ex_info->examples[i], attr_info, options);
X         split = splits;
X         while (split)
X         {
X	    if (split->can_use)
X               update_statistics(split, attr_info, &ex_info->examples[i], class,
X                                 example_mask[i]);
X            split = split->next;
X         }
X      }
X
X   if (options->do_sampling && options->min_sample)
X   {
X      reset_sample_index();
X      for ( ; ex < options->min_sample && done == FALSE; ++ex)
X      {
X         example = get_sample_instance();
X	 if (example != NULL)
X	 {
X            class = get_class(example, attr_info, options);
X            split = splits;
X            while (split)
X            {
X	       if (split->can_use)
X                  update_statistics(split, attr_info, example, class, 1.0);
X               split = split->next;
X            }
X	 }
X	 else
X	    done = TRUE;
X      }
X   }
X
X   if (options->split_method == GAIN || options->split_method == GAIN_RATIO)
X   {
X      avg_gain = 0.0;
X      counted = 0;
X      split = splits;
X      while (split)
X      {
X         if (split->can_use)
X         {
X            base_info = base_information(split, attr_info->num_classes);
X            info = split_information(split, attr_info->num_classes);
X            split->gain = (split->total - split->missing) / split->total *
X		          (base_info - info);
X
X            if (split->gain > - EPSILON &&
X		split->arity < 0.3 * ex_info->number)
X            {
X	       avg_gain += split->gain;
X	       ++counted;
X            }
X         }
X         split = split->next;
X      }
X
X      if (options->split_method == GAIN_RATIO)
X      {
X         avg_gain = counted ? avg_gain / counted : 1E6;
X
X         split = splits;
X         while (split)
X         {
X            if (split->can_use)
X	    {
X	       possible_info = possible_information(split);
X	       if (split->gain >= avg_gain  - EPSILON &&
X		   possible_info > EPSILON)
X	          split->gain /= possible_info;
X	    }
X   
X            split = split->next;
X         }
X      }
X   }
X   else if (options->split_method == ORT)
X   {
X      split = splits;
X      while (split)
X      {
X         if (split->can_use)
X            split->gain = split_ORT(attr_info, split);
X         split = split->next;
X      }
X   }
X}
X
X
XSplit *pick_split(options, splits, ex_info, example_mask)
X   Options *options;
X   Split *splits;
X   ExampleInfo *ex_info;
X   float *example_mask;
X{
X   Split *split, *best_split;
X
X   best_split = NULL;
X   split = splits;
X   while (split)
X   {
X      if (split->can_use && !trivial_split(split, options->min_objects) &&
X	  (!options->do_sampling ||
X	   !trivial_split_when_sampling(split, ex_info, example_mask, options)))
X      {
X         if (!best_split || split->gain > best_split->gain)
X            best_split = split;
X      }
X
X      split = split->next;
X   }
X
X   if (best_split && best_split->gain == 0.0)
X      best_split = NULL;
X
X   return(best_split);
X}
X
X
Xstatic Split *make_split(attr_info, ex_info, example_mask, options, splits)
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Options *options;
X   Split *splits;
X{
X   Split *best_split, *look_split;
X   float best_gain;
X
X   evaluate_splits(attr_info, ex_info, example_mask, options, splits);
X
X/*
Xprint_splits(attr_info, splits, stdout);
X*/
X
X   best_split = pick_split(options, splits, ex_info, example_mask);
X
X/*
X   if (options->split_search_method == LOOKAHEAD)
X   {
X      best_gain = (best_split != NULL) ? best_split->gain : 0.0;
X      look_split = lookahead_make_split(attr_info, ex_info, example_mask,
X					options, splits);
X      if (look_split && look_split->gain > best_gain)
X	 best_split = look_split;
X   }
X*/
X
X   return(best_split);
X}
X
X
Xstatic void unset_node_state(node, constraints)
X   TreeNode *node;
X   Constraint **constraints;
X{
X   Split *split;
X
X   while (node->parent)
X   {
X      node = node->parent;
X      split = Get_Split(node);
X      split->can_use = TRUE;
X      unset_constraint(split, constraints);
X   }
X}
X
X
Xstatic void set_node_state(node, constraints)
X   TreeNode *node;
X   Constraint **constraints;
X{
X   Split *split;
X   int branch;
X
X   while (node->parent)
X   {
X      branch = node->parent_branch;
X      node = node->parent;
X      split = Get_Split(node);
X      split->can_use = FALSE;
X      set_constraint(split, branch, constraints);
X   }
X}
X
X
Xstatic float calculate_node_priority(node)
X   TreeNode *node;
X{
X   float priority;
X   int branch;
X
X   if (node->type != LEAF)
X      error("System error", "non-leaf passed to calculate_node_priority", TRUE);
X
X   priority = 1.0 - Get_Proportion(node);
X
X   while (node->parent)
X   {
X      branch = node->parent_branch;
X      node = node->parent;
X      priority *= Get_Nth_Prob(node, branch);
X   }
X
X   return(priority);
X}
X
X
Xstatic void free_queue(queue)
X   PriorityQueue *queue;
X{
X   PriorityQueue *temp;
X
X   while (queue != NULL)
X   {
X      temp = queue;
X      queue = queue->next;
X      check_free((void *) temp->mask);
X      check_free((void *) temp);
X   }
X}
X
X
Xstatic PriorityQueue *insert_node_into_queue(node, priority, mask, queue)
X   TreeNode *node;
X   float priority;
X   float *mask;
X   PriorityQueue *queue;
X{
X   PriorityQueue *new_one;
X   PriorityQueue *current, *prev;
X
X   new_one = (PriorityQueue *) check_malloc(sizeof(PriorityQueue));
X   new_one->node = node;
X   new_one->priority = priority; 
X   new_one->mask = mask;
X   new_one->next = NULL;
X
Xprintf("INSERTING NODE WITH PRIORITY %.3f INTO QUEUE\n", priority);
X
X   current = queue;
X   prev = NULL;
X   while (current && current->priority >= new_one->priority)
X   {
X      prev = current;
X      current = current->next;
X   }
X
X   if (prev)
X   {
X      prev->next = new_one;
X      new_one->next = current;
X   }
X   else
X   {
X      queue = new_one;
X      new_one->next = current;
X   }
X
X   return(queue);
X}
X
X
Xstatic PriorityQueue *remove_node_from_queue(queue, node, mask)
X   PriorityQueue *queue;
X   TreeNode **node;
X   float **mask;
X{
X   PriorityQueue *temp;
X
X   if (queue)
X   {
Xprintf("REMOVING NODE WITH PRIORITY %.3f FROM QUEUE\n\n", queue->priority);
X      *node = queue->node;
X      *mask = queue->mask;
X      temp = queue;
X      queue = queue->next;
X      check_free((void *) temp);
X   }
X   else
X   {
X      *node = NULL;
X      *mask = NULL;
X   }
X
X   return(queue);
X}
X
X
Xstatic PriorityQueue *expand_tree_node(node, ex_info, example_mask, splits,
X				       attr_info, constraints, options, queue)
X   TreeNode *node;
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Split *splits;
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   Options *options;
X   PriorityQueue *queue;
X{
X   Split *discrete_splits;
X   Split *best_split;
X   TreeNode *child;
X   float **children_masks;
X   float priority;
X   int samples_needed;
X   Distribution **local_distributions;
X   Distribution **ancestor_distributions;
X   int i;
X
X   discrete_splits = splits;
X   splits = add_real_valued_splits(attr_info, ex_info, example_mask,
X				   options, constraints, splits);
X   
X   if (options->split_search_method == BEAM)
X   {
X      best_split = ID2_of_3_beam(attr_info, ex_info, example_mask, constraints,
X                                 options, splits);
X   }
X   else
X   {
X      best_split = make_split(attr_info, ex_info, example_mask, options, 
X			      splits);
X   }
X
X   if (!best_split)
X   {
X      node->type_specific.leaf.stop_reason = S_NO_PICK_SPLIT;
X      return(queue);
X   }
X
X   node->type = INTERNAL;
X   node->type_specific.internal.split = best_split;
X   ++best_split->reference_count;
X
X   if (discrete_splits != splits)
X   {
X      if (discrete_splits)
X      {
X         discrete_splits->prev->next = NULL;
X         discrete_splits->prev = NULL;
X      }
X      free_unused_splits(splits);
X      splits = discrete_splits;
X   }
X
X   node->type_specific.internal.probs =
X      (float *) check_malloc(sizeof(float) * best_split->arity);
X   for (i = 0; i < best_split->arity; ++i)
X      node->type_specific.internal.probs[i] = best_split->branch_distr[i] /
X                                      (best_split->total - best_split->missing);
X
X   children_masks = make_masks(node, ex_info, example_mask);
X
X   node->type_specific.internal.children =
X      (TreeNode **) check_malloc(sizeof(TreeNode *) * best_split->arity);
X
X   /* for debugging */
X   for (i = 0; i < best_split->arity; ++i)
X      node->type_specific.internal.children[i] = NULL; 
X
X   for (i = 0; i < best_split->arity; ++i)
X   {
X      node->type_specific.internal.children[i] = (TreeNode *)
X                                                 check_malloc(sizeof(TreeNode));
X      child = node->type_specific.internal.children[i];
X      child->parent = node;
X      child->number = -1;
X      child->parent_branch = i;
X      child->distributions = NULL;
X      example_distribution(child, ex_info, attr_info, options,
X			   children_masks[i]);
X
X      set_constraint(best_split, i, constraints);
X
X      if (options->do_sampling)
X      {
X         if (options->distribution_type == LOCAL &&
X	     child->e_total >= options->min_estimation_sample)
X         {
X            ancestor_distributions = get_local_distributions(child);
X	    child->distributions = determine_local_distributions(attr_info,
X				      ex_info, children_masks[i], constraints,
X				      ancestor_distributions, options);
X         }
X
X         samples_needed = options->min_sample - (int) child->e_total;
X         if (samples_needed > 0)
X	 {
X	    local_distributions = (options->distribution_type == LOCAL) ?
X			          get_local_distributions(child) : NULL;
X            get_new_sample(attr_info, constraints, options, samples_needed,
X			   local_distributions, child);
X            sample_distribution(child, samples_needed, attr_info, options);
X	 }
X      }
X
X      make_leaf(child, node, options, attr_info, constraints, FALSE, S_GLOBAL);
X
X      if (options->do_sampling && options->sampling_stop &&
X	  sampling_stop(child, options, attr_info, constraints))
X      {
X	 child->type_specific.leaf.stop_reason = S_SAMPLING;
X	 check_free((void *) children_masks[i]);
X      }
X      else if (Get_Total(child) < 2 * options->min_objects)
X      {
X	 child->type_specific.leaf.stop_reason = S_MIN_OBJECTS;
X	 check_free((void *) children_masks[i]);
X      }
X      else if (Get_Total_Error(child) == 0.0)
X      {
X	 child->type_specific.leaf.stop_reason = S_ERROR;
X	 check_free((void *) children_masks[i]);
X      }
X      else if ((priority = calculate_node_priority(child)) == 0.0)
X      {
X	 child->type_specific.leaf.stop_reason = S_ZERO_BRANCH_PROB;
X	 check_free((void *) children_masks[i]);
X      }
X      else
X      {
X         priority = calculate_node_priority(child);
X         queue = insert_node_into_queue(child, priority, children_masks[i],
X					queue);
X      }
X
X      unset_constraint(best_split, constraints);
X   }
X
X   check_free((void *) children_masks);
X
X   return(queue);
X}
X
X
Xfloat measure_fidelity(tree, ex_info, attr_info, options, matrix)
X   TreeNode *tree;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X   int **matrix;
X{
X   int **confusion_matrix;
X   int correct;
X   float fidelity;
X   int (*saved_oracle)();
X   int saved_use_oracle_flag;
X   int i;
X
X   if (matrix == NULL)
X      confusion_matrix = get_confusion_matrix(attr_info->num_classes);
X   else
X      confusion_matrix = matrix;
X
X   saved_oracle = options->oracle;
X   saved_use_oracle_flag = options->use_oracle;
X   register_network_oracle(&options->oracle);
X   options->use_oracle = TRUE;
X
X   classify_using_tree(tree, ex_info, attr_info, options, confusion_matrix,
X                       NULL, FALSE);
X
X   for (i = 0, correct = 0; i < attr_info->num_classes; ++i)
X      correct += confusion_matrix[i][i];
X
X   options->oracle = saved_oracle;
X   options->use_oracle = saved_use_oracle_flag;
X
X   if (matrix == NULL)
X      free_confusion_matrix(confusion_matrix, attr_info->num_classes);
X
X   fidelity = 1.0 * correct / ex_info->number;
X   return(fidelity);
X}
X
X
Xstatic float measure_accuracy(tree, ex_info, attr_info, options, matrix)
X   TreeNode *tree;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X   int **matrix;
X{
X   int **confusion_matrix;
X   int correct;
X   float accuracy;
X   int (*saved_oracle)();
X   int saved_use_oracle_flag;
X   int i;
X
X   if (matrix == NULL)
X      confusion_matrix = get_confusion_matrix(attr_info->num_classes);
X   else
X      confusion_matrix = matrix;
X
X   saved_oracle = options->oracle;
X   saved_use_oracle_flag = options->use_oracle;
X   options->oracle = NULL;
X   options->use_oracle = FALSE;
X
X   classify_using_tree(tree, ex_info, attr_info, options, confusion_matrix,
X                       NULL, FALSE);
X
X   for (i = 0, correct = 0; i < attr_info->num_classes; ++i)
X      correct += confusion_matrix[i][i];
X
X   options->oracle = saved_oracle;
X   options->use_oracle = saved_use_oracle_flag;
X
X   if (matrix == NULL)
X      free_confusion_matrix(confusion_matrix, attr_info->num_classes);
X
X   accuracy = 1.0 * correct / ex_info->number;
X   return(accuracy);
X}
X
X
X/*
X	is proportion information accurately maintained for leaves
X	test stopping criteria before putting root on queue
X*/
Xstatic TreeNode *best_first(train_examples, train_mask, splits, attr_info, 
X			    constraints, options, size, test_examples,
X			    validation_examples, pfname)
X   ExampleInfo *train_examples;
X   float *train_mask;
X   Split *splits;
X   AttributeInfo *attr_info;
X   Constraint **constraints;
X   Options *options;
X   int size;
X   ExampleInfo *test_examples;
X   ExampleInfo *validation_examples;
X   char *pfname;
X{
X   TreeNode *root, *current;
X   PriorityQueue *queue = NULL;
X   int internal_nodes = 0;
X   float priority;
X   FILE *pfile = NULL;
X   float fidelity, accuracy;
X   float last_fidelity;
X   int samples_needed;
X   int changed;
X   int patience_counter = 0;
X   int patience_stop = FALSE;
X   Distribution **local_distributions;
X   float *fidelity_values;
X   ExampleInfo *validation_set = NULL;
X   float *example_mask;
X
X   root = (TreeNode *) check_malloc(sizeof(TreeNode));
X
Xtree_root = root;
X   example_distribution(root, train_examples, attr_info, options, train_mask);
X   if (root->class == NO_CLASS)
X      error(prog_name, "none of the training examples has a class label", TRUE);
X   make_leaf(root, NULL, options, attr_info, constraints, FALSE, S_GLOBAL);
X   root->number = 0;
X   root->parent = NULL;
X   root->distributions = NULL;
X
X   if (options->do_sampling && options->distribution_type == LOCAL &&
X       root->e_total >= options->min_estimation_sample)
X   {
X      root->distributions = determine_local_distributions(attr_info,
X			       train_examples, train_mask, constraints,
X			       NULL, options);
X   }
X
X   priority = calculate_node_priority(root);
X/*
X   priority = new_calculate_node_priority(root, train_examples, options);
X*/
X
X
X   queue = insert_node_into_queue(root, priority, train_mask, queue);
X
X   if (options->patience_threshold > 0.0)
X   {
X      fidelity = measure_fidelity(root, train_examples, attr_info,
X				  options, NULL);
X      last_fidelity = fidelity;
X   }
X
X   if (options->validation_stop)
X   {
X      if (validation_examples->number == 0)
X	 validation_set = train_examples;
X      else
X	 validation_set = validation_examples;
X      fidelity_values = (float *) check_malloc(sizeof(float) * (size + 1));
X      fidelity_values[0] = measure_fidelity(root, validation_set, attr_info,
X					    options, NULL);
X   }
X
X   if (pfname)
X   {
X      pfile = check_fopen(pfname, "w");
X      fprintf(pfile, "nodes\ttrain fidelity\ttrain accuracy");
X      if (validation_examples->number != 0)
X	 fprintf(pfile, "\tvalid fidelity\tvalid accuracy");
X      if (test_examples->number != 0)
X	 fprintf(pfile, "\ttest fidelity\ttest accuracy");
X      fprintf(pfile, "\tlast gain\tchanged\n\n");
X      if (options->patience_threshold <= 0.0)
X         fidelity = measure_fidelity(root, train_examples, attr_info,
X				     options, NULL);
X      accuracy = measure_accuracy(root, train_examples, attr_info,
X				  options, NULL);
X      fprintf(pfile, "%d\t%f\t%f", internal_nodes, fidelity, accuracy);
X      if (validation_examples->number != 0)
X      {
X	 if (validation_set == validation_examples)
X	    fidelity = fidelity_values[0];
X	 else
X            fidelity = measure_fidelity(root, validation_examples, attr_info,
X				        options, NULL);
X         accuracy = measure_accuracy(root, validation_examples, attr_info,
X				     options, NULL);
X         fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
X      }
X      if (test_examples->number != 0)
X      {
X         fidelity = measure_fidelity(root, test_examples, attr_info,
X				     options, NULL);
X         accuracy = measure_accuracy(root, test_examples, attr_info,
X				     options, NULL);
X         fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
X      }
X      fprintf(pfile, "\n");
X      fflush(pfile);
X   }
X
X   while (queue != NULL && internal_nodes < size && !patience_stop)
X   {
X      queue = remove_node_from_queue(queue, &current, &example_mask);
X
X      set_node_state(current, constraints);
X      if (options->do_sampling)
X      {
X         samples_needed = options->min_sample - (int) current->e_total;
X         if (samples_needed > 0)
X	 {
X	    local_distributions = (options->distribution_type == LOCAL) ?
X			          get_local_distributions(current) : NULL;
X            get_new_sample(attr_info, constraints, options, samples_needed,
X			   local_distributions, current);
X	 }
X      }
X
X/*
Xif (options->do_sampling && options->distribution_type == LOCAL)
X{
X   local_distributions = (options->distribution_type == LOCAL) ?
X			  get_local_distributions(current) : NULL;
X   printf("LOCAL DISTRIBUTIONS:\n");
X   print_attribute_distributions(attr_info, options, local_distributions);
X}
X*/
X
X      queue = expand_tree_node(current, train_examples, example_mask, splits,
X			       attr_info, constraints, options, queue);
X
X      unset_node_state(current, constraints);
X
X      if (current->type == INTERNAL)
X      {
X         ++internal_nodes;
X	 current->number = internal_nodes;
X
X         changed = !children_predict_same(current);
X	 if (changed && options->patience_threshold > 0.0)
X	 {
X            fidelity = measure_fidelity(root, train_examples, attr_info,
X				        options, NULL);
X	    if (fidelity - last_fidelity < options->patience_threshold)
X	       ++patience_counter;
X	    else
X	       patience_counter = 0;
X
X	    if (patience_counter == options->patience_counter)
X	    {
X	       patience_stop = TRUE;
X               printf("Stopping patience reached: ");
X	       printf("last fidelity = %f, this fidelity = %f\n",
X		      last_fidelity, fidelity);
X	    }
X            last_fidelity = fidelity;
X	 }
X
X         if (options->validation_stop)
X         {
X            fidelity_values[internal_nodes] = measure_fidelity(root,
X	                         validation_set, attr_info, options, NULL);
X         }
X
X         if (pfile)
X         {
X	    if (validation_set == train_examples)
X	       fidelity = fidelity_values[internal_nodes];
X	    else
X	       fidelity = measure_fidelity(root, train_examples, attr_info,
X				           options, NULL);
X	    accuracy = measure_accuracy(root, train_examples, attr_info,
X				        options, NULL);
X	    fprintf(pfile, "%d\t%f\t%f", internal_nodes, fidelity, accuracy);
X            if (validation_examples->number != 0)
X            {
X	       if (validation_set == validation_examples)
X	          fidelity = fidelity_values[internal_nodes];
X	       else
X                  fidelity = measure_fidelity(root, validation_examples,
X					      attr_info, options, NULL);
X               accuracy = measure_accuracy(root, validation_examples, attr_info,
X				           options, NULL);
X               fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
X            }
X            if (test_examples->number != 0)
X            {
X               fidelity = measure_fidelity(root, test_examples, attr_info,
X				           options, NULL);
X               accuracy = measure_accuracy(root, test_examples, attr_info,
X				           options, NULL);
X               fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
X            }
X	    fprintf(pfile, "\t%f", Get_Split(current)->gain);
X	    if (changed)
X	       fprintf(pfile, "\t*\n");
X	    else
X               fprintf(pfile, "\n");
X            fflush(pfile);
X         }
X      }
X
X      if (example_mask != train_mask)
X         check_free((void *) example_mask);
X   }
X
Xprintf("\nSTOPPING CRITERIA MET:\n");
Xif (patience_stop)
X   printf("\tpatience reached\n");
Xif (internal_nodes >= size)
X   printf("\tsize limit reached\n");
Xif (queue == NULL)
X   printf("\tqueue empty\n");
X
X   if (options->validation_stop)
X   {
X      int i;
X      int best = 0;
X
X      for (i = 1; i <= internal_nodes; ++i)
X	 if (fidelity_values[i] > fidelity_values[best])
X	    best = i;
X
Xprintf("BEST TREE HAS %d NODES\n", best);
X
X      check_free((void *) fidelity_values);
X      validation_prune(root, best);
X   }
X
X   if (pfile)
X      fclose(pfile);
X   free_queue(queue);
X
X   return(root);
X}
X
X
Xstatic TreeNode *make_subtree(ex_info, example_mask, splits, attr_info, 
X			      parent, constraints, options, depth)
X   ExampleInfo *ex_info;
X   float *example_mask;
X   Split *splits;
X   AttributeInfo *attr_info;
X   TreeNode *parent;
X   Constraint **constraints;
X   Options *options;
X   int depth;
X{
X   int i;
X   Split *best_split;
X   Split *discrete_splits;
X   TreeNode *node;
X   float **children_masks;
X   int samples_needed;
X   Distribution **local_distributions;
X   Distribution **ancestor_distributions;
X
X   /* add candidate splits for real-valued attributes */
X   discrete_splits = splits;
X   splits = add_real_valued_splits(attr_info, ex_info, example_mask,
X				   options, constraints, splits);
X
X   node = (TreeNode *) check_malloc(sizeof(TreeNode));
X   node->distributions = NULL;
X   node->parent = parent;
X   if (!parent)
X      tree_root = node;
X   else
X   {
X/* for debugging only */
X      for (i = 0; parent->type_specific.internal.children[i]; ++i)
X	 ;
X      parent->type_specific.internal.children[i] = node;
X   }
X
X   example_distribution(node, ex_info, attr_info, options, example_mask);
X
Xnode->error = 0.0;
X
X   if (options->do_sampling)
X   {
X      if (options->distribution_type == LOCAL &&
X	  node->e_total >= options->min_estimation_sample)
X      {
X         ancestor_distributions = get_local_distributions(node);
X	 node->distributions = determine_local_distributions(attr_info,
X				  ex_info, example_mask, constraints,
X				  ancestor_distributions, options);
X      }
X
X      samples_needed = options->min_sample - (int) node->e_total;
X      if (samples_needed > 0)
X      {
X	 local_distributions = (options->distribution_type == LOCAL) ?
X			       get_local_distributions(node) : NULL;
X         get_new_sample(attr_info, constraints, options, samples_needed,
X			local_distributions, node);
X         sample_distribution(node, samples_needed, attr_info, options);
X      }
X   }
X
X   /* test to see if this should be a leaf */
X   if (options->do_sampling && options->sampling_stop && 
X       sampling_stop(node, options, attr_info, constraints))
X   {
X      make_leaf(node, parent, options, attr_info, constraints, TRUE,
X		S_SAMPLING);
X      return(node);
X   }
X   else if (Get_Total(node) < 2 * options->min_objects)
X   {
X      make_leaf(node, parent, options, attr_info, constraints, TRUE,
X		S_MIN_OBJECTS);
X      return(node);
X   }
X   else if (Get_Total_Error(node) == 0.0)
X   {
X      make_leaf(node, parent, options, attr_info, constraints, TRUE, S_ERROR);
X      return(node);
X   }
X   else if (splits == NULL)
X   {
X      make_leaf(node, parent, options, attr_info, constraints, TRUE,
X		S_NO_SPLITS);
X      return(node);
X   }
X   else if (depth == options->stop_depth)
X   {
X      make_leaf(node, parent, options, attr_info, constraints, FALSE, S_DEPTH);
X      return(node);
X   }
X
X
X   if (options->split_search_method == BEAM)
X   {
X      best_split = ID2_of_3_beam(attr_info, ex_info, example_mask, constraints,
X			         options, splits);
X   }
X   else
X   {
X      best_split = make_split(attr_info, ex_info, example_mask,
X			      options, splits);
X   }
X
X   if (!best_split)
X   {
X      make_leaf(node, parent, options, attr_info, constraints, FALSE,
X		S_NO_PICK_SPLIT);
X      return(node);
X   }
X
X   node->type = INTERNAL;
X   node->type_specific.internal.split = best_split;
X   ++best_split->reference_count;
X
X   /* remove candidate splits for real-valued attributes */
X   if (discrete_splits != splits)
X   {
X      if (discrete_splits)
X      {
X         discrete_splits->prev->next = NULL;
X         discrete_splits->prev = NULL;
X      }
X      free_unused_splits(splits);
X      splits = discrete_splits;
X   }
X
X   if (best_split->type != M_OF_N_SPLIT && best_split->type != REAL_SPLIT)
X      splits = remove_split(splits, best_split);
X
X
X   node->type_specific.internal.probs = 
X      (float *) check_malloc(sizeof(float) * best_split->arity);
X   for (i = 0; i < best_split->arity; ++i)
X      node->type_specific.internal.probs[i] = best_split->branch_distr[i] /
X	                              (best_split->total - best_split->missing);
X
X   children_masks = make_masks(node, ex_info, example_mask);
X
X   node->type_specific.internal.children = 
X      (TreeNode **) check_malloc(sizeof(TreeNode *) * best_split->arity);
X
X#ifdef DEBUG
X#endif
X	for (i = 0; i < best_split->arity; ++i)
X	   node->type_specific.internal.children[i] = NULL;
X
X   node->error = 0.0;
X   for (i = 0; i < best_split->arity; ++i)
X   {
X      set_constraint(best_split, i, constraints);
X      node->type_specific.internal.children[i] = 
X	 make_subtree(ex_info, children_masks[i], splits, attr_info, 
X		      node, constraints, options, depth + 1);
X
X      if (!options->do_sampling)
X         node->error += node->type_specific.internal.children[i]->error;
X      else
X         node->error += node->type_specific.internal.probs[i] *
X			node->type_specific.internal.children[i]->error;
X
X      unset_constraint(best_split, constraints);
X   }
X   free_masks(children_masks, best_split->arity);
X
X/*
X   if (node->error >= Get_Example_Error(node) - EPSILON || 
X       children_predict_same(node))
X*/
X
X/*
X   if (children_predict_same(node))
X   {
X      printf("COLLAPSE: children error = %.3f, parent error = %.3f\n",
X	     node->error, Get_Example_Error(node));
X
X      split = Get_Split(node);
X      for (i = 0; i < split->arity; ++i)
X         free_tree(Get_Nth_Child(node, i));
X      make_leaf(node, parent, options, attr_info, constraints, TRUE, S_GLOBAL);
X   }
X*/
X
X   if (best_split->type != M_OF_N_SPLIT && best_split->type != REAL_SPLIT)
X      splits = put_split_back(splits, best_split);
X
X   return(node);
X}
X
X
Xstatic void reset_leaf_statistics(node)
X   TreeNode *node;
X{
X   Split *split;
X   int branch;
X
X   if (node->type == LEAF)
X   {
X      node->type_specific.leaf.total = 0.0;
X      node->type_specific.leaf.error = 0.0;
X   }
X   else
X   {
X      split = Get_Split(node);
X      for (branch = 0; branch < split->arity; ++branch)
X         reset_leaf_statistics(Get_Nth_Child(node, branch));
X   }
X}
X
X
Xstatic void determine_class(node, example, weight, distribution,
X			    covered, attr_info, actual)
X   TreeNode *node;
X   Example *example;
X   float weight;
X   float *distribution;
X   int *covered;
X   AttributeInfo *attr_info;
X   int actual;
X{
X   int branch;
X   Split *split;
X   int i;
X
X   if (node->type == LEAF)
X   {
X      if (Get_Total(node) > 0.0)
X         for (i = 0; i < attr_info->num_classes; ++i)
X            distribution[i] += weight * Get_Class_Total(node, i) /
X			       Get_Total(node);
X      else
X        distribution[node->class] += weight;
X
X      node->type_specific.leaf.total += weight;
X      if (node->class != actual)
X         node->type_specific.leaf.error += weight;
X
X      if (covered)
X      {
X         if (weight == 1.0)
X         {
X	    if (node->type_specific.leaf.covered)
X	        *covered = TRUE;
X	    else
X	       *covered = FALSE;
X         }
X         else
X	    *covered = UNDETERMINED;
X      }
X   }
X   else
X   {
X      branch = which_branch(Get_Split(node), example);
X      if (branch == MISSING)
X      {
X	 split = Get_Split(node);
X	 for (branch = 0; branch < split->arity; ++branch)
X            determine_class(Get_Nth_Child(node, branch), example, 
X			    weight * Get_Nth_Prob(node, branch),
X			    distribution, covered, attr_info, actual);
X      }
X      else
X      {
X         node = Get_Nth_Child(node, branch);
X         determine_class(node, example, weight, distribution, covered,
X			 attr_info, actual);
X      }
X   }
X}
X
X
Xvoid classify_example(tree, example, covered, attr_info, distribution, actual)
X   TreeNode *tree;
X   Example *example;
X   int *covered;
X   AttributeInfo *attr_info;
X   float *distribution;
X   int actual;
X{
X   int i;
X
X   for (i = 0; i < attr_info->num_classes; ++i)
X      distribution[i] = 0.0;
X
X   determine_class(tree, example, 1.0, distribution, covered,
X		   attr_info, actual);
X}
X
X
Xint get_predicted_class(attr_info, distribution)
X   AttributeInfo *attr_info;
X   float *distribution;
X{
X   int class;
X   int i;
X
X   class = 0;
X   for (i = 1; i < attr_info->num_classes; ++i)
X      if (distribution[i] > distribution[class])
X	 class = i;
X
X   return(class);
X}
X
X
Xvoid classify_using_tree(tree, ex_info, attr_info, options,
X			 matrix, covered_matrix, use_test_fold)
X   TreeNode *tree;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X   int **matrix;
X   int **covered_matrix;
X   int use_test_fold;
X{
X   int i;
X   int predicted;
X   ValueType actual;
X   Example *example;
X   int covered;
X   int correct;
X   float *distribution;
X
X   if (ClassIsVector(attr_info))
X   {
X      error("system error",
X	    "tried to use classify_using_tree for class vectors", TRUE);
X   }
X
X   distribution = (float *) check_malloc(sizeof(float) * 
X					 attr_info->num_classes);
X
X   reset_leaf_statistics(tree);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      if ((example->fold == ex_info->test_fold) == use_test_fold)
X      {
X         actual = get_class(example, attr_info, options);
X         classify_example(tree, example, &covered, attr_info, distribution,
X			  actual.discrete);
X         predicted = get_predicted_class(attr_info, distribution);
X         ++matrix[predicted][actual.discrete];
X
X/*
Xprintf("%-10d %-20s %d\n", i,
X       attr_info->attributes[attr_info->class_index].labels[predicted],
X      (int) (predicted == actual.discrete));
X*/
X
X         if (covered_matrix && covered != UNDETERMINED)
X         {
X	    correct = (predicted == actual.discrete);
X	    ++covered_matrix[covered][correct];
X         }
X      }
X   }
X
X   check_free((void *) distribution);
X}
X
X
Xvoid match_any(tree, ex_info, attr_info, options, matrix)
X   TreeNode *tree;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X   Options *options;
X   int **matrix;
X{
X   int i, j;
X   int predicted;
X   int actual_class;
X   ValueType actual;
X   Example *example;
X   float *distribution;
X
X   if (!ClassIsVector(attr_info))
X   {
X      error("system error",
X	    "tried to use match_any for non-vector classes", TRUE);
X   }
X
X   distribution = (float *) check_malloc(sizeof(float) * 
X					 attr_info->num_classes);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      actual = get_class(&ex_info->examples[i], attr_info, options);
X      classify_example(tree, example, NULL, attr_info, distribution,
X		       actual.discrete);
X      predicted = get_predicted_class(attr_info, distribution);
X
X      if (actual.vector[predicted] > 0.0)
X	 actual_class = predicted;
X      else
X      {
X	 /* we'll say the "actual" class is the one w/ largest probability */
X	 actual_class = 0;
X	 for (j = 1; j < attr_info->num_classes; ++j)
X	    if (actual.vector[j] > actual.vector[actual_class])
X	       actual_class = j;
X      }
X
X      ++matrix[predicted][actual_class];
X   }
X
X   check_free((void *) distribution);
X}
X
X
Xfloat calculate_sum_squared_error(tree, ex_info, attr_info)
X   TreeNode *tree;
X   ExampleInfo *ex_info;
X   AttributeInfo *attr_info;
X{
X   int i, j;
X   Example *example;
X   float *distribution;
X   float target, part;
X   float SS_error = 0.0;
X   int class_is_vector = ClassIsVector(attr_info);
X
X   distribution = (float *) check_malloc(sizeof(float) * 
X					 attr_info->num_classes);
X
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      example = &ex_info->examples[i];
X      classify_example(tree, example, NULL, attr_info, distribution, NONE);
X
X      for (j = 0; j < attr_info->num_classes; ++j)
X      {
X	 if (class_is_vector)
X	    target = example->values[attr_info->class_index].value.vector[j];
X	 else
X	 {
X	    target =
X	       (j == example->values[attr_info->class_index].value.discrete) ?
X		     1.0 : 0.0;
X	 }
X	 part = target - distribution[j];
X	 SS_error += 0.5 * part * part;
X      }
X   }
X
X   check_free((void *) distribution);
X
X   return(SS_error);
X}
X
X
Xstatic void determine_min_estimation_sample(train_examples, options)
X   ExampleInfo *train_examples;
X   Options *options;
X{
X   int n = 0;
X   int i;
X
X   for (i = 0; i < train_examples->number; ++i)
X      if (train_examples->examples[i].fold != train_examples->test_fold)
X	 ++n;
X
X   options->min_estimation_sample  = options->min_estimation_fraction * n;
X}
X
X
XTreeNode *induce_tree(attr_info, train_examples, train_mask, test_examples,
X		      validation_examples, options, pfname)
X   AttributeInfo *attr_info;
X   ExampleInfo *train_examples;
X   float *train_mask;
X   ExampleInfo *test_examples;
X   ExampleInfo *validation_examples;
X   Options *options;
X   char *pfname;
X{
X   Split *splits;
X   TreeNode *tree;
X   Constraint **constraints;
X   int i;
X
X
X   if (options->do_sampling && !options->use_oracle)
X   {
X      error("System error", "do_sampling and use_oracle disagree", TRUE);
X   }
X
X   if (options->use_oracle)
X   {
X      if (options->oracle == NULL)
X         error(prog_name, "tried to use oracle before one loaded", TRUE);
X
X      cache_oracle_classifications(train_examples, attr_info, options);
X
X      if (options->do_sampling)
X         determine_min_estimation_sample(train_examples, options);
X   }
X
X   splits = make_candidate_splits(attr_info, options);
X
X   constraints = (Constraint **) 
X		 check_malloc(sizeof(Constraint *) * attr_info->number);
X   for (i = 0; i < attr_info->number; ++i)
X      constraints[i] = NULL;
X
X   if (options->expansion_method == BEST_FIRST)
X   {
X      tree = best_first(train_examples, train_mask, splits, attr_info,
X			constraints, options, options->tree_size_limit,
X			test_examples, validation_examples, pfname);
X   }
X   else
X   {
X      tree = make_subtree(train_examples, train_mask, splits, attr_info, NULL,
X		          constraints, options, 0);
X   }
X
X   printf("\nBEFORE SIMPLIFICATION:\n");
X   report_tree_statistics(tree, attr_info);
X   unnecessary_node_prune(tree);
X
X   printf("AFTER SIMPLIFICATION:\n");
X   report_tree_statistics(tree, attr_info);
X
X   check_free((void *) constraints);
X   free_unused_splits(splits);
X
X   return(tree);
X}
X
X
Xvoid print_tree(node, attr_info, level)
X   TreeNode *node;
X   AttributeInfo *attr_info;
X   int level;
X{
X   int index;
X   Attribute *attr;
X   int i, j;
X   Split *split;
X   char *temp_label;
X
X   if (!node)
X   {
X      printf("NULL\n");
X   }
X   else if (node->type == LEAF)
X   {
X      index = node->class;
X      attr = &attr_info->attributes[attr_info->class_index];
X      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
X         temp_label = attr->labels[index];
X      else
X         temp_label = index ? "true" : "false";
X      printf("%s ", temp_label);
X
X/*
X      if (Get_Example_Error(node) == 0.0)
X	 printf("(%.1f)", node->e_total);
X      else
X	 printf("(%.1f/%.1f)", node->e_total, Get_Example_Error(node));
X
X      printf("  (%.1f/%.1f)", node->type_specific.leaf.total,
X	     node->type_specific.leaf.error);
X*/
X
X
X/*
X      switch(node->type_specific.leaf.stop_reason)
X      {
X	 case S_GLOBAL:
X	    printf("  GLOBAL\n");
X	    break;
X	 case S_DEPTH:
X	    printf("  DEPTH\n");
X	    break;
X	 case S_NO_SPLITS:
X	    printf("  NO_SPLITS\n");
X	    break;
X	 case S_NO_PICK_SPLIT:
X	    printf("  NO_PICK_SPLIT\n");
X	    break;
X	 case S_MIN_OBJECTS:
X	    printf("  MIN_OBJECTS\n");
X	    break;
X	 case S_ERROR:
X	    printf("  ERROR\n");
X	    break;
X	 case S_SAMPLING:
X	    printf("  SAMPLING\n");
X	    break;
X	 case S_SIMPLIFIED:
X	    printf("  SIMPLIFIED\n");
X	    break;
X	 case S_PRUNED:
X	    printf("  PRUNED\n");
X	    break;
X	 case S_ZERO_BRANCH_PROB:
X	    printf("  BRANCH-PROB=0\n");
X	    break;
X	 default:
X	    error("system error", "bad stop_reason in print_tree", TRUE);
X      }
X*/
X
X
X      printf("  [");
X      for (i = 0; i < attr_info->num_classes; ++i)
X      {
X         if (i > 0)
X            printf(", ");
X         printf("%.1f", node->e_distribution[i]);
X      }
X      printf("]  [");
X      for (i = 0; i < attr_info->num_classes; ++i)
X      {
X         if (i > 0)
X            printf(", ");
X         printf("%d", (int) node->s_distribution[i]);
X      }
X      printf("]\n");
X
X   }
X   else
X   {
X      printf("\n");
X      split = Get_Split(node);
X      for (i = 0; i < split->arity; ++i)
X      {
X         for (j = 0; j < level; ++j)
X            printf("|   ");
X
X         print_split(split, attr_info, i, stdout);
X	 printf(": ");
X
X/*
X	 if (i== 0 && node->distributions != NULL)
X	    printf("(D) ");
X*/
X
X	 print_tree(node->type_specific.internal.children[i],
X		    attr_info, level + 1);
X      }
X   }
X}
X
X
Xstatic void draw_node(node, attr_info, stream)
X   TreeNode *node;
X   AttributeInfo *attr_info;
X   FILE *stream;
X{
X   int index;
X   Attribute *attr;
X   int i;
X   TreeNode *child;
X   Split *split;
X   char *class_label;
X   char *font_color = "black";
X
X   if (node->type == LEAF)
X   {
X      index = node->class;
X      attr = &attr_info->attributes[attr_info->class_index];
X      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
X         class_label = attr->labels[index];
X      else
X         class_label = index ? "true" : "false";
X
X      if (attr_info->num_classes == 2)
X         font_color = index ? "green" : "red";
X
X      fprintf(stream, "\tn%d [color=blue,fontcolor=%s,label=\"%s\"];\n",
X	      (int) node, font_color, class_label);
X   }
X   else
X   {
X      split = Get_Split(node);
X      fprintf(stream, "\tn%d [color=blue,label=\"", (int) node);
X      print_split(split, attr_info, 0, stream);
X      fprintf(stream, "\",shape=box];\n");
X
X      for (i = 0; i < split->arity; ++i)
X      {
X	 child = node->type_specific.internal.children[i];
X         fprintf(stream, "\tn%d -> n%d;\n", (int) node, (int) child);
X         draw_node(child, attr_info, stream);
X      }
X   }
X}
X
X
Xvoid draw_tree(node, attr_info, fname)
X   TreeNode *node;
X   AttributeInfo *attr_info;
X   char *fname;
X{
X   FILE *stream;
X
X   stream = check_fopen(fname, "w");
X   fprintf(stream, "digraph tree\n{\n");
X
X   draw_node(node, attr_info, stream);
X
X   fprintf(stream, "}\n");
X   fclose(stream);
X}
X
X
Xstatic int count_values(split)
X   Split *split;
X{
X   Member *member;
X   int count = 0;
X
X   switch (split->type)
X   {
X      case NOMINAL_SPLIT:
X      case BOOLEAN_SPLIT:
X      case REAL_SPLIT:
X	 return(1);
X      case M_OF_N_SPLIT:
X      {
X	 member = Get_Members(split);
X	 while (member)
X	 {
X	    ++count;
X	    member = member->next;
X	 }
X	 return(count);
X      }
X      default:
X	 error("System error", "bad split type in count_values", TRUE);
X   }
X}
X
X
Xstatic void tree_stats(node, stats, value_count)
X   TreeNode *node;
X   TreeStats *stats;
X   int value_count;
X{
X   int i;
X   int count;
X
X   if (node->type == LEAF)
X   {
X      ++stats->leaves;
X
X      ++stats->rules[node->class];
X      stats->antes[node->class] += value_count;
X   }
X   else
X   {
X      ++stats->internal;
X      count = count_values(Get_Split(node));
X      stats->values += count;
X      value_count += count;
X      for (i = 0; i < node->type_specific.internal.split->arity; ++i)
X	 tree_stats(Get_Nth_Child(node, i), stats, value_count);
X   }
X}
X
X
Xstatic void fraction_covered(node, fraction, correctness, size)
X   TreeNode *node;
X   float *fraction;
X   float *correctness;
X   double size;
X{
X   Split *split;
X   int i;   
X   double multiplier;
X
X   if (node->type == LEAF)
X   {
X      if (node->type_specific.leaf.covered)
X         *fraction += size; 
X      *correctness += size * (1.0 - node->e_total);
X   }
X   else
X   {
X      split = Get_Split(node);
X      multiplier = 1.0 / split->arity;
X      for (i = 0; i < split->arity; ++i)
X         fraction_covered(node->type_specific.internal.children[i],
X			      fraction, correctness, multiplier * size);
X   }
X}
X
X
Xstatic void determine_non_linearity(node, NL, size)
X   TreeNode *node;
X   float *NL;
X   int *size;
X{
X   int arity;
X   float left_NL, right_NL;
X   int left_size, right_size;
X
X   if (node->type == LEAF)
X   {
X      *size = 0;
X      *NL = 0.0;
X   }
X   else
X   {
X      arity = node->type_specific.internal.split->arity;
X      if (arity != 2)
X      {
X	 error(prog_name,
X	       "tree non-linearity only computed for binary trees currently",
X	       TRUE);
X      }
X
X      determine_non_linearity(Get_Nth_Child(node, 0), &left_NL, &left_size);
X      determine_non_linearity(Get_Nth_Child(node, 1), &right_NL, &right_size);
X      if (left_size > right_size)
X	 *NL = 0.5 * (right_NL + right_size + left_NL);
X      else
X	 *NL = 0.5 * (left_NL + left_size + right_NL);
X      *size = 1 + left_size + right_size;
X   }
X}
X
X
Xvoid report_tree_statistics(node, attr_info)
X   TreeNode *node;
X   AttributeInfo *attr_info;
X{
X   TreeStats stats;
X   float NL = 0.0;
X   int size;
X   int i;
X   float covered = 0.0;
X   float correctness = 0.0;
X
X   stats.leaves = 0;
X   stats.internal = 0;
X   stats.values = 0;
X   stats.rules = check_malloc(sizeof(int) * attr_info->num_classes);
X   stats.antes = check_malloc(sizeof(int) * attr_info->num_classes);
X   for (i = 0; i < attr_info->num_classes; ++i)
X   {
X      stats.rules[i] = 0;
X      stats.antes[i] = 0;
X   }
X
X   tree_stats(node, &stats, 0);
X
X/*
X   determine_non_linearity(node, &NL, &size);
X
X   if (size != stats.internal)
X   {
X      error("system error", "inconsistent tree size in report_tree_statistics",
X	    TRUE);
X   }
X*/
X
X   printf("\tTree has %d internal nodes, %d leaves, and %d values\n",
X	  stats.internal, stats.leaves, stats.values);
X/*
X   printf("\tNon-linearity measure = %.2f\n", NL);
X   fraction_covered(node, &covered, &correctness, 1.0);
X   printf("Fraction of instance space adequately covered = %.2f\n", covered);
X   printf("Estimated correctness of tree = %.3f\n", correctness);
X
X   printf("   class       rules   antecedents\n");
X   for (i = 0; i < attr_info->num_classes; ++i)
X      printf("   %-10s  %6d  %6d\n",
X	     attr_info->attributes[attr_info->class_index].labels[i],
X	     stats.rules[i], stats.antes[i]);
X
X*/
X
X   check_free((void *) stats.rules);
X   check_free((void *) stats.antes);
X}
X
X
Xvoid echo_key_parameters(msg, options)
X   char *msg;
X   Options *options;
X{
X   char *method;
X
X   printf("%s:\n", msg);
X
X   switch (options->expansion_method)
X   {
X      case DEPTH_FIRST:  method = "depth first"; break;
X      case BEST_FIRST:  method = "best first"; break;
X      default:  method = "unknown"; break;
X   }
X   printf("\t%-40s: %s\n", "expansion method", method); 
X   if (options->expansion_method == DEPTH_FIRST)
X   {
X      printf("\t%-40s: %d\n", "stop depth", options->stop_depth); 
X   }
X   else if (options->expansion_method == BEST_FIRST)
X   {
X      printf("\t%-40s: %d\n", "tree size limit", options->tree_size_limit);
X      printf("\t%-40s: %f\n", "patience threshold",
X	     options->patience_threshold);
X      printf("\t%-40s: %d\n", "patience counter",
X	     options->patience_counter);
X   }
X
X   switch (options->split_search_method)
X   {
X      case GREEDY:  method = "greedy"; break;
X      case BEAM:  method = "beam"; break;
X      case LOOKAHEAD:  method = "lookahead"; break;
X      default:  method = "unknown"; break;
X   }
X   printf("\t%-40s: %s\n", "split search method", method); 
X   if (options->split_search_method == BEAM)
X   {
X      printf("\t%-40s: %d\n", "beam width", options->beam_width); 
X      printf("\t%-40s: %f\n", "mofn significance level", options->mofn_level); 
X   }
X
X   switch (options->split_method)
X   {
X      case GAIN:  method = "gain"; break;
X      case GAIN_RATIO:  method = "gain ratio"; break;
X      case ORT:  method = "ORT"; break;
X      default:  method = "unknown"; break;
X   }
X   printf("\t%-40s: %s\n", "split evaluation method", method); 
X
X   if (options->use_oracle)
X   {
X      printf("\t%-40s: %s\n", "use oracle", "yes"); 
X   }
X   else
X   {
X      printf("\t%-40s: %s\n", "use oracle", "no"); 
X   }
X
X   if (options->do_sampling)
X   {
X      printf("\t%-40s: %s\n", "use sampling", "yes"); 
X      printf("\t%-40s: %d\n", "minimum sample", options->min_sample);
X      switch (options->estimation_method)
X      {
X         case KERNEL: method = "kernel"; break;
X         case GAUSSIAN: method = "gaussian"; break;
X         case UNIFORM: method = "uniform"; break;
X         default:  method = "unknown"; break;
X      }
X      printf("\t%-40s: %s\n", "density estimation method", method); 
X
X      switch (options->distribution_type)
X      {
X         case LOCAL: method = "local"; break;
X         case GLOBAL: method = "global"; break;
X         default:  method = "unknown"; break;
X      }
X      printf("\t%-40s: %s\n", "estimated distributions", method); 
X
X      if (options->distribution_type == LOCAL)
X      {
X         printf("\t%-40s: %f\n", "minimum estimation fraction",
X		options->min_estimation_fraction);
X         printf("\t%-40s: %f\n", "local distribution significance level",
X		options->distribution_alpha);
X      }
X   }
X   else
X   {
X      printf("\t%-40s: %s\n", "sampling used", "no"); 
X   }
X
X   printf("\t%-40s: %f\n", "minimum objects", options->min_objects);
X   printf("\n");
X}
X
END-of-tree.c
echo x - tree.h
sed 's/^X//' >tree.h << 'END-of-tree.h'
X#define MIXED_CLASS	-1
X#define NO_CLASS	-2
X#define MISSING		-3
X
X#define UNDETERMINED	3
X
X
X#define Log2(x) (log(x) / 0.69314718055994530942)
X
X
Xtypedef enum split_type {NOMINAL_SPLIT, M_OF_N_SPLIT, 
X			 REAL_SPLIT, BOOLEAN_SPLIT} SplitType;
X
X
Xtypedef struct member
X{
X   int attribute;
X   float posterior;
X   ValueType value;
X   AttributeType type;
X   char negated;		/* used only for real-valued splits */
X   struct member *next;
X} Member;
X
X
Xtypedef struct split
X{
X   SplitType type;
X   int arity;
X   int reference_count;
X   char can_use;
X   union
X   {
X      struct			/* split on nominal or boolean attribute */
X      {
X	 int attribute;
X      } nominal;
X      struct			/* M-of-N split */
X      {
X	 int m;
X	 Member *members;
X	 char expanded;
X	 unsigned int sample_key;
X	 float chi_square_prob;
X      } mofn;
X      struct			/* split on real attribute */
X      {
X	 int attribute;
X	 float threshold;
X      } real;
X      struct			/* boolean split on nominal attribute */
X      {
X	 int attribute;
X	 int value;
X	 char bool_attr;
X      } boolean;
X   } type_specific;
X   float total;
X   float missing;
X   float *branch_distr;
X   float **class_distr;		/* arity X classes */
X   float gain;
X   struct split *next;
X   struct split *prev;
X} Split;
X
X
X#define Get_Nominal_Attr(a) ((a)->type_specific.nominal.attribute)
X#define Get_M(a) ((a)->type_specific.mofn.m)
X#define Get_N(a) ((a)->type_specific.mofn.n)
X#define Get_Members(a) ((a)->type_specific.mofn.members)
X#define Get_Real_Attr(a) ((a)->type_specific.real.attribute)
X#define Get_Threshold(a) ((a)->type_specific.real.threshold)
X#define Get_Boolean_Attr(a) ((a)->type_specific.boolean.attribute)
X#define Get_Boolean_Value(a) ((a)->type_specific.boolean.value)
X#define Is_Boolean_Attr(a) ((a)->type_specific.boolean.bool_attr)
X
X
Xtypedef enum node_type {INTERNAL, LEAF} NodeType;
Xtypedef enum stop_reason {S_GLOBAL, S_DEPTH, S_NO_SPLITS, S_NO_PICK_SPLIT,
X			  S_MIN_OBJECTS, S_ERROR, S_SAMPLING,
X			  S_SIMPLIFIED, S_PRUNED, S_ZERO_BRANCH_PROB} StopReason;
X
X
Xtypedef struct tree_node
X{
X   NodeType type;
X   int number;
X   union
X   {
X      struct
X      {
X         Split *split;
X         struct tree_node **children;
X	 float *probs;
X      } internal;
X      struct
X      {
X	 char covered;		/* does this leaf meet covering criteria */
X	 StopReason stop_reason;
X	 float total;		/* classification statistic */
X	 float error;		/* classification statistic */
X      } leaf;
X   } type_specific;
X   Distribution **distributions;
X   struct tree_node *parent;
X   int parent_branch;
X   int class;
X   float error;			/* error as calculated in C4.5 */
X   float *s_distribution;
X   float s_total;		/* total # of samples at node */
X   float *e_distribution;
X   float e_total;		/* total # of examples/samples at node */
X} TreeNode;
X
X
X#define Get_Split(a) ((a)->type_specific.internal.split)
X#define Get_Children(a) ((a)->type_specific.internal.children)
X#define Get_Nth_Child(a, n) ((a)->type_specific.internal.children[(n)])
X#define Get_Probs(a) ((a)->type_specific.internal.probs)
X#define Get_Nth_Prob(a, n) ((a)->type_specific.internal.probs[(n)])
X
X#define Get_Class_Total(a, i) ((a)->e_distribution[(i)] + \
X			       (a)->s_distribution[(i)])
X#define Get_Predicted_Class_Total(a) ((a)->e_distribution[(a)->class] + \
X			              (a)->s_distribution[(a)->class])
X#define Get_Total(a) ((a)->e_total + (a)->s_total)
X#define Get_Example_Error(a) ((a)->e_total - (a)->e_distribution[(a)->class])
X#define Get_Total_Error(a) ((a)->e_total + (a)->s_total - \
X			    (a)->e_distribution[(a)->class] - \
X			    (a)->s_distribution[(a)->class])
X#define Get_Example_Proportion(a) ((a)->e_distribution[(a)->class] \
X				   / (a)->e_total)
X#define Get_Sample_Proportion(a) ((a)->s_distribution[(a)->class] \
X				  / (a)->s_total)
X#define Get_Proportion(a) (Get_Predicted_Class_Total((a)) / Get_Total((a)))
X
X
Xtypedef struct constraint
X{
X   Split *split;
X   Member *member;
X   int branch;
X   struct constraint *next;
X} Constraint;
X
X
Xtypedef struct
X{
X   int internal;
X   int leaves;
X   int values;
X   int *rules;
X   int *antes;
X} TreeStats;
X
X
Xtypedef enum expansion__method {DEPTH_FIRST, BEST_FIRST} ExpansionMethod;
Xtypedef enum split_search_method {GREEDY, BEAM, LOOKAHEAD} SplitSearchMethod;
Xtypedef enum estimation_method {KERNEL, GAUSSIAN, UNIFORM} EstimationMethod;
Xtypedef enum split_eval_method {GAIN, GAIN_RATIO, ORT} SplitEvalMethod;
Xtypedef enum distribution_type {LOCAL, GLOBAL} DistributionType;
X
X
Xtypedef struct
X{
X   /* key control parameters */
X   ExpansionMethod expansion_method;
X   SplitSearchMethod split_search_method;
X   int use_oracle;
X   int do_sampling;
X
X   /* other control parameters */
X   SplitEvalMethod split_method;
X
X   /* stopping parameters */
X   int stop_depth;
X   int tree_size_limit;
X   float min_objects;
X   float patience_threshold;
X   int patience_counter;
X
X   /* sampling parameters */
X   int min_sample;
X   int (*oracle)();
X   DistributionType distribution_type;
X   float min_estimation_fraction;
X   float distribution_alpha;
X   int min_estimation_sample;
X   EstimationMethod estimation_method;
X   double (*kernel_width_fn)();
X   int print_distributions;
X   float stop_z;
X   float stop_epsilon;
X   int sampling_stop;
X   int validation_stop;
X
X   /* m-of-n search parameters */
X   int num_mofn_ops;
X   void (**mofn_ops)();
X   float mofn_level;
X   int beam_width;
X
X} Options;
X
X
Xtypedef struct priority_queue
X{
X   TreeNode *node;
X   float priority;
X   float *mask;
X   struct priority_queue *next;
X} PriorityQueue;
X
X
Xextern TreeNode		*tree_root;
X
X
Xextern Split		*add_split();
Xextern void		cache_oracle_classifications();
Xextern float		calculate_sum_squared_error();
Xextern void		classify_example();
Xextern void		draw_tree();
Xextern void		example_distribution();
Xextern void		classify_using_tree();
Xextern Split		*copy_split();
Xextern void		echo_key_parameters();
Xextern void		evaluate_splits();
Xextern void		free_split();
Xextern void		free_tree();
Xextern void		free_unused_splits();
Xextern ValueType	get_class();
Xextern Distribution	**get_local_distributions();
Xextern Split		*get_new_split();
Xextern int		get_predicted_class();
Xextern TreeNode		*induce_tree();
Xextern float		**make_masks();
Xextern void		match_any();
Xextern float		measure_fidelity();
Xextern Split		*pick_split();
Xextern void		print_constraint();
Xextern void		print_constraints();
Xextern void		print_split();
Xextern void		print_tree();
Xextern void		report_tree_statistics();
Xextern void		reset_statistics();
Xextern int		trivial_split();
Xextern int		trivial_split_when_sampling();
Xextern void		set_constraint();
Xextern void		update_statistics();
Xextern void		unset_constraint();
Xextern int		which_branch();
END-of-tree.h
echo x - user-command-exp.h
sed 's/^X//' >user-command-exp.h << 'END-of-user-command-exp.h'
X 
X/* exported functions */
Xextern void	install_user_commands();
Xextern void	install_user_variables();
END-of-user-command-exp.h
echo x - user-command.c
sed 's/^X//' >user-command.c << 'END-of-user-command.c'
X#include <stdio.h>
X#include <stdlib.h>
X#include <string.h>
X#include <math.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "tree.h"
X#include "command-int.h"
X#include "network-exp.h"
X#include "mofn-exp.h"
X#include "sample-exp.h"
X
X
X
Xvoid install_user_commands()
X{
X}
X
X
Xvoid install_user_variables()
X{
X}
X
END-of-user-command.c
echo x - user-examples-exp.h
sed 's/^X//' >user-examples-exp.h << 'END-of-user-examples-exp.h'
X
Xextern void		read_attributes();
Xextern void		read_attribute_mappings();
Xextern void		read_examples();
X
END-of-user-examples-exp.h
echo x - user-examples-int.h
sed 's/^X//' >user-examples-int.h << 'END-of-user-examples-int.h'
X#define BAD_VALUE		-1
X#define DEFAULT_MIN		0.0
X#define DEFAULT_MAX		1.0
X
END-of-user-examples-int.h
echo x - user-examples.c
sed 's/^X//' >user-examples.c << 'END-of-user-examples.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include <string.h>
X#include "utils-exp.h"
X#include "examples-exp.h"
X#include "user-examples-int.h"
X
X
Xextern char *strdup();
X
X
X
Xstatic AttributeType match_attribute_type(type)
X   char type;
X{
X   switch (type)
X   {
X      case 'n':
X      case 'N': return(NOMINAL_ATTR);
X      case 'r':
X      case 'R': return(REAL_ATTR);
X      case 'b':
X      case 'B': return(BOOLEAN_ATTR);
X      case 'v':
X      case 'V': return(VECTOR_ATTR);
X      default:
X         sprintf(err_buffer, "`%c` is not a valid attribute type", type);
X         error(prog_name, err_buffer, TRUE);
X   }
X}
X
X
Xstatic int lookup_attribute(name, attr_info, search_limit)
X   char *name;
X   AttributeInfo *attr_info;
X   int search_limit;
X{
X   int i;
X
X   for (i = 0; i < search_limit; ++i)
X   {
X      if (!strcasecmp(name, attr_info->attributes[i].name))
X         break;
X   }
X
X   if (i == search_limit)
X      return(NULL_ATTR);
X   else
X      return(i);
X}
X
X
Xvoid read_attributes(fname, attr_info)
X   char *fname;
X   AttributeInfo *attr_info;
X{
X   FILE *in_file;
X   char buffer[BUFSIZ];
X   char *token[100];
X   char type;
X   Attribute *attribute;
X   int i, j;
X
X   in_file = check_fopen(fname, "r");
X
X   attr_info->number = 0;
X   while (fgets(buffer, BUFSIZ, in_file))
X      ++attr_info->number;
X   rewind(in_file);
X
X   if (attr_info->number < 2)
X      error(prog_name, "attribute file must specify at least 2 attributes", 
X	    TRUE);
X
X   attr_info->attributes = (Attribute *) 
X			 check_malloc(sizeof(Attribute) * attr_info->number);
X   attr_info->class_index = attr_info->number - 1;
X
X   for (i = 0; i < attr_info->number; ++i)
X   {
X      attribute = &attr_info->attributes[i];
X      attribute->dependency = NULL_ATTR;
X
X      if (fscanf(in_file, "%s %c", buffer, &type) != 2)
X      {
X         sprintf(err_buffer, "file %s is not in correct format", fname);
X         error(prog_name, err_buffer, TRUE);
X      }
X
X      if (lookup_attribute(buffer, attr_info, i) != NULL_ATTR)
X      {
X         sprintf(err_buffer, "attribute name %s used more than once", buffer);
X         error(prog_name, err_buffer, TRUE);
X      }
X      
X      attribute->name = strdup(buffer);
X      attribute->type = match_attribute_type(type);
X      attribute->map = NULL;
X      attribute->range = NULL;
X      attribute->relevant = TRUE;
X
X      if (attribute->type == VECTOR_ATTR && i != attr_info->class_index)
X      {
X         error(prog_name,
X	       "only the class attribute can have type = vector", TRUE);
X      }
X
X      if (attribute->type == NOMINAL_ATTR || attribute->type == VECTOR_ATTR)
X      {
X         fgets(buffer, BUFSIZ, in_file);
X         attribute->num_values = 0;
X
X         if (token[0] = strtok(buffer, " \t\n"))
X         {
X            ++attribute->num_values;
X            while (token[attribute->num_values] = strtok((char *) NULL," \t\n"))
X               ++attribute->num_values;
X         }
X
X         if (attribute->num_values < 2)
X         {
X            sprintf(err_buffer, 
X		  "bad attribute %s (nominal attributes must have >= 2 values)",
X                  attribute->name);
X            error(prog_name, err_buffer, TRUE);
X         }
X         else if (attribute->num_values > MAX_ATTR_VALUES)
X         {
X            sprintf(err_buffer, 
X	       "attribute has too many values; the current limit is %d values",
X	       MAX_ATTR_VALUES);
X            error(prog_name, err_buffer, TRUE);
X	 }
X
X	 attribute->distribution = NULL; 
X         attribute->labels = (char **)
X                           check_malloc(sizeof(char *) * attribute->num_values);
X         for (j = 0; j < attribute->num_values; ++j)
X            attribute->labels[j] = strdup(token[j]);
X      }
X      else if (attribute->type == BOOLEAN_ATTR)
X      {
X	 attribute->num_values = 2;
X	 attribute->distribution = NULL; 
X      }
X      else if (attribute->type == REAL_ATTR)
X      {
X         attribute->num_values = 1;
X	 attribute->distribution = NULL; 
X	 attribute->range = (Range *) check_malloc(sizeof(Range));
X	 attribute->range->min = DEFAULT_MIN;
X	 attribute->range->max = DEFAULT_MAX;
X      }
X   }
X
X   attribute = &attr_info->attributes[attr_info->class_index];
X   if (attribute->type == NOMINAL_ATTR || attribute->type == VECTOR_ATTR)
X      attr_info->num_classes = attribute->num_values;
X   else if (attribute->type == BOOLEAN_ATTR)
X      attr_info->num_classes = 2; 
X   else
X      error(prog_name,
X	    "the class attribute must be boolean, nominal or vector", TRUE);
X
X   fclose(in_file);
X}
X
X
Xstatic int match_boolean_value(label)
X   char *label;
X{
X   if (!strcasecmp(label, "true") || !strcasecmp(label, "t"))
X      return(1);
X   else if (atoi(label) == 1)
X      return(1);
X   else if (!strcasecmp(label, "false") || !strcasecmp(label, "f"))
X      return(0);
X   else if (atoi(label) == 0)
X      return(0);
X
X   return(BAD_VALUE);
X}
X
X
Xstatic int match_nominal_value(label, attribute)
X   char *label;
X   Attribute *attribute;
X{
X   int i;
X
X   for (i = 0; i < attribute->num_values; ++i)
X   {
X      if (!strcasecmp(label, attribute->labels[i]))
X         return(i);
X   }
X
X   return(BAD_VALUE);
X}
X
X
Xvoid read_examples(fnames, num_files, attr_info, ex_info)
X   char **fnames;
X   int num_files;
X   AttributeInfo *attr_info;
X   ExampleInfo *ex_info;
X{
X   FILE *in_file;
X   char buffer[BUFSIZ];
X   Example *example;
X   Attribute *attribute;
X   int *last_in_file;
X   int file_index;
X   int i, j, k;
X   int value;
X
X   last_in_file = (int *) check_malloc(sizeof(int) * num_files);
X
X   ex_info->number = 0;
X   ex_info->test_fold = NONE;
X   for (file_index = 0; file_index < num_files; ++file_index)
X   {
X      in_file = check_fopen(fnames[file_index], "r");
X      while (fgets(buffer, BUFSIZ, in_file))
X         ++ex_info->number;
X      last_in_file[file_index] = ex_info->number;
X      fclose(in_file);
X   }
X   ex_info->size = ex_info->number;
X
X   for (file_index = 0; file_index < num_files; ++file_index)
X      if ((file_index == 0 && last_in_file[0] == 0) || (file_index != 0 &&
X	  last_in_file[file_index] == last_in_file[file_index - 1]))
X      {
X         sprintf(err_buffer, "examples file %s is empty", fnames[file_index]);
X         error(prog_name, err_buffer, TRUE);
X      }
X
X   ex_info->examples = (Example *) check_malloc(sizeof(Example) * ex_info->size);
X       
X   file_index = 0;
X   in_file = check_fopen(fnames[file_index], "r");
X   for (i = 0; i < ex_info->number; ++i)
X   {
X      if (i == last_in_file[file_index])
X      {
X	 ++file_index;
X	 fclose(in_file);
X	 in_file = check_fopen(fnames[file_index], "r");
X      }
X
X      example = &ex_info->examples[i];
X      example->values = (Value *)
X                         check_malloc(sizeof(Value) * attr_info->number);
X
X      if (fscanf(in_file,"%s", buffer) == EOF)
X         error(prog_name, "examples file not in correct format", TRUE);
X      example->name = strdup(buffer);
X      example->fold = 0;
X      example->oracle.missing = TRUE;
X
X      for (j = 0; j < attr_info->number; ++j)
X      {
X	 attribute = &attr_info->attributes[j];
X
X         if (fscanf(in_file,"%s", buffer) == EOF)
X            error(prog_name, "examples file not in correct format", TRUE);
X
X	 if (!strcmp(buffer, "?"))
X	 {
X	    if (j == attr_info->class_index)
X	    {
X	       error(prog_name,
X		     "class attribute cannot have missing values", TRUE);
X	    }
X	    example->values[j].missing = TRUE;
X	 }
X	 else
X	 {
X	    example->values[j].missing = FALSE;
X
X            if (attribute->type == REAL_ATTR)
X            {
X               if (sscanf(buffer, "%f", &example->values[j].value.real) != 1)
X                  error(prog_name, "examples file not in correct format", TRUE);
X            }
X            else if (attribute->type == BOOLEAN_ATTR)
X	    {
X               if ((value = match_boolean_value(buffer)) == BAD_VALUE)
X               {
X                  sprintf(err_buffer,
X                          "bad examples file -- %s not a valid value for %s", 
X			  buffer, attribute->name);
X                  error(prog_name, err_buffer, TRUE);
X               }
X               example->values[j].value.discrete = value;
X	    }
X            else if (attribute->type == NOMINAL_ATTR)
X            {
X               if ((value = match_nominal_value(buffer,attribute)) == BAD_VALUE)
X               {
X                  sprintf(err_buffer,
X                          "bad examples file -- %s not a valid value for %s", 
X			  buffer, attribute->name);
X                  error(prog_name, err_buffer, TRUE);
X               }
X               example->values[j].value.discrete = value;
X            }
X            else if (attribute->type == VECTOR_ATTR)
X            {
X	       example->values[j].value.vector = 
X		  check_malloc(sizeof(float) * attr_info->num_classes);
X
X	       example->values[j].value.vector[0] = (float) atof(buffer);
X	       for (k = 1; k < attr_info->num_classes; ++k)
X	       {
X                  if (fscanf(in_file,"%s", buffer) == EOF)
X                     error(prog_name, "examples file not in correct format",
X			   TRUE);
X	          example->values[j].value.vector[k] = (float) atof(buffer);
X	       }
X	    }
X	 }
X      }
X   }
X
X   check_free((void *) last_in_file);
X
X   fclose(in_file);
X}
X
X
Xvoid read_attribute_mappings(fname, attr_info)
X   char *fname;
X   AttributeInfo *attr_info;
X{
X   FILE *in_file;
X   char buffer[BUFSIZ];
X   Attribute *attr;
X   Map *map;
X   int index; 
X   int i, j;
X
X   in_file = check_fopen(fname, "r");
X
X   for (i = 0; i < attr_info->number; ++i)
X      check_free((void *) attr_info->attributes[i].map);
X
X   while (fscanf(in_file, "%s", buffer) == 1)
X   {
X      if ((index = lookup_attribute(buffer, attr_info,
X				    attr_info->number)) == NULL_ATTR)
X      {
X         sprintf(err_buffer, "unable to set map; unknown attribute %s", buffer);
X         error(prog_name, err_buffer, TRUE);
X      }
X
X      attr = &attr_info->attributes[index];
X
X      if (attr->type == NOMINAL_ATTR)
X      {
X         map = (Map *) check_malloc(sizeof(Map));
X         if (fscanf(in_file, "%d", &map->size) != 1)
X         {
X	    sprintf(err_buffer, "unable to read map size for %s", buffer);
X            error(prog_name, err_buffer, TRUE);
X         }
X
X         if (map->size <= 0)
X         {
X	    sprintf(err_buffer, "map size for %s must be greater than 0",
X		    buffer);
X            error(prog_name, err_buffer, TRUE);
X         }
X
X         map->vectors = (float **) check_malloc(sizeof(float*) *
X						attr->num_values);
X         for (i = 0; i < attr->num_values; ++i)
X         {
X	    map->vectors[i] = (float *) check_malloc(sizeof(float) * map->size);
X	    for (j = 0; j < map->size; ++j)
X	       if (fscanf(in_file, "%f", &map->vectors[i][j]) != 1)
X	       {
X	          sprintf(err_buffer, "failed to read map for value %s of %s", 
X		          attr->labels[i], buffer);
X                  error(prog_name, err_buffer, TRUE);
X	       }
X         }
X      }
X      else if (attr->type == REAL_ATTR)
X      {
X         map = (Map *) check_malloc(sizeof(Map));
X	 fgets(buffer, BUFSIZ, in_file);
X      }
X      else
X      {
X         sprintf(err_buffer,
X		"tried to set map for non real/nominal attribute (%s)", buffer);
X         error(prog_name, err_buffer, TRUE);
X      }
X
X      attr->map = map;
X   }
X
X   fclose(in_file);
X}
X
X
END-of-user-examples.c
echo x - utils-exp.h
sed 's/^X//' >utils-exp.h << 'END-of-utils-exp.h'
X#define	TRUE		1
X#define FALSE		0
X#define DEFAULT_SEED	100
X#define EPSILON		0.001
X
X/* return a random number in [0.1] */
X#define Rnd() ((float)random()*0.4656612875e-9)
X
X#define Min(a, b) (((a) > (b)) ? (b) : (a))
X#define Max(a, b) (((a) < (b)) ? (b) : (a))
X
Xextern int			strncasecmp();
X#define Startsame(s1,s2)        (!strncasecmp(s1,s2,strlen(s1)))
X
X
Xtypedef struct
X{
X   float value;
X   int index;
X} Order;
X
X
Xextern char	err_buffer[];
Xextern char	*prog_name;
X
X
Xextern void	bzero();
Xextern FILE	*check_fopen();
Xextern void	check_free();
Xextern void	*check_malloc();
Xextern void	check_system();
Xextern void	error();
Xextern int	float_compare();
Xextern void	free_confusion_matrix();
Xextern int	**get_confusion_matrix();
Xextern double	my_random();
Xextern void	my_srandom();
Xextern int	order_compare();
Xextern void	print_measure();
Xextern void	print_confusion_matrix();
Xextern void	reset_confusion_matrix();
X
END-of-utils-exp.h
echo x - utils.c
sed 's/^X//' >utils.c << 'END-of-utils.c'
X#include <stdlib.h>
X#include <stdio.h>
X#include "utils-exp.h"
X
X
Xchar	err_buffer[BUFSIZ];
Xchar	*prog_name = "";
X
X
X/*  
X   Handle an error.
X*/
Xvoid error(bullet, msg, do_exit)
X   char *bullet;
X   char *msg;
X   int do_exit;
X{
X   fprintf(stderr, "%s: %s\n", bullet, msg);
X   if (do_exit)
X      exit(1);
X}
X
X
X/*  
X   Do a malloc and check to see if it was successful.
X*/
Xvoid *check_malloc(size)
X   unsigned int size;
X{
X   void *p;
X
X   p = (void *) malloc(size);
X   if (p)
X      return(p);
X   else
X      error(prog_name, "malloc failed", TRUE);
X}
X
X
X/*
X   Do a free.  First check to make sure that the pointer is non-NULL.
X*/
Xvoid check_free(p)
X   void *p;
X{
X   if (p)
X      free((char *) p);
X}
X
X
X/*  Given string containing a UNIX command, call a shell to execute this
X    command.  Return TRUE if the command executes successfully.
X*/
Xvoid check_system(command)
X   char *command;
X{
X   if (system(command) == 127)
X   {
X      sprintf(err_buffer, "unable to execute: %s", command);
X      error("system call failure", err_buffer, TRUE);
X   }
X}
X
X
XFILE *check_fopen(fname, type)
X   char *fname;
X   char *type;
X{
X   FILE *f;
X
X   if ((f = fopen(fname, type)) == NULL)
X   {
X      sprintf(err_buffer, "unable to open file %s", fname);
X      error(prog_name, err_buffer, TRUE);
X   }
X
X   return(f);
X}
X
X
Xint **get_confusion_matrix(dimension)
X   int dimension;
X{
X   int i, j;
X   int **matrix;
X
X   matrix = (int **) check_malloc(sizeof(int *) * dimension);
X   for (i = 0; i < dimension; ++i)
X   {
X      matrix[i] = (int *) check_malloc(sizeof(int) * dimension);
X      for (j = 0; j < dimension; ++j)
X	 matrix[i][j] = 0;
X   }
X
X   return(matrix);
X}
X
X
Xvoid reset_confusion_matrix(matrix, dimension)
X   int **matrix;
X   int dimension;
X{
X   int i, j;
X
X   for (i = 0; i < dimension; ++i)
X      for (j = 0; j < dimension; ++j)
X	 matrix[i][j] = 0;
X}
X
X
Xvoid free_confusion_matrix(matrix, dimension)
X   int **matrix;
X   int dimension;
X{
X   int i;
X
X   for (i = 0; i < dimension; ++i)
X      check_free((void *) matrix[i]);
X
X   check_free((void *) matrix);
X}
X
X
Xvoid print_measure(matrix, dimension, set, measure)
X   int **matrix;
X   int dimension;
X   char *set;
X   char *measure;
X{
X   int i, j;
X   int correct = 0;
X   int total = 0;
X
X   for (i = 0; i < dimension; ++i)
X      for (j = 0; j < dimension; ++j)
X      {
X         total += matrix[i][j];
X         if (i == j)
X            correct += matrix[i][j];
X      }
X
X   printf("%s Set %s: %d/%d = %.3f\n", set, measure, correct, total,
X          correct / (float) total);
X}
X
X
Xvoid print_confusion_matrix(matrix, dimension, col_label, row_label)
X   int **matrix;
X   int dimension;
X   char *col_label;
X   char *row_label;
X{
X   int i, j;
X   int *col_totals;
X   int row_total;
X   int total = 0;
X
X   col_totals = (int *) check_malloc(sizeof(int) * dimension);
X   for (i = 0; i < dimension; ++i)
X      col_totals[i] = 0;
X
X   printf("\n\t\t%s\n\t\t", col_label);
X   for (i = 0; i < dimension; ++i)
X      printf("%6d", i + 1);
X   printf("\n\t\t|");
X   for (i = 0; i < dimension; ++i)
X      printf("------");
X   printf("-|------\n");
X   for (i = 0; i < dimension; ++i)
X   {
X      row_total = 0;
X
X      if (!i)
X         printf("%-9s %2d\t|", row_label, i + 1);
X      else if (i < dimension)
X         printf("          %2d\t|", i + 1);
X      else
X        printf("           X \t|");
X      for (j = 0; j < dimension; ++j)
X      {
X         printf("%5d ", matrix[i][j]);
X         col_totals[j] += matrix[i][j];
X         row_total += matrix[i][j];
X         total += matrix[i][j];
X      }
X      printf(" | %5d\n", row_total);
X   }
X   printf("\t\t|");
X   for (i = 0; i < dimension; ++i)
X      printf("------");
X   printf("-|------\n");
X
X   printf("\t\t|");
X   for (i = 0; i < dimension; ++i)
X      printf("%5d ", col_totals[i]);
X   printf(" | %5d\n\n", total);
X
X   check_free((void *) col_totals);
X}
X
X
Xint float_compare(a, b)
X   float *a;
X   float *b;
X{
X   if (*a > *b)
X      return(1);
X   else if (*a == *b)
X      return(0);
X   else
X      return(-1);
X}
X
X
Xint order_compare(a, b)
X   Order *a;
X   Order *b;
X{
X   if (a->value > b->value)
X      return(1);
X   else if (a->value == b->value)
X      return(0);
X   else
X      return(-1);
X}
X
X
Xvoid my_srandom(seed)
Xlong int seed;
X{
X   srand48(seed);
X}
X
X
Xdouble my_random()
X{
X   extern double drand48();
X
X   return(drand48());
X}
X
X
Xvoid bzero(array, length)
X   char *array;
X   int length;
X{
X   int i;
X
X   for (i = 0; i < length; ++i)
X      array[i] = '\0';
X}
X
END-of-utils.c
echo x - heart.attr
sed 's/^X//' >heart.attr << 'END-of-heart.attr'
Xage		R
Xsex		N	0 1
Xcp		N	1 2 3 4
Xtrestbps	R
Xchol		R
Xfbs		N	0 1
Xrestecg		N	0 1 2
Xthalach		R
Xexang		N	0 1
Xoldpeak		R
Xslope		N	1 2 3
Xca		N	0 1 2 3
Xthal		N	3 6 7
Xclass		N	okay disease
END-of-heart.attr
echo x - heart.cmd
sed 's/^X//' >heart.cmd << 'END-of-heart.cmd'
Xget attributes			heart.attr
Xget training_examples		heart.train.pat
Xget test_examples		heart.test.pat
Xget network			heart
X
Xset seed			10
Xset tree_size_limit		10
Xset min_sample			5000
X
Xtrepan				heart.fidelity
Xtest_fidelity
Xtest_correctness
Xprint_tree
Xdraw_tree			heart.tree
X
Xquit
END-of-heart.cmd
echo x - heart.net
sed 's/^X//' >heart.net << 'END-of-heart.net'
Xdefinitions:
Xnunits   29
Xninputs  28
Xnoutputs 1
Xend
Xnetwork:
X%r 28 1		0 28
Xend
Xbiases:
X%r 28 1
Xend
END-of-heart.net
echo x - heart.test.pat
sed 's/^X//' >heart.test.pat << 'END-of-heart.test.pat'
Xp-0     0.5625 1 2 0.2453 0.2511 0 0 0.8168 0 0.1290 1 0 3 okay
Xp-1     0.5625 1 3 0.3396 0.2968 1 2 0.5420 1 0.0968 2 1 6 disease
Xp-2     0.3125 1 2 0.2453 0.3128 0 0 0.7786 0 0.0000 1 0 7 okay
Xp-3     0.7292 1 1 0.1509 0.1941 0 2 0.5573 1 0.2903 2 0 3 okay
Xp-4     0.6458 1 4 0.3396 0.1826 0 2 0.4656 1 0.3871 2 2 7 disease
Xp-5     0.2917 1 4 0.5283 0.2763 0 0 0.7634 0 0.2419 1 0 3 okay
Xp-6     0.4583 1 1 0.2925 0.1986 0 2 0.4122 1 0.2258 1 1 3 okay
Xp-7     0.6875 1 4 0.2453 0.3219 0 0 0.2137 1 0.2903 2 2 7 disease
Xp-8     0.5000 0 4 0.3396 0.3151 0 2 0.5496 0 0.0645 2 0 3 okay
Xp-9     0.4792 1 2 0.2453 0.4543 0 0 0.7710 0 0.0323 1 0 3 okay
Xp-10    0.2500 1 2 0.3868 0.1758 0 0 0.4656 0 0.0000 2 0 6 okay
Xp-11    0.4583 1 3 0.0000 0.2306 0 0 0.6336 1 0.0000 1 1 7 okay
Xp-12    0.1250 1 4 0.2453 0.1644 0 0 0.4504 1 0.2581 2 0 7 disease
Xp-13    0.3750 1 3 0.1321 0.2671 0 0 0.6183 0 0.0000 1 0 3 disease
Xp-14    0.4583 1 4 0.4340 0.3950 0 0 0.7786 1 0.2581 1 0 7 disease
Xp-15    0.7292 1 4 0.4811 0.1963 0 2 0.4656 0 0.3226 2 2 6 disease
Xp-16    0.5625 0 4 0.3774 0.6461 0 2 0.6031 1 0.3065 2 2 7 disease
Xp-17    0.8333 1 1 0.6226 0.2466 1 2 0.4580 0 0.0161 2 1 3 okay
Xp-18    0.6042 1 4 0.3208 0.3037 0 2 0.4504 1 0.4839 2 2 7 disease
Xp-19    0.6250 1 4 0.4151 0.3311 0 2 0.8473 0 0.0000 1 0 3 okay
Xp-20    0.1042 0 2 0.2264 0.1918 0 0 0.9237 0 0.1129 1 0 3 okay
Xp-21    0.7917 0 3 0.5472 0.3447 0 0 0.7710 0 0.0000 1 1 3 okay
Xp-22    0.5417 0 4 0.8113 0.4589 0 1 0.3511 1 0.5484 2 0 3 disease
Xp-23    0.4792 1 4 0.2925 0.1963 0 0 0.7405 0 0.1613 1 2 7 disease
Xp-24    0.6875 1 2 0.3208 0.1872 1 2 0.5267 0 0.0000 1 0 3 okay
Xp-25    0.6042 1 4 0.4906 0.2100 0 0 0.2595 0 0.3226 2 1 7 disease
Xp-26    0.7708 1 4 0.6226 0.2329 0 2 0.5115 0 0.3710 1 0 6 okay
Xp-27    0.3750 1 3 0.3396 0.2900 0 0 0.8244 0 0.0000 1 0 3 okay
Xp-28    0.6667 1 4 0.5094 0.1758 0 0 0.6870 0 0.0000 1 1 7 disease
Xp-29    0.5625 1 2 0.2453 0.2603 0 0 0.7481 0 0.0000 3 0 3 okay
Xp-30    0.8125 1 4 0.4717 0.1530 1 0 0.5344 0 0.5484 2 2 7 disease
END-of-heart.test.pat
echo x - heart.train.pat
sed 's/^X//' >heart.train.pat << 'END-of-heart.train.pat'
Xp-0     0.7083 1 1 0.4811 0.2443 1 2 0.6031 0 0.3710 3 0 6 okay
Xp-1     0.7917 1 4 0.6226 0.3653 0 2 0.2824 1 0.2419 2 3 3 disease
Xp-2     0.7917 1 4 0.2453 0.2352 0 2 0.4427 1 0.4194 2 2 7 disease
Xp-3     0.1667 1 3 0.3396 0.2831 0 0 0.8855 0 0.5645 3 0 3 okay
Xp-4     0.2500 0 2 0.3396 0.1781 0 2 0.7710 0 0.2258 1 0 3 okay
Xp-5     0.6875 0 4 0.4340 0.3242 0 2 0.6794 0 0.5806 3 2 3 disease
Xp-6     0.5833 0 4 0.2453 0.5205 0 0 0.7023 1 0.0968 1 0 3 okay
Xp-7     0.7083 1 4 0.3396 0.2922 0 2 0.5802 0 0.2258 2 1 7 disease
Xp-8     0.5000 1 4 0.4340 0.1758 1 2 0.6412 1 0.5000 3 0 7 disease
Xp-9     0.5833 1 4 0.4340 0.1507 0 0 0.5878 0 0.0645 2 0 6 okay
Xp-10    0.5625 0 2 0.4340 0.3836 0 2 0.6260 0 0.2097 2 0 3 okay
Xp-11    0.4792 1 3 0.7358 0.1667 1 0 0.6947 0 0.0806 1 0 7 okay
Xp-12    0.5833 1 3 0.5283 0.0959 0 0 0.7863 0 0.2581 1 0 3 okay
Xp-13    0.3958 1 2 0.1509 0.2352 0 0 0.7405 0 0.1613 3 0 7 disease
Xp-14    0.5208 1 4 0.4340 0.2580 0 0 0.6794 0 0.1935 1 0 3 okay
Xp-15    0.3958 0 3 0.3396 0.3402 0 0 0.5191 0 0.0323 1 0 3 okay
Xp-16    0.4167 1 2 0.3396 0.3196 0 0 0.7634 0 0.0968 1 0 3 okay
Xp-17    0.6042 0 1 0.5283 0.3584 1 2 0.6947 0 0.1613 1 0 3 okay
Xp-18    0.6042 1 2 0.2453 0.3607 0 2 0.6794 0 0.2903 2 0 3 disease
Xp-19    0.6042 1 3 0.3585 0.2237 0 2 0.7786 0 0.5161 1 2 7 disease
Xp-20    0.4375 0 3 0.2453 0.2123 0 0 0.6641 0 0.2581 2 0 3 okay
Xp-21    0.6042 0 3 0.2453 0.4886 0 0 0.7710 0 0.0000 1 0 3 okay
Xp-22    0.7708 0 1 0.5283 0.2283 0 0 0.3282 0 0.4194 3 0 3 okay
Xp-23    0.2292 1 4 0.1509 0.0936 0 2 0.3282 1 0.3226 2 0 7 disease
Xp-24    0.8333 0 1 0.4340 0.2580 0 0 0.6107 0 0.2903 1 2 3 okay
Xp-25    0.6458 1 4 0.2170 0.2374 1 0 0.6794 1 0.2258 1 2 7 disease
Xp-26    0.7292 1 3 0.4340 0.4772 0 0 0.6641 0 0.0000 1 0 3 disease
Xp-27    0.6250 1 4 0.3868 0.2466 0 0 0.6870 0 0.0806 2 0 7 okay
Xp-28    0.3125 1 3 0.3396 0.2443 0 0 0.8244 1 0.0645 1 0 3 okay
Xp-29    0.2708 1 4 0.4340 0.2283 0 0 0.8168 0 0.0000 1 0 3 okay
Xp-30    0.2917 1 4 0.2453 0.1164 0 2 0.3740 1 0.4032 2 0 7 disease
Xp-31    0.5833 1 4 0.5283 0.3425 0 2 0.3130 1 0.0968 2 1 6 disease
Xp-32    0.5417 1 4 0.3585 0.5183 0 0 0.4656 1 0.1935 2 1 7 disease
Xp-33    0.6667 1 3 0.5283 0.2671 1 0 0.5038 1 0.1613 2 0 3 okay
Xp-34    0.7500 0 4 0.5283 0.2260 0 2 0.3282 0 0.1613 2 3 7 disease
Xp-35    0.2292 1 1 0.4340 0.1667 0 0 0.8168 1 0.2258 1 0 7 okay
Xp-36    0.8750 0 2 0.6226 0.4018 0 0 0.6947 0 0.0645 1 2 3 okay
Xp-37    0.6250 1 3 0.5283 0.1963 1 0 0.6565 0 0.2581 1 0 3 okay
Xp-38    0.6667 0 4 0.3396 0.4658 0 2 0.7481 0 0.0000 1 0 3 disease
Xp-39    0.6042 1 3 0.1698 0.2374 0 2 0.7176 0 0.4032 2 1 7 disease
Xp-40    0.4583 1 3 0.1509 0.1119 0 0 0.3969 0 0.0968 1 0 3 okay
Xp-41    0.4375 1 4 0.5283 0.2671 0 2 0.4351 0 0.4194 2 0 7 disease
Xp-42    0.7500 0 3 0.4340 0.6644 1 2 0.6565 0 0.1290 1 1 3 okay
Xp-43    0.5000 1 3 0.3396 0.1621 1 2 0.6183 0 0.1935 3 0 3 okay
Xp-44    0.2500 0 2 0.1038 0.1644 0 0 0.7405 0 0.0000 1 1 3 okay
Xp-45    0.7500 1 4 0.2453 0.1164 0 0 0.5267 0 0.0645 1 0 7 okay
Xp-46    0.3125 1 4 0.1698 0.3744 0 2 0.6260 0 0.0000 1 1 3 disease
Xp-47    0.3125 1 2 0.3396 0.2123 0 2 0.8931 0 0.0000 1 0 3 okay
Xp-48    0.6458 1 4 0.3396 0.2900 0 0 0.5573 1 0.2258 1 1 7 disease
Xp-49    0.5208 1 4 0.2830 0.3196 0 2 0.2901 1 0.3548 2 1 7 disease
Xp-50    0.4375 1 3 0.4340 0.2443 0 0 0.7023 0 0.0968 2 1 7 disease
Xp-51    0.2500 1 4 0.1509 0.1050 0 2 0.6641 0 0.0000 1 0 7 disease
Xp-52    0.5208 1 3 0.2925 0.3356 0 2 0.6183 0 0.0806 3 1 3 okay
Xp-53    0.4583 0 4 0.3396 0.4087 0 0 0.5420 1 0.1935 2 0 7 disease
Xp-54    0.3542 0 3 0.4528 0.1164 0 2 0.6794 1 0.2258 3 0 3 okay
Xp-55    0.6042 1 4 0.3208 0.2055 0 2 0.4580 1 0.3548 2 3 7 disease
Xp-56    0.5208 0 3 0.3868 0.4064 1 0 0.7557 0 0.0000 1 0 3 okay
Xp-57    0.5208 1 4 0.2453 0.1416 0 0 0.3206 0 0.2258 2 1 7 disease
Xp-58    0.6458 1 4 0.4811 0.3562 0 2 0.5420 1 0.4516 2 2 7 disease
Xp-59    0.6458 1 3 0.4340 0.1347 0 2 0.6412 0 0.4839 2 0 3 disease
Xp-60    0.5208 1 3 0.5283 0.2420 0 2 0.7176 0 0.2581 1 0 7 okay
Xp-61    0.6250 1 4 0.7170 0.4566 0 2 0.5267 1 0.5484 3 0 7 disease
Xp-62    0.3542 1 3 0.5283 0.2397 0 0 0.5802 0 0.5806 2 0 3 disease
Xp-63    0.7500 0 3 0.5755 0.3265 0 0 0.5878 0 0.1290 1 0 3 okay
Xp-64    0.7917 1 4 0.2925 0.2922 1 0 0.7023 0 0.0323 2 2 7 disease
Xp-65    0.7500 1 4 0.1509 0.2785 0 2 0.6641 0 0.0968 1 2 6 disease
Xp-66    0.3125 1 4 0.1509 0.1621 0 2 0.8092 0 0.0000 1 1 3 disease
Xp-67    0.7500 0 3 0.6226 0.5342 0 2 0.6107 0 0.1290 1 0 3 okay
Xp-68    0.6458 1 4 0.2925 0.3014 0 2 0.5344 1 0.4516 2 1 7 disease
Xp-69    0.4583 0 3 0.4340 0.4155 0 2 0.5420 0 0.2419 1 1 3 okay
Xp-70    0.3958 1 2 0.3396 0.2717 0 2 0.8321 0 0.0323 2 0 3 okay
Xp-71    0.6042 1 4 0.5283 0.3288 0 2 0.3053 1 0.1290 1 0 7 disease
Xp-72    0.3333 1 4 0.0943 0.1872 0 2 0.5878 1 0.4839 2 0 3 okay
Xp-73    0.2083 1 3 0.4340 0.4452 0 2 0.8473 0 0.0000 1 0 3 okay
Xp-74    0.8125 1 3 0.8113 0.3379 1 2 0.6031 1 0.2581 2 0 7 disease
Xp-75    0.3125 1 3 0.4340 0.2489 0 2 0.8321 0 0.0000 1 0 3 okay
Xp-76    0.3750 1 3 0.4151 0.2991 0 2 0.6489 0 0.0000 1 0 3 okay
Xp-77    0.5000 0 3 0.3208 0.2055 0 2 0.3359 0 0.0000 1 0 ? okay
Xp-78    0.5000 0 4 0.4151 0.2466 0 2 0.6794 0 0.0000 1 0 3 okay
Xp-79    0.4583 0 3 0.3396 0.2968 0 2 0.5954 0 0.0806 1 0 3 okay
Xp-80    0.7708 1 4 0.2453 0.4018 0 2 0.6107 0 0.0645 2 0 3 okay
Xp-81    0.6875 0 4 0.6226 0.0868 0 2 0.5649 0 1.0000 3 3 7 disease
Xp-82    0.6875 1 3 0.3396 0.2397 0 0 0.5725 0 0.2903 2 3 7 okay
Xp-83    0.3125 0 3 0.1321 0.0342 0 0 0.7939 0 0.0968 2 0 3 okay
Xp-84    0.7083 0 3 0.3868 0.2877 0 2 0.7710 0 0.0000 1 0 3 okay
Xp-85    0.4792 1 4 0.3208 0.2945 0 0 0.6870 1 0.0000 1 1 7 disease
Xp-86    0.6250 1 4 0.1509 0.2580 0 2 0.5420 1 0.1935 2 1 7 disease
Xp-87    0.6458 0 4 0.5283 0.3014 0 2 0.6565 0 0.4194 2 2 7 disease
Xp-88    0.4792 1 2 0.3774 0.1712 0 0 0.6641 0 0.1290 1 1 3 okay
Xp-89    0.3958 1 4 0.2642 0.2192 0 2 0.8779 0 0.0000 1 0 3 okay
Xp-90    0.3333 1 4 0.1981 0.3059 0 2 0.8702 0 0.0000 1 0 3 okay
Xp-91    0.1042 1 1 0.2264 0.1279 0 2 0.7863 0 0.0000 1 0 3 okay
Xp-92    0.5833 0 4 0.3208 0.4041 0 2 0.6718 0 0.0000 1 1 3 okay
Xp-93    0.8750 0 3 0.1509 0.3174 1 2 0.4504 0 0.0000 1 1 3 okay
Xp-94    0.4167 1 3 0.2453 0.1416 0 0 0.5191 0 0.3226 2 3 7 disease
Xp-95    0.5208 1 2 0.1321 0.4178 0 0 0.6489 0 0.0000 1 0 7 okay
Xp-96    0.6250 1 4 0.4340 0.1164 0 0 0.6947 1 0.0000 1 1 7 disease
Xp-97    0.5833 1 3 0.3208 0.2352 0 2 0.6031 0 0.0645 2 1 7 disease
Xp-98    0.6667 1 4 0.2453 0.3059 0 0 0.5267 1 0.5806 2 1 7 disease
Xp-99    0.2083 1 4 0.2264 0.2123 0 0 0.5267 0 0.1935 2 0 7 disease
Xp-100   0.6667 0 4 0.4811 0.4132 0 2 0.5725 1 0.1613 2 0 7 disease
Xp-101   0.5625 1 4 0.2925 0.2808 1 2 0.5573 1 0.1935 2 1 3 disease
Xp-102   0.4792 1 1 0.2264 0.1370 0 2 0.9084 0 0.0000 2 0 6 okay
Xp-103   0.2917 0 4 0.3585 0.4909 1 2 0.4962 1 0.4839 2 0 7 disease
Xp-104   0.6875 0 3 0.3396 0.3128 0 0 0.1985 0 0.1935 2 1 7 disease
Xp-105   0.6042 1 3 0.4340 0.1941 1 2 0.7176 0 0.0000 1 0 3 okay
Xp-106   0.1250 0 4 0.4151 0.1301 0 0 0.8473 0 0.2258 1 0 3 okay
Xp-107   0.7083 1 4 0.3396 0.4658 1 2 0.4656 1 0.2903 1 3 7 disease
Xp-108   0.7500 1 4 0.3868 0.2922 0 2 0.4275 0 0.4516 2 1 7 disease
Xp-109   0.3958 1 4 0.3396 0.2968 1 2 0.6031 1 0.0000 1 2 7 disease
Xp-110   0.7083 0 4 0.5283 0.6416 0 2 0.6336 0 0.6452 2 3 7 disease
Xp-111   0.4583 1 3 0.0566 0.2192 0 0 0.5496 1 0.1935 2 0 3 okay
Xp-112   0.5417 1 4 0.4340 0.2078 0 0 0.3053 1 0.9032 3 0 7 disease
Xp-113   0.7500 1 1 0.4151 0.3562 1 2 0.7863 0 0.2258 2 1 3 disease
Xp-114   0.3333 0 2 0.3396 0.2466 0 2 0.7939 0 0.0968 2 0 3 okay
Xp-115   0.5625 0 4 1.0000 0.3699 1 2 0.4733 1 0.6452 3 2 7 disease
Xp-116   0.5208 1 4 0.1509 0.2580 0 0 0.4198 1 0.4516 2 1 7 disease
Xp-117   0.3125 1 2 0.2453 0.2146 0 0 0.7557 0 0.0000 1 0 3 okay
Xp-118   0.6875 0 4 0.2830 0.1895 0 0 0.7023 0 0.0000 1 0 3 okay
Xp-119   0.5208 1 3 0.2453 0.3014 0 2 0.5802 0 0.0645 2 0 7 okay
Xp-120   0.0000 1 2 0.3396 0.1781 0 2 1.0000 0 0.0000 1 0 3 okay
Xp-121   0.4583 1 4 0.4340 0.3082 0 2 0.8779 1 0.0000 1 0 3 okay
Xp-122   0.2917 0 3 0.2642 0.1986 0 0 0.7176 0 0.0323 2 0 3 okay
Xp-123   0.5417 0 2 0.3868 0.2831 0 2 0.6870 0 0.2258 2 0 3 okay
Xp-124   0.8542 1 4 0.4811 0.1096 0 0 0.4122 1 0.4194 3 0 7 disease
Xp-125   0.6875 1 2 0.2453 0.3539 0 2 0.2443 0 0.2258 2 1 7 disease
Xp-126   0.4583 1 3 0.2925 0.2717 1 2 0.7252 0 0.3871 2 0 3 okay
Xp-127   0.6250 1 2 0.4340 0.2169 0 0 0.7099 1 0.0000 1 0 3 okay
Xp-128   0.6250 1 1 0.7170 0.3699 0 2 0.6718 0 0.0323 2 0 7 disease
Xp-129   0.4792 1 2 0.3208 0.1804 1 0 0.8626 0 0.0000 1 0 3 okay
Xp-130   0.7292 1 3 0.2925 0.4178 0 0 0.4580 1 0.2903 2 0 7 disease
Xp-131   0.6042 1 3 0.1038 0.2603 0 2 0.6336 1 0.0968 2 0 7 okay
Xp-132   0.5833 1 4 0.6698 0.3721 1 2 0.4046 0 0.1613 2 3 7 disease
Xp-133   0.2500 1 3 0.1698 0.2831 0 0 0.8244 0 0.0000 1 0 3 okay
Xp-134   0.3333 1 2 0.3208 0.4155 0 2 0.7557 0 0.0000 1 0 3 okay
Xp-135   0.6458 0 3 0.0755 0.4384 0 0 0.6794 0 0.0000 1 1 3 okay
Xp-136   0.4792 1 1 0.5472 0.3927 1 0 0.8168 0 0.1935 2 0 7 okay
Xp-137   0.2708 0 4 0.0755 0.3174 0 2 0.3893 0 0.0968 2 0 3 okay
Xp-138   0.7917 0 3 0.1981 1.0000 0 2 0.6794 0 0.2581 2 0 7 okay
Xp-139   0.5417 1 4 0.6226 0.3721 0 2 0.5649 1 0.1290 2 1 7 disease
Xp-140   0.7292 1 4 0.2453 0.2740 0 2 0.1908 1 0.3548 3 1 3 disease
Xp-141   0.8542 1 4 0.3396 0.4475 0 2 0.2901 0 0.3871 2 3 3 disease
Xp-142   0.6042 1 4 0.2925 0.3973 0 2 0.7634 0 0.0000 1 2 7 disease
Xp-143   0.6458 1 4 0.4340 0.3813 0 2 0.7557 0 0.1935 2 2 7 disease
Xp-144   0.8125 1 3 0.2264 0.3447 0 0 0.6107 0 0.1613 1 1 7 okay
Xp-145   0.3542 1 2 0.0660 0.1621 1 0 0.6489 0 0.0000 1 0 7 okay
Xp-146   1.0000 1 4 0.2925 0.4064 0 2 0.6947 1 0.0000 1 3 3 disease
Xp-147   0.5208 0 3 0.1509 0.2009 0 0 0.6641 0 0.2581 2 0 3 okay
Xp-148   0.6042 0 4 0.0566 0.2785 0 2 0.3893 0 0.1613 2 0 3 okay
Xp-149   0.3958 1 3 0.2830 0.2945 1 0 0.7939 0 0.0000 1 2 3 okay
Xp-150   0.5833 1 4 0.3585 0.1849 0 0 0.7405 1 0.0000 1 0 7 okay
Xp-151   0.4792 1 3 0.4151 0.2215 0 0 0.7481 0 0.0000 1 ? 3 okay
Xp-152   0.5208 0 2 0.3585 0.3699 1 2 0.6718 1 0.0000 1 1 3 okay
Xp-153   0.1250 1 4 0.3019 0.3562 0 2 0.6489 1 0.0000 1 0 7 disease
Xp-154   0.3333 0 2 0.1698 0.0776 0 0 0.5115 0 0.0000 2 0 3 okay
Xp-155   0.8542 1 3 0.6226 0.3265 0 0 0.3130 1 0.4677 2 1 7 disease
Xp-156   0.5000 1 4 0.4528 0.2283 0 2 0.3053 1 0.0000 1 0 7 okay
Xp-157   0.6250 0 4 0.7547 0.2808 0 0 0.5496 1 0.0000 2 0 3 disease
Xp-158   0.6875 0 4 0.4340 0.6119 0 2 0.6565 0 0.1935 2 0 3 okay
Xp-159   0.5833 1 4 0.5472 0.3379 0 0 0.1298 1 0.1935 2 1 7 disease
Xp-160   0.4792 1 4 0.1321 0.2443 1 0 0.5802 0 0.0161 1 3 7 okay
Xp-161   0.5625 1 4 0.3585 0.1324 0 2 0.2595 1 0.3387 2 1 6 disease
Xp-162   0.2917 1 3 0.3396 0.4315 0 0 0.6947 0 0.3065 1 1 3 okay
Xp-163   0.5000 1 3 0.3396 0.2740 1 2 0.7786 0 0.0000 1 3 3 okay
Xp-164   0.3958 1 4 0.2830 0.3379 0 2 0.7252 0 0.0806 2 0 7 disease
Xp-165   0.2708 1 1 0.5094 0.2694 0 2 0.8168 0 0.1290 1 2 3 okay
Xp-166   0.6250 1 1 0.7925 0.3288 0 2 0.5649 0 0.6774 3 0 7 okay
Xp-167   0.6458 0 4 0.6038 0.4087 0 2 0.6870 0 0.0000 1 0 3 disease
Xp-168   0.7083 0 2 0.4340 0.1575 0 0 0.8244 0 0.0000 1 2 3 okay
Xp-169   0.2708 1 3 0.2453 0.2603 1 0 0.9389 0 0.1290 3 0 7 okay
Xp-170   0.7708 1 2 0.6226 0.2740 0 0 0.3740 1 0.0000 2 3 6 disease
Xp-171   0.5208 1 2 0.9245 0.3584 0 2 0.9466 0 0.0000 1 1 7 disease
Xp-172   0.8333 1 3 0.4340 0.2922 0 2 0.5725 0 0.3226 2 3 7 disease
Xp-173   0.4375 1 3 0.3302 0.1598 0 0 0.7023 0 0.0000 1 0 3 okay
Xp-174   0.4583 1 4 0.4340 0.3927 0 0 0.3893 1 0.6774 2 3 7 disease
Xp-175   0.2917 1 4 0.3585 0.2763 1 2 0.5496 1 0.0161 2 ? 7 disease
Xp-176   0.6875 0 4 0.4151 0.3836 1 0 0.2672 0 0.3065 2 3 3 disease
Xp-177   0.8125 0 3 0.2453 0.1941 0 2 0.3359 0 0.2419 2 0 3 okay
Xp-178   0.7917 1 4 0.0566 0.3950 0 2 0.4122 1 0.1452 2 2 3 disease
Xp-179   0.3333 0 4 0.4151 0.2511 0 2 0.6183 1 0.0323 2 0 3 okay
Xp-180   0.4375 0 2 0.2453 0.2694 0 0 0.6947 0 0.1774 1 0 3 okay
Xp-181   0.6250 1 1 0.6226 0.3356 0 2 0.4122 0 0.0000 1 0 3 disease
Xp-182   0.4375 0 4 0.1509 0.2922 0 2 0.6718 0 0.0000 1 0 3 okay
Xp-183   0.7292 0 4 0.8113 0.4543 0 0 0.6336 1 0.0000 1 0 3 okay
Xp-184   0.5833 1 3 0.5283 0.0000 1 0 0.7786 0 0.0323 1 1 7 okay
Xp-185   0.7292 0 3 0.4340 0.4269 0 0 0.4733 0 0.0323 1 0 7 okay
Xp-186   0.2917 1 4 0.1509 0.1941 0 0 0.6870 0 0.0000 1 0 7 okay
Xp-187   0.3333 1 4 0.4528 0.4178 0 2 0.5802 1 0.0000 2 3 7 disease
Xp-188   0.4375 1 4 0.4717 0.1689 0 2 0.4198 1 0.1452 2 0 7 disease
Xp-189   0.5417 1 2 0.3396 0.3105 0 0 0.6412 0 0.0000 1 0 3 okay
Xp-190   0.6875 0 4 0.5283 0.2694 0 0 0.6336 1 0.2258 2 0 3 disease
Xp-191   0.1667 0 3 0.2453 0.2032 0 0 0.7557 0 0.0000 1 0 3 okay
Xp-192   0.1875 1 1 0.2453 0.2397 0 0 0.8473 1 0.6129 2 0 7 disease
Xp-193   0.2500 1 3 0.3396 0.2009 0 2 0.7405 0 0.3226 2 0 3 okay
Xp-194   0.7708 0 4 0.7925 0.2329 1 0 0.7176 1 0.1613 2 2 7 disease
Xp-195   0.4792 1 4 0.1698 0.2374 0 0 0.6794 0 0.0000 1 1 3 disease
Xp-196   0.5625 1 1 0.2453 0.1530 0 2 0.6947 0 0.3065 2 0 7 okay
Xp-197   0.3542 0 2 0.1038 0.1781 0 0 0.7710 0 0.0000 1 0 3 okay
Xp-198   0.3542 0 4 0.4151 0.2671 0 2 0.6183 1 0.0000 2 0 3 okay
Xp-199   0.7292 0 4 0.3396 0.4041 0 0 0.3893 0 0.3226 2 2 3 okay
Xp-200   0.2500 0 3 0.1698 0.3242 0 2 0.7710 1 0.0000 1 0 3 okay
Xp-201   0.5208 0 3 0.1321 0.3219 0 2 0.7328 0 0.0000 1 0 3 okay
Xp-202   0.2083 0 3 0.0000 0.1667 0 0 0.8244 0 0.0000 1 0 3 okay
Xp-203   0.5000 1 4 0.2736 0.3562 0 0 0.1832 1 0.3226 2 2 7 disease
Xp-204   0.7083 0 4 0.1321 0.3265 0 0 0.7481 1 0.2903 2 2 3 disease
Xp-205   0.3750 1 4 0.1698 0.1781 0 0 0.5496 0 0.0161 1 0 3 okay
Xp-206   0.5208 1 4 0.1509 0.1826 0 2 0.2824 1 0.0000 2 1 3 disease
Xp-207   0.7708 1 4 0.1698 0.1963 0 2 0.4656 1 0.0161 1 1 3 disease
Xp-208   0.4792 0 3 0.3962 0.1598 0 2 0.7481 0 0.0161 2 0 3 okay
Xp-209   0.4167 1 3 0.2264 0.0525 0 2 0.4198 0 0.1290 1 3 3 disease
Xp-210   0.9375 0 2 0.2453 0.3265 0 2 0.3817 1 0.0323 1 1 3 okay
Xp-211   0.5208 0 3 0.6226 0.1712 0 0 0.7023 0 0.0000 1 1 3 okay
Xp-212   0.5208 1 4 0.2642 0.3653 0 2 0.3435 1 0.5161 2 2 3 disease
Xp-213   0.5625 1 4 0.3396 0.3584 1 2 0.2443 1 0.2581 3 0 7 disease
Xp-214   0.3542 1 4 0.2453 0.2808 0 2 0.5573 0 0.1290 1 0 7 disease
Xp-215   0.4167 0 2 0.3774 0.3311 0 0 0.6947 0 0.0000 2 0 3 okay
Xp-216   0.2708 1 2 0.2453 0.3858 0 0 0.6947 0 0.0000 1 0 3 okay
Xp-217   0.2500 1 2 0.1509 0.2489 0 0 0.6260 0 0.0000 1 0 3 okay
Xp-218   0.2500 0 2 0.3019 0.4110 0 0 0.7023 0 0.0000 1 0 3 okay
Xp-219   0.4167 0 4 0.3396 0.3265 0 0 0.7023 0 0.0000 1 0 3 okay
Xp-220   0.6667 1 1 0.3774 0.2466 0 0 0.5649 0 0.4194 2 2 3 disease
Xp-221   0.6458 0 3 0.2453 0.1187 1 0 0.1908 0 0.0000 1 0 3 okay
Xp-222   0.7917 1 4 0.2453 0.2534 0 0 0.0000 0 0.1613 2 0 3 disease
Xp-223   0.6042 1 4 0.0566 0.2466 0 0 0.6489 0 0.0161 1 1 7 disease
Xp-224   0.3750 1 4 0.1509 0.3402 0 2 0.3588 1 0.1613 2 1 3 disease
Xp-225   0.5833 1 4 0.1509 0.1712 0 0 0.4198 1 0.2419 2 0 6 okay
Xp-226   0.7292 1 4 0.3208 0.3128 0 0 0.2595 1 0.0323 2 1 7 okay
Xp-227   0.4583 0 3 0.2453 0.3858 0 2 0.6565 0 0.0968 1 0 3 okay
Xp-228   0.2917 1 4 0.1981 0.4041 0 0 0.8397 0 0.1935 2 0 3 okay
Xp-229   0.2708 0 3 0.2453 0.1895 0 0 0.7786 0 0.0000 2 0 3 okay
Xp-230   0.7917 0 4 0.1132 0.2215 0 0 0.5420 0 0.0484 1 2 3 okay
Xp-231   0.9792 0 3 0.4340 0.1621 0 1 0.3435 0 0.1774 2 0 3 okay
Xp-232   0.8542 1 2 0.5849 0.2717 0 2 0.5496 0 0.0000 1 0 3 okay
Xp-233   0.5833 1 2 0.2830 0.3082 0 0 0.5344 0 0.0484 1 0 7 disease
Xp-234   0.3125 0 3 0.2264 0.2648 0 0 0.5954 0 0.0484 2 1 3 okay
Xp-235   0.6042 0 2 0.3962 0.4406 1 2 0.6183 0 0.0000 1 2 3 disease
Xp-236   0.6458 0 1 0.5283 0.2603 0 0 0.7634 0 0.1452 1 0 3 okay
Xp-237   0.3125 1 3 0.2453 0.2283 0 0 0.7481 0 0.0000 1 0 3 okay
Xp-238   0.6667 1 4 0.4151 0.0913 0 2 0.4122 1 0.5806 2 1 3 disease
Xp-239   0.2708 1 4 0.3962 0.4315 0 0 0.4122 1 0.2903 2 0 6 disease
Xp-240   0.4792 1 4 0.3208 0.1781 1 0 0.6489 1 0.1613 2 0 ? disease
Xp-241   0.6250 1 3 0.3019 0.2100 1 0 0.4809 0 0.3548 2 1 6 disease
Xp-242   0.2292 1 4 0.5472 0.2215 0 0 0.8397 0 0.0000 1 0 7 disease
Xp-243   0.2708 1 3 0.3396 0.1233 0 0 0.6031 0 0.0000 1 0 3 okay
Xp-244   0.6667 1 4 0.4340 0.1849 0 2 0.5115 1 0.3065 1 1 7 disease
Xp-245   0.3542 1 4 0.4340 0.4224 0 0 0.3740 1 0.2903 2 2 7 disease
Xp-246   0.8750 0 4 0.1698 0.0525 0 0 0.4122 0 0.2581 2 0 3 okay
Xp-247   0.6250 1 1 0.3774 0.1781 0 0 0.6947 0 0.1290 1 2 3 disease
Xp-248   0.7292 1 1 0.7170 0.2306 0 2 0.6412 0 0.0968 2 0 7 okay
Xp-249   0.7708 0 3 0.4906 0.3470 0 2 0.6183 0 0.0000 2 1 3 okay
Xp-250   0.2083 0 3 0.4151 0.2146 0 0 0.6183 0 0.0000 2 0 3 okay
Xp-251   0.5833 1 2 0.5660 0.2420 0 2 0.7099 0 0.0000 1 1 3 disease
Xp-252   0.6042 0 4 0.3396 0.1621 0 0 0.4580 0 0.0968 2 0 3 okay
Xp-253   0.5833 1 4 0.1509 0.4772 0 0 0.5496 1 0.4839 2 1 7 disease
Xp-254   0.5417 0 4 0.3208 0.1804 0 1 0.4504 1 0.3226 2 1 7 disease
Xp-255   0.1250 1 2 0.2642 0.1507 0 0 0.7863 0 0.0000 1 0 3 okay
Xp-256   0.6042 1 4 0.1887 0.4384 0 1 0.5267 0 0.7097 3 3 6 disease
Xp-257   0.6042 0 4 0.7170 0.2260 1 2 0.5725 1 0.4516 2 2 6 disease
Xp-258   0.6042 1 2 0.2925 0.2146 0 0 0.5573 0 0.0645 2 ? 7 okay
Xp-259   0.5625 1 2 0.3396 0.2169 0 2 0.7023 0 0.0000 1 0 7 okay
Xp-260   0.7917 1 3 0.5472 0.1963 0 2 0.6031 0 0.1290 2 0 7 disease
Xp-261   0.5417 0 2 0.3585 0.4932 0 0 0.7252 0 0.1935 1 0 3 okay
Xp-262   0.3125 1 4 0.2453 0.0982 0 0 0.5573 1 0.4516 3 0 6 disease
Xp-263   0.7083 1 4 0.4340 0.1393 0 2 0.5573 1 0.6452 1 2 7 disease
Xp-264   0.7083 0 4 0.2830 0.1621 0 0 0.4962 1 0.0000 2 0 3 disease
Xp-265   0.2500 1 2 0.2453 0.0708 0 0 0.8473 0 0.0000 1 0 3 okay
Xp-266   0.6250 1 4 0.6604 0.1142 1 2 0.1450 0 0.1613 2 2 6 disease
Xp-267   0.5833 0 4 0.4340 0.2626 0 0 0.3969 1 0.0323 2 0 7 disease
Xp-268   0.3333 1 1 0.1509 0.3151 0 0 0.4656 0 0.1935 2 0 7 disease
Xp-269   0.5833 1 4 0.3396 0.0114 0 0 0.3359 1 0.1935 2 1 7 disease
Xp-270   0.5833 0 2 0.3396 0.2511 0 2 0.7863 0 0.0000 2 1 3 disease
Xp-271   0.1875 1 3 0.4151 0.1119 0 0 0.7786 0 0.0000 1 ? 3 okay
END-of-heart.train.pat
echo x - heart.wgt
sed 's/^X//' >heart.wgt << 'END-of-heart.wgt'
X-0.884502
X-0.545180
X0.825685
X-0.637266
X0.158687
X-1.527773
X1.552208
X2.632711
X0.491675
X0.505640
X-0.020800
X-0.623910
X-0.188146
X0.072734
X-2.027649
X-0.237234
X0.327129
X3.197414
X-0.468819
X0.960440
X0.129205
X-2.165278
X0.473230
X1.288427
X1.022733
X-0.526460
X-0.575535
X0.712369
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X0.000000
X-0.015175
END-of-heart.wgt
echo x - makefile
sed 's/^X//' >makefile << 'END-of-makefile'
XCC =			gcc
XCFLAGS =		-O
XLIBS =			-lm
X
XSOURCES =		command.c examples.c main.c mofn.c network.c \
X			sample.c stats.c tree.c utils.c \
X			user-command.c user-examples.c
XOBJECTS =		command.o examples.o main.o mofn.o network.o \
X			sample.o stats.o tree.o utils.o \
X			user-command.o user-examples.o
X
X
Xtrepan: $(OBJECTS)
X	$(CC) -o trepan $(CFLAGS) $(OBJECTS) $(LIBS)
X
X
Xtrepan.purify: $(OBJECTS)
X	purify -log-file=trepan.log $(CC) -o trepan.purify $(CFLAGS) \
X	$(OBJECTS) $(LIBS)
X
X	
Xdepend:
X	makedepend -f makefile $(SOURCES)
X
Xlint:
X	lint $(SOURCES)  | less
X
X
X# DO NOT DELETE THIS LINE -- make depend depends on it.
X
Xcommand.o: /usr/include/stdio.h /usr/include/sys/types.h
Xcommand.o: /usr/include/machine/types.h /usr/include/sys/cdefs.h
Xcommand.o: /usr/include/machine/cdefs.h /usr/include/machine/ansi.h
Xcommand.o: /usr/include/machine/endian.h /usr/include/stdlib.h
Xcommand.o: /usr/include/string.h /usr/include/math.h utils-exp.h
Xcommand.o: examples-exp.h user-examples-exp.h tree.h command-int.h
Xcommand.o: user-command-exp.h network-exp.h mofn-exp.h sample-exp.h
Xexamples.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xexamples.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xexamples.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xexamples.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xexamples.o: /usr/include/string.h utils-exp.h examples-exp.h
Xmain.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xmain.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xmain.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xmain.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xmain.o: /usr/include/math.h /usr/include/string.h utils-exp.h examples-exp.h
Xmain.o: tree.h command-exp.h
Xmofn.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xmofn.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xmofn.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xmofn.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xmofn.o: /usr/include/math.h /usr/include/string.h utils-exp.h examples-exp.h
Xmofn.o: tree.h sample-exp.h mofn-int.h stats-exp.h
Xnetwork.o: /usr/include/math.h /usr/include/sys/cdefs.h
Xnetwork.o: /usr/include/machine/cdefs.h /usr/include/stdio.h
Xnetwork.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xnetwork.o: /usr/include/machine/ansi.h /usr/include/machine/endian.h
Xnetwork.o: /usr/include/stdlib.h /usr/include/string.h utils-exp.h
Xnetwork.o: examples-exp.h tree.h network-int.h
Xsample.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xsample.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xsample.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xsample.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xsample.o: /usr/include/string.h /usr/include/math.h utils-exp.h
Xsample.o: examples-exp.h tree.h stats-exp.h sample-int.h
Xstats.o: /usr/include/stdio.h /usr/include/sys/types.h
Xstats.o: /usr/include/machine/types.h /usr/include/sys/cdefs.h
Xstats.o: /usr/include/machine/cdefs.h /usr/include/machine/ansi.h
Xstats.o: /usr/include/machine/endian.h /usr/include/stdlib.h
Xstats.o: /usr/include/math.h utils-exp.h stats-int.h
Xtree.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xtree.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xtree.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xtree.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xtree.o: /usr/include/math.h utils-exp.h examples-exp.h network-exp.h tree.h
Xtree.o: sample-exp.h mofn-exp.h
Xutils.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xutils.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xutils.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xutils.o: /usr/include/machine/endian.h /usr/include/stdio.h utils-exp.h
Xuser-command.o: /usr/include/stdio.h /usr/include/sys/types.h
Xuser-command.o: /usr/include/machine/types.h /usr/include/sys/cdefs.h
Xuser-command.o: /usr/include/machine/cdefs.h /usr/include/machine/ansi.h
Xuser-command.o: /usr/include/machine/endian.h /usr/include/stdlib.h
Xuser-command.o: /usr/include/string.h /usr/include/math.h utils-exp.h
Xuser-command.o: examples-exp.h tree.h command-int.h network-exp.h mofn-exp.h
Xuser-command.o: sample-exp.h
Xuser-examples.o: /usr/include/stdlib.h /usr/include/machine/ansi.h
Xuser-examples.o: /usr/include/sys/types.h /usr/include/machine/types.h
Xuser-examples.o: /usr/include/sys/cdefs.h /usr/include/machine/cdefs.h
Xuser-examples.o: /usr/include/machine/endian.h /usr/include/stdio.h
Xuser-examples.o: /usr/include/string.h utils-exp.h examples-exp.h
Xuser-examples.o: user-examples-int.h
END-of-makefile
exit

