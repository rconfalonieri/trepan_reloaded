#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "user-examples-exp.h"
#include "tree.h"
#include "command-int.h"
#include "user-command-exp.h"
#include "network-exp.h"
#include "mofn-exp.h"
#include "sample-exp.h"


/* variables shared by command.c and user-command.c */
int NoMenuNum;
int SetMenuNum;
int GetMenuNum;
int SaveMenuNum;
int ShowMenuNum;
char arg_buffer[2048];
int num_arguments = 0;
char *arguments[256];


/* variables shared by command.c and user-command.c */
AttributeInfo active_attributes;
ExampleInfo train_examples;
float *train_mask = NULL;
ExampleInfo test_examples;
ExampleInfo validation_examples;
Options active_options;
TreeNode *tree = NULL;


static int num_menus = 0;
static OptionRec *menu_list[MAX_MENUS];
static OptionRec *variable_list = NULL;
static char in_buffer[2048];



static Options backup_options;


void save_options(options)
   Options *options;
{
   memcpy((void *) &backup_options, (void *) options, (int) sizeof(Options));
}


void restore_options(options)
   Options *options;
{
   memcpy((void *) options, (void *) &backup_options, (int) sizeof(Options));
}


void init_data_structures()
{
   train_examples.number = 0;
   train_examples.examples = NULL;

   test_examples.number = 0;
   test_examples.examples = NULL;

   validation_examples.number = 0;
   validation_examples.examples = NULL;

   active_attributes.number = 0;
   active_attributes.class_index = 0;
   active_attributes.num_classes = 0;
   active_attributes.attributes = NULL;
   active_attributes.stratification = NULL;

   active_options.expansion_method = DEPTH_FIRST;
   active_options.split_search_method = GREEDY;
   active_options.do_sampling = FALSE;
   active_options.use_oracle = FALSE;
   active_options.min_objects = 2;
   active_options.beam_width = 2;
   active_options.min_sample = 1000;
   active_options.oracle = NULL;
   active_options.distribution_type = LOCAL;
   active_options.distribution_alpha = 0.10;
   active_options.min_estimation_fraction = 0.0;
   active_options.sampling_stop = FALSE;
   active_options.validation_stop = FALSE;
   active_options.stop_depth = 10000;
   active_options.tree_size_limit = 100;
   active_options.patience_threshold = 0.0;
   active_options.patience_counter = 1;
   active_options.stop_z = 2.32;
   active_options.stop_epsilon = 0.01;

   active_options.num_mofn_ops = 2;
   active_options.mofn_ops = check_malloc(active_options.num_mofn_ops *
					  sizeof(*active_options.mofn_ops));
   active_options.mofn_ops[0] = mofn_plus_1; 
   active_options.mofn_ops[1] = m_plus_1_of_n_plus_1; 
   active_options.mofn_level = 0.05;

   active_options.split_method = GAIN;

   active_options.estimation_method = KERNEL;
   active_options.kernel_width_fn = sqrt;
   active_options.print_distributions = FALSE;

   /* added by roberto */
   active_options.use_ontology = TRUE;
}


void parse_args(in_stream)
   FILE *in_stream;
{
   char *arg;

   fgets(arg_buffer, BUFSIZ, in_stream);

   num_arguments = 0;
   arg = strtok(arg_buffer, " \t\n\"");
   while (arg != NULL)
   {
      arguments[num_arguments] = arg;
      ++num_arguments;
      arg = strtok((char *) NULL, " \t\n\"");
   }
}


static int make_new_menu()
{
   int mnum = num_menus;

   num_menus++;

   if (mnum >= MAX_MENUS)
      error(prog_name, "Too many menus", TRUE);

   menu_list[mnum] = NULL;
   return mnum;
}


static void install_menu_option(name, frommenu, tomenu)
   char *name;
   int frommenu;
   int tomenu;
{
   OptionRec *temp;
   OptionRec *last;
   OptionRec *after;

   if (frommenu >= num_menus)
      error(prog_name, "Origin menu does not exist", TRUE);
   if (tomenu >= num_menus)
      error(prog_name, "Origin menu does not exist", TRUE);

   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
   strcpy(temp->name, name);
   temp->otype = ONewMenu;
   temp->menunum = tomenu;
   temp->next = NULL;

   if (menu_list[frommenu] == NULL)
      menu_list[frommenu] = temp;
   else if (strcasecmp(temp->name, menu_list[frommenu]->name) < 0)
   {
      temp->next = menu_list[frommenu];
      menu_list[frommenu] = temp;
   }
   else
   {
      last = menu_list[frommenu];
      after = menu_list[frommenu]->next;
      while (after != NULL)
         if (strcasecmp(temp->name, after->name) < 0)
            after = NULL;
         else
	 {
            last = after;
            after = after->next;
         }
      temp->next = last->next;
      last->next = temp;
   }
}


void install_command_option(name, frommenu, fptr)
   char *name;
   int frommenu;
   void (*fptr)();
{
   OptionRec *temp;
   OptionRec *last;
   OptionRec *after;

   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
   strcpy(temp->name, name);
   temp->otype = OCommand;
   temp->func = fptr;
   temp->next = NULL;

   if (menu_list[frommenu] == NULL)
      menu_list[frommenu] = temp;
   else if (strcasecmp(temp->name,menu_list[frommenu]->name) < 0)
   {
      temp->next = menu_list[frommenu];
      menu_list[frommenu] = temp;
   }
   else
   {
      last = menu_list[frommenu];
      after = menu_list[frommenu]->next;
      while (after != NULL)
         if (strcasecmp(temp->name, after->name) < 0)
            after = NULL;
         else
         {
            last = after;
            after = after->next;
         }
      temp->next = last->next;
      last->next = temp;
   }
}


static void install_show_variable_option (name, frommenu, vtype, vptr)
   char *name;
   int frommenu;
   int vtype;
   int *vptr;
{
   OptionRec *temp;
   OptionRec *last;
   OptionRec *after;
   OptionRec *tempvl = variable_list;
   int vlfound = 0;

   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
   strcpy(temp->name, name);
   temp->otype = OShowVariable;
   temp->vartype = vtype;
   temp->varptr = vptr;
   temp->next = NULL;

   while ((tempvl != NULL) && (!vlfound))
      if (!strcmp(name,tempvl->name))
         vlfound = 1;
      else
         tempvl = tempvl->vnext;

   if (!vlfound)
   {
      temp->vnext = variable_list;
      variable_list = temp;
   }

   if (menu_list[frommenu] == NULL)
      menu_list[frommenu] = temp;
   else if (strcasecmp(temp->name, menu_list[frommenu]->name) < 0)
   {
      temp->next = menu_list[frommenu];
      menu_list[frommenu] = temp;
   }
   else
   {
      last = menu_list[frommenu];
      after = menu_list[frommenu]->next;
      while (after != NULL)
      if (strcasecmp(temp->name, after->name) < 0)
         after = NULL;
      else
      {
         last = after;
         after = after->next;
      }
      temp->next = last->next;
      last->next = temp;
   }
}


void install_variable_option (name, frommenu, vtype, vptr)
   char *name;
   int frommenu;
   int vtype;
   int *vptr;
{
   OptionRec *temp;
   OptionRec *last;
   OptionRec *after;

   temp = (OptionRec *) check_malloc(sizeof(OptionRec));
   strcpy(temp->name, name);
   temp->otype = OVariable;
   temp->vartype = vtype;
   temp->varptr = vptr;
   temp->next = NULL;
   temp->vnext = variable_list;
   variable_list = temp;

   install_show_variable_option(name, ShowMenuNum, vtype, vptr);

   if (menu_list[frommenu] == NULL)
      menu_list[frommenu] = temp;
   else if (strcasecmp(temp->name,menu_list[frommenu]->name) < 0)
   {
      temp->next = menu_list[frommenu];
      menu_list[frommenu] = temp;
   }
   else
   {
      last = menu_list[frommenu];
      after = menu_list[frommenu]->next;
      while (after != NULL)
         if (strcasecmp(temp->name,after->name) < 0)
            after = NULL;
         else
         {
            last = after;
            after = after->next;
         }
      temp->next = last->next;
      last->next = temp;
   }
}


static OptionRec *find_variable (name, report)
   char *name;
   int report;
{
   OptionRec *temp = variable_list;
   int done = 0;

   while ((temp != NULL) && (!done))
      if (!strcmp(name, temp->name))
         return temp;
      else
         temp = temp->vnext;

   temp = variable_list;
   while ((temp != NULL) && (!done))
      if (Startsame(name, temp->name))
         return temp;
      else
         temp = temp->vnext;

   if (report)
   {
      sprintf(err_buffer, "No variable %s", name);
      error(prog_name, err_buffer, TRUE);
   }
   return NULL;
}


static OptionRec *find_match(name, olst)
   char *name;
   OptionRec *olst;
{
   OptionRec *temp = olst;

   while (temp != NULL)
      if (!strcmp(name, temp->name))
         return(temp);
      else
         temp = temp->next;

   temp = olst;
   while (temp != NULL)
      if (Startsame(name, temp->name))
         return temp;
      else
         temp = temp->next;

   sprintf(err_buffer, "No menu option corresponding to %s",name);
   error(prog_name, err_buffer, TRUE);
   return NULL;
}


char *get_next_string(in_stream)
   FILE *in_stream;
{
   if (fscanf(in_stream, "%s", in_buffer) != EOF)
      return  in_buffer;

   error(prog_name, "unexpected end of file", TRUE);
}


static void show_variable(vtype, varptr)
   int vtype;
   int *varptr;
{
   switch (vtype)
   {
      case VInt:
         printf("%d",*varptr);
         break;
      case VFloat:
         printf("%.6f",* (float *) varptr);
         break;
      case VString:
         printf("%s",(char *) varptr);
         break;
   }
}


static void cmd_echo(in_stream)
   FILE *in_stream;
{
   char *str;
   OptionRec *match;
   char buffer[BUFSIZ];

   fgets(buffer, BUFSIZ, in_stream);

   str = strtok(buffer, " \t\n\"");
   while (str != NULL)
   {
      if (str[0] == '$')
      {
         match = find_variable(str + 1,FALSE);
         if (match == NULL)
	 {
            sprintf(err_buffer, "%s is not a registered variable", str + 1);
	    error("Warning", err_buffer, FALSE);
	 }
         else
            show_variable(match->vartype, match->varptr);
         printf(" ");
      }
      else
         printf("%s ",str);

     str = strtok((char *) NULL, " \t\n\"");
  }
  printf("\n");
}


static void cmd_quit(in_stream)
   FILE *in_stream;
{
   exit(0);
}


static void cmd_get_network(in_stream)
   FILE *in_stream;
{
   char *stem;

   if ((stem = get_next_string(in_stream)) == NULL)
      error(prog_name, "file stem for network files not specified", TRUE);

   get_network(stem);
}


static void cmd_get_ensemble(in_stream)
   FILE *in_stream;
{
   char stem[BUFSIZ];
   int number;

   if (fscanf(in_stream, "%s", stem) != 1)
      error(prog_name, "file stem for network files not specified", TRUE);

   if (fscanf(in_stream, "%d", &number) != 1)
      error(prog_name, "number of networks in ensemble not specified", TRUE);

/*
   if (number < 2 || number > 100)
*/
   if (number < 1 || number > 100)
      error(prog_name,
	    "number of networks in ensemble must be between 2 and 100", TRUE);

   get_ensemble(stem, number);
}


static void cmd_attribute_distributions(in_stream)
   FILE *in_stream;
{
   if (train_examples.number == 0)
   {
      error(prog_name,
	    "attribute_distributions called before training examples loaded",
	    TRUE);
   }

   determine_attribute_distributions(&active_attributes, &train_examples,
				     train_mask);
   print_attribute_distributions(&active_attributes, &active_options, NULL);
}


static void cmd_lo_mofn(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *fname;

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (train_examples.number == 0)
      error(prog_name, "lo_mofn called before training examples loaded", TRUE);

   determine_attribute_distributions(&active_attributes, &train_examples,
				     train_mask);

   if (active_options.print_distributions)
      print_attribute_distributions(&active_attributes, &active_options, NULL);

   save_options(&active_options);

   active_options.expansion_method = BEST_FIRST;
   active_options.split_search_method = GREEDY;
   active_options.do_sampling = TRUE;
   active_options.use_oracle = TRUE;
   active_options.sampling_stop = TRUE;
   active_options.split_node_type = LO_MOFN;

   register_network_oracle(&active_options.oracle);

   if (tree)
      free_tree(tree);

   echo_key_parameters("\nParameter settings for lo_mofn", &active_options);

   tree = induce_tree(&active_attributes, &train_examples, train_mask,
		      &test_examples, &validation_examples, &active_options,
		      fname); 

   restore_options(&active_options);
}


static void cmd_trepan(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *fname;

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (train_examples.number == 0)
      error(prog_name, "TREPAN called before training examples loaded", TRUE);

   determine_attribute_distributions(&active_attributes, &train_examples,
				     train_mask);

   if (active_options.print_distributions)
      print_attribute_distributions(&active_attributes, &active_options, NULL);

   save_options(&active_options);

   active_options.expansion_method = BEST_FIRST;
   active_options.split_search_method = BEAM;
   active_options.do_sampling = TRUE;
   active_options.use_oracle = TRUE;
   active_options.sampling_stop = TRUE;
   active_options.split_node_type = MOFN;

   register_network_oracle(&active_options.oracle);

   if (tree)
      free_tree(tree);

   echo_key_parameters("\nParameter settings for TREPAN", &active_options);

   tree = induce_tree(&active_attributes, &train_examples, train_mask,
		      &test_examples, &validation_examples, &active_options,
		      fname); 

   restore_options(&active_options);
}


static void cmd_disjunctive_trepan(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *fname;

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (train_examples.number == 0)
   {
      error(prog_name,
	    "disjunctive_trepan called before training examples loaded",
	    TRUE);
   }

   determine_attribute_distributions(&active_attributes, &train_examples,
				     train_mask);

   if (active_options.print_distributions)
      print_attribute_distributions(&active_attributes, &active_options, NULL);

   save_options(&active_options);

   active_options.expansion_method = BEST_FIRST;
   active_options.split_search_method = BEAM;
   active_options.do_sampling = TRUE;
   active_options.use_oracle = TRUE;
   active_options.sampling_stop = TRUE;
   active_options.num_mofn_ops = 1;
   active_options.mofn_ops = check_malloc(sizeof(*active_options.mofn_ops));
   active_options.mofn_ops[0] = mofn_plus_1;
   active_options.split_node_type = DISJ;

   register_network_oracle(&active_options.oracle);

   if (tree)
      free_tree(tree);

   echo_key_parameters("\nParameter settings for disjunctive_trepan",
                       &active_options);

   tree = induce_tree(&active_attributes, &train_examples, train_mask,
		      &test_examples, &validation_examples, &active_options,
		      fname); 

   check_free((void *) active_options.mofn_ops);
   restore_options(&active_options);
}


static void cmd_conjunctive_trepan(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *fname;

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (train_examples.number == 0)
   {
      error(prog_name,
	    "conjunctive_trepan called before training examples loaded",
	    TRUE);
   }

   determine_attribute_distributions(&active_attributes, &train_examples,
				     train_mask);

   if (active_options.print_distributions)
      print_attribute_distributions(&active_attributes, &active_options, NULL);

   save_options(&active_options);

   active_options.expansion_method = BEST_FIRST;
   active_options.split_search_method = BEAM;
   active_options.do_sampling = TRUE;
   active_options.use_oracle = TRUE;
   active_options.sampling_stop = TRUE;
   active_options.num_mofn_ops = 1;
   active_options.mofn_ops = check_malloc(sizeof(*active_options.mofn_ops));
   active_options.mofn_ops[0] = m_plus_1_of_n_plus_1; 
    active_options.split_node_type = CONJ;

   register_network_oracle(&active_options.oracle);

   if (tree)
      free_tree(tree);

   echo_key_parameters("\nParameter settings for conjunctive_trepan",
		       &active_options);

   tree = induce_tree(&active_attributes, &train_examples, train_mask,
		      &test_examples, &validation_examples, &active_options,
		      fname); 

   check_free((void *) active_options.mofn_ops);
   restore_options(&active_options);
}


static void cmd_draw_tree(in_stream)
   FILE *in_stream;
{
   char *fname;
   char buffer[BUFSIZ];

   if (!tree)
      error(prog_name, "draw_tree called before tree learned", TRUE);

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (fname == NULL)
      error(prog_name, "unable to read file name in draw_tree", TRUE);

   draw_tree(tree, &active_attributes, fname);
}


static void cmd_print_tree(in_stream)
   FILE *in_stream;
{
   if (!tree)
      error(prog_name, "print_tree called before tree learned", TRUE);

   printf("\nInduced decision tree:");
   printf("\n----------------------\n");
   print_tree(tree, &active_attributes, 0);
   printf("\n\n");
}


static void cmd_test_correctness(in_stream)
   FILE *in_stream;
{
   int **matrix;
   int **covered_matrix;
   int (*saved_oracle)();

   if (!tree)
      error(prog_name, "test_correctness called before tree learned", TRUE);

   matrix = get_confusion_matrix(active_attributes.num_classes);
   covered_matrix = get_confusion_matrix(2);

   saved_oracle = active_options.oracle;
   active_options.oracle = NULL;

   if (train_examples.number != 0)
   {
      classify_using_tree(tree, &train_examples, &active_attributes,
		          &active_options, matrix, covered_matrix, FALSE);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Training",
		    "Correctness");
      printf("\n");
   }

   if (validation_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      classify_using_tree(tree, &validation_examples, &active_attributes,
		          &active_options, matrix, covered_matrix, FALSE);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Validation",
		    "Correctness");
   }

   if (test_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      classify_using_tree(tree, &test_examples, &active_attributes,
		          &active_options, matrix, covered_matrix, FALSE);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Test",
		    "Correctness");
   }

/*
   print_confusion_matrix(covered_matrix, 2, "Correct", "Covered");
   printf("not covered = 1,  covered = 2   |   incorrect = 1, correct = 2\n");
*/

   active_options.oracle = saved_oracle;
   fflush(stdout);
   free_confusion_matrix(matrix, active_attributes.num_classes);
   free_confusion_matrix(covered_matrix, 2);
}


static void cmd_test_fidelity(in_stream)
   FILE *in_stream;
{
   int **matrix;

   if (!tree)
      error(prog_name, "test_fidelity called before tree learned", TRUE);

   matrix = get_confusion_matrix(active_attributes.num_classes);

   if (train_examples.number != 0)
   {
      (void) measure_fidelity(tree, &train_examples, &active_attributes,
		              &active_options, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Oracle", "Tree");
      print_measure(matrix, active_attributes.num_classes, "Training",
		    "Fidelity");
      printf("\n");
   }

   if (validation_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      (void) measure_fidelity(tree, &validation_examples, &active_attributes,
		              &active_options, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Oracle", "Tree");
      print_measure(matrix, active_attributes.num_classes, "Validation",
		    "Fidelity");
      printf("\n");
   }

   if (test_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      (void) measure_fidelity(tree, &test_examples, &active_attributes,
		              &active_options, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Oracle", "Tree");
      print_measure(matrix, active_attributes.num_classes, "Test",
		    "Fidelity");
      printf("\n");
   }

   fflush(stdout);
   free_confusion_matrix(matrix, active_attributes.num_classes);
}


static void cmd_set_seed(in_stream)
   FILE *in_stream;
{
   long int random_seed;

   if (fscanf(in_stream, "%ld", &random_seed) != 1)
   {
      error(prog_name, "unable to read value for random seed", FALSE);
      return;
   }
   my_srandom(random_seed);
}


static void cmd_set_distribution_alpha(in_stream)
   FILE *in_stream;
{
   float temp;

   if (fscanf(in_stream, "%f", &temp) != 1)
   {
      error(prog_name, "unable to read value for distribution_alpha", FALSE);
      return;
   }

   if (temp < 0.0 || temp > 1.0)
   {
      error(prog_name, "distribution_alpha must be in [0, 1]", FALSE);
      return;
   }

   active_options.distribution_alpha = temp;
}


static void cmd_set_beam_width(in_stream)
   FILE *in_stream;
{
   int temp;

   if (fscanf(in_stream, "%d", &temp) != 1)
   {
      error(prog_name, "unable to read value for beam_width", FALSE);
      return;
   }

   if (temp < 1)
   {
      error(prog_name, "beam_width must be at least 1", FALSE);
      return;
   }

   active_options.beam_width = temp;
}


static void cmd_set_min_objects(in_stream)
   FILE *in_stream;
{
   float temp;

   if (fscanf(in_stream, "%f", &temp) != 1)
   {
      error(prog_name, "unable to read value for min_objects", FALSE);
      return;
   }

   if (temp < 0.0)
   {
      error(prog_name, "min_objects must be at least 0.0", FALSE);
      return;
   }

   active_options.min_objects = temp;
}


static void cmd_set_min_estimation_fraction(in_stream)
   FILE *in_stream;
{
   float temp;

   if (fscanf(in_stream, "%f", &temp) != 1)
   {
      error(prog_name, "unable to read value for min_estimation_fraction",
	    TRUE);
      return;
   }

   if (temp < 0.0 || temp > 1.0)
   {
      error(prog_name, "min_estimation_fraction must be between 0.0 and 1.0",
	    TRUE);
      return;
   }

   active_options.min_estimation_fraction = temp;
}


static void cmd_set_stop_epsilon(in_stream)
   FILE *in_stream;
{
   float temp;

   if (fscanf(in_stream, "%f", &temp) != 1)
   {
      error(prog_name, "unable to read value for stop_epsilon", TRUE);
      return;
   }

   if (temp <= 0.0 || temp >= 0.5)
   {
      error(prog_name, "stop_epsilon must be > 0.0 and < 0.5", TRUE);
      return;
   }

   active_options.stop_epsilon = temp;
}


static void cmd_set_estimation_method(in_stream)
   FILE *in_stream;
{
   char name[BUFSIZ];

   if (fscanf(in_stream, "%s", name) != 1)
   {
      error(prog_name, "unable to read name of estimation method", FALSE);
      return;
   }

   if (Startsame(name, "kernel"))
   {
      active_options.estimation_method = KERNEL;
   }
   else if (Startsame(name, "gaussian"))
   {
      active_options.estimation_method = GAUSSIAN;
   }
   else if (Startsame(name, "uniform"))
   {
      active_options.estimation_method = UNIFORM;
   }
   else 
   {
      sprintf(err_buffer, "%s is not a valid estimation method", name);
      error(prog_name, err_buffer, TRUE);
   }

}


static void cmd_set_kernel_width(in_stream)
   FILE *in_stream;
{
   char name[BUFSIZ];

   if (fscanf(in_stream, "%s", name) != 1)
   {
      error(prog_name, "unable to read name of kernel_width function", FALSE);
      return;
   }

   if (Startsame(name, "log"))
   {
      active_options.kernel_width_fn = log;
   }
   else if (Startsame(name, "sqrt"))
   {
      active_options.kernel_width_fn = sqrt;
   }
   else 
   {
      sprintf(err_buffer, "%s is not a valid kernel_width function", name);
      error(prog_name, err_buffer, TRUE);
   }

}


static void cmd_set_min_sample(in_stream)
   FILE *in_stream;
{
   int temp;

   if (fscanf(in_stream, "%d", &temp) != 1)
   {
      error(prog_name, "unable to read value for min_sample", FALSE);
      return;
   }

   if (temp < 0)
   {
      error(prog_name, "min_sample must be at least 0", FALSE);
      return;
   }

   active_options.min_sample = temp;
}


static void cmd_set_classification_function(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *name;

   fgets(buffer, BUFSIZ, in_stream);

   if ((name = strtok(buffer, " \t\n")) == NULL)
   {
      error(prog_name,
	    "function type not specified in set_classification_function", TRUE);
   }

   set_classification_function(name);
}


static void cmd_set_distribution_type(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *name;

   fgets(buffer, BUFSIZ, in_stream);

   if ((name = strtok(buffer, " \t\n")) == NULL)
      error(prog_name, "type not specified in set_distribution_type", TRUE);

   if (Startsame(name, "local"))
      active_options.distribution_type = LOCAL;
   else if (Startsame(name, "global"))
      active_options.distribution_type = GLOBAL;
   else
   {
      sprintf(err_buffer, "%s is not a valid distribution type", name);
      error(prog_name, err_buffer, TRUE);
   }
}


static void cmd_set_split_method(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *name;

   fgets(buffer, BUFSIZ, in_stream);

   if ((name = strtok(buffer, " \t\n")) == NULL)
      error(prog_name, "method type not specified in set_split_method", TRUE);

   if (Startsame(name, "gain"))
      active_options.split_method = GAIN;
   else if (Startsame(name, "gain_ratio"))
      active_options.split_method = GAIN_RATIO;
   else if (Startsame(name, "ratio"))
      active_options.split_method = GAIN_RATIO;
   else if (Startsame(name, "ORT"))
      active_options.split_method = ORT;
   else
   {
      sprintf(err_buffer, "%s is not a valid split method", name);
      error(prog_name, err_buffer, TRUE);
   }
}


static void cmd_set_activation_function(in_stream)
   FILE *in_stream;
{
   char buffer[BUFSIZ];
   char *function_type;
   char *range;

   fgets(buffer, BUFSIZ, in_stream);

   if ((function_type = strtok(buffer, " \t\n")) == NULL)
   {
      error(prog_name, "function type not specified in set_activation_function",
	    TRUE);
   }

   range = strtok(NULL, " \t\n");
   set_activation_function(function_type, range);
}


static void cmd_read_attributes(in_stream)
   FILE *in_stream;
{
   char *name;

   if ((name = get_next_string(in_stream)) == NULL)
      error(prog_name, "file name for attribute file not specified", TRUE);

   if (active_attributes.number)
      free_attributes(&active_attributes);

   if (train_examples.number)
   {
      error("Warning", "freeing loaded training examples", FALSE);
      free_examples(&train_examples, &active_attributes);
   }

   if (test_examples.number)
   {
      error("Warning", "freeing loaded test examples", FALSE);
      free_examples(&test_examples, &active_attributes);
   }

   read_attributes(name, &active_attributes);
}


static void cmd_read_attribute_mappings(in_stream)
   FILE *in_stream;
{
   char *name;

   if ((name = get_next_string(in_stream)) == NULL)
      error(prog_name, "file name for attribute maps not specified", TRUE);

   if (active_attributes.number == 0)
   {
      error(prog_name,
	    "tried to set attribute maps before attributes loaded", TRUE);
   }

   read_attribute_mappings(name, &active_attributes);
}


static void cmd_read_train_examples(in_stream)
   FILE *in_stream;
{
   int num_files = 0;
   char buffer[BUFSIZ];
   char *fnames[256];
   int i;

   if (active_attributes.number == 0)
      error(prog_name,
            "tried to read examples before attribute information loaded", TRUE);

   if (train_examples.number)
   {
      free_examples(&train_examples, &active_attributes);
      check_free((void *) train_mask);
   }

   fgets(buffer, BUFSIZ, in_stream);
   fnames[num_files] = strtok(buffer, " \t\n\"");
   while (fnames[num_files] != NULL)
   {
      ++num_files;
      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
   }

   if (num_files == 0)
      error(prog_name, "file name for examples not specified", TRUE);

   read_examples(fnames, num_files, &active_attributes, &train_examples);

   train_mask = (float *) check_malloc(sizeof(float) * train_examples.number);
   for (i = 0; i < train_examples.number; ++i)
      if (train_examples.examples[i].fold == train_examples.test_fold)
         train_mask[i] = 0.0;
      else
         train_mask[i] = 1.0;
}


static void cmd_read_validation_examples(in_stream)
   FILE *in_stream;
{
   int num_files = 0;
   char buffer[BUFSIZ];
   char *fnames[256];

   if (active_attributes.number == 0)
      error(prog_name,
            "tried to read examples before attribute information loaded", TRUE);

   if (validation_examples.number)
      free_examples(&validation_examples, &active_attributes);

   fgets(buffer, BUFSIZ, in_stream);
   fnames[num_files] = strtok(buffer, " \t\n\"");
   while (fnames[num_files] != NULL)
   {
      ++num_files;
      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
   }

   if (num_files == 0)
      error(prog_name, "file name for examples not specified", TRUE);

   read_examples(fnames, num_files, &active_attributes, &validation_examples);
}


static void cmd_read_test_examples(in_stream)
   FILE *in_stream;
{
   int num_files = 0;
   char buffer[BUFSIZ];
   char *fnames[256];

   if (active_attributes.number == 0)
      error(prog_name,
            "tried to read examples before attribute information loaded", TRUE);

   if (test_examples.number)
      free_examples(&test_examples, &active_attributes);

   fgets(buffer, BUFSIZ, in_stream);
   fnames[num_files] = strtok(buffer, " \t\n\"");
   while (fnames[num_files] != NULL)
   {
      ++num_files;
      fnames[num_files] = strtok((char *) NULL, " \t\n\"");
   }

   if (num_files == 0)
      error(prog_name, "file name for examples not specified", TRUE);

   read_examples(fnames, num_files, &active_attributes, &test_examples);
}


static void cmd_predict_using_network(in_stream)
   FILE *in_stream;
{
   register_network_oracle(&active_options.oracle);
      
   if (train_examples.number != 0)
   {
      predict_using_network(&train_examples, &active_attributes);
      printf("\n");
   }

   if (validation_examples.number != 0)
   {
      predict_using_network(&validation_examples, &active_attributes);
      printf("\n");
   }

   if (test_examples.number != 0)
   {
      predict_using_network(&test_examples, &active_attributes);
      printf("\n");
   }

   fflush(stdout);
}


static void cmd_classify_using_network(in_stream)
   FILE *in_stream;
{
   int **matrix;

   register_network_oracle(&active_options.oracle);
   matrix = get_confusion_matrix(active_attributes.num_classes);

   if (train_examples.number != 0)
   {
      classify_using_network(&active_options, &train_examples, 
			     &active_attributes, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Training",
		    "Correctness");
      printf("\n");
   }

   if (validation_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      classify_using_network(&active_options, &validation_examples, 
			     &active_attributes, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Validation",
		    "Correctness");
   }

   if (test_examples.number != 0)
   {
      reset_confusion_matrix(matrix, active_attributes.num_classes);
      classify_using_network(&active_options, &test_examples, 
			     &active_attributes, matrix);
      printf("\n");
      print_confusion_matrix(matrix, active_attributes.num_classes,
			     "Target", "Predicted");
      print_measure(matrix, active_attributes.num_classes, "Test",
		    "Correctness");
   }

   fflush(stdout);
   free_confusion_matrix(matrix, active_attributes.num_classes);
}


static void init_menus()
{
   NoMenuNum = make_new_menu();
   SetMenuNum = make_new_menu();
   GetMenuNum = make_new_menu();
   SaveMenuNum = make_new_menu();
   ShowMenuNum = make_new_menu();

   install_menu_option("set/", NoMenuNum, SetMenuNum);
   install_menu_option("mainmenu", SetMenuNum, NoMenuNum);
   install_menu_option("get/", NoMenuNum, GetMenuNum);
   install_menu_option("mainmenu", GetMenuNum, NoMenuNum);
   install_menu_option("save/", NoMenuNum, SaveMenuNum);
   install_menu_option("mainmenu", SaveMenuNum, NoMenuNum);
   install_menu_option("show/", NoMenuNum, ShowMenuNum);
   install_menu_option("mainmenu", ShowMenuNum, NoMenuNum);
}


static int read_variable(stream, vtype, varptr)
   FILE *stream;
   int vtype;
   int *varptr;
{
   switch (vtype)
   {
      case VInt:
         return fscanf(stream,"%d", varptr);
      case VFloat:
         return fscanf(stream,"%f", (float *) varptr);
      case VString:
         return fscanf(stream,"%s", (char *) varptr);
      default:
         error(prog_name, "unknown type of variable to read", TRUE);
         return(FALSE);
  }
}


static void install_commands()
{
   install_command_option("attributes", GetMenuNum, cmd_read_attributes);
   install_command_option("test_examples", GetMenuNum,cmd_read_test_examples);
   install_command_option("validation_examples",
			  GetMenuNum,cmd_read_validation_examples);
   install_command_option("training_examples",
			  GetMenuNum,cmd_read_train_examples);
   install_command_option("network", GetMenuNum, cmd_get_network);
   install_command_option("ensemble", GetMenuNum, cmd_get_ensemble);
   install_command_option("attribute_mappings", GetMenuNum,
			  cmd_read_attribute_mappings);

   install_command_option("echo", NoMenuNum, cmd_echo);
   install_command_option("quit", NoMenuNum, cmd_quit);
   install_command_option("print_tree", NoMenuNum, cmd_print_tree);
   install_command_option("draw_tree", NoMenuNum, cmd_draw_tree);
   install_command_option("test_correctness", NoMenuNum, cmd_test_correctness);
   install_command_option("test_fidelity", NoMenuNum, cmd_test_fidelity);
   install_command_option("trepan", NoMenuNum, cmd_trepan);
   install_command_option("disjunctive_trepan", NoMenuNum,
                          cmd_disjunctive_trepan);
   install_command_option("conjunctive_trepan", NoMenuNum,
                          cmd_conjunctive_trepan);
   install_command_option("lo_mofn", NoMenuNum, cmd_lo_mofn);
   install_command_option("predict_using_network", NoMenuNum,
			  cmd_predict_using_network);
   install_command_option("attribute_distributions", NoMenuNum,
			  cmd_attribute_distributions);
   install_command_option("classify_using_network", NoMenuNum,
			  cmd_classify_using_network);

   install_command_option("seed", SetMenuNum, cmd_set_seed);
   install_command_option("min_objects", SetMenuNum, cmd_set_min_objects);
   install_command_option("beam_width", SetMenuNum, cmd_set_beam_width);
   install_command_option("stop_epsilon", SetMenuNum, cmd_set_stop_epsilon);
   install_command_option("min_estimation_fraction", SetMenuNum, 
			  cmd_set_min_estimation_fraction);
   install_command_option("min_sample", SetMenuNum, cmd_set_min_sample);
   install_command_option("distribution_alpha", SetMenuNum,
			  cmd_set_distribution_alpha);
   install_command_option("activation_function", SetMenuNum,
			  cmd_set_activation_function);
   install_command_option("classification_function", SetMenuNum,
			  cmd_set_classification_function);
   install_command_option("kernel_width", SetMenuNum, cmd_set_kernel_width);
   install_command_option("estimation_method", SetMenuNum,
			  cmd_set_estimation_method);
   install_command_option("split_method", SetMenuNum, cmd_set_split_method);
   install_command_option("distribution_type", SetMenuNum, cmd_set_distribution_type);
}


static void install_variables()
{
   install_variable_option("patience_threshold", SetMenuNum, VFloat,
			   (int *) &active_options.patience_threshold);
   install_variable_option("patience_counter", SetMenuNum, VInt,
			   (int *) &active_options.patience_counter);
   install_variable_option("validation_stop", SetMenuNum, VInt,
			   (int *) &active_options.validation_stop);
   install_variable_option("tree_size_limit", SetMenuNum, VInt,
			   (int *) &active_options.tree_size_limit);
   install_variable_option("stop_depth", SetMenuNum, VInt,
			   (int *) &active_options.stop_depth);
   install_variable_option("stop_z", SetMenuNum, VInt,
			   (int *) &active_options.stop_z);
   install_variable_option("print_distributions", SetMenuNum, VInt,
			   (int *) &active_options.print_distributions);
   install_variable_option("mofn_level", SetMenuNum, VFloat,
			   (int *) &active_options.mofn_level);
}


void run_commands(in_stream)
   FILE *in_stream;
{
   int mnum = NoMenuNum;
   OptionRec *match;
   char *str;

   while (TRUE)
   {
      str = get_next_string(in_stream);
      match = find_match(str, menu_list[mnum]);
      if (match)
      {
	 switch (match->otype)
	 {
	    case ONewMenu:
	       mnum = match->menunum;
	       break;
	    case OVariable:
	       if (!read_variable(in_stream, match->vartype, match->varptr))
	       {
		  sprintf(err_buffer, "Failed to read value for %s",
			  match->name);
		  error(prog_name, err_buffer, TRUE);
	       }
	       mnum = NoMenuNum;
	       break;
	    case OCommand:
	       (*match->func)(in_stream);
	       mnum = NoMenuNum;
	       break;
	    case OShowVariable:
	       printf("%s = ",match->name);
	       show_variable(match->vartype, match->varptr);
	       printf("\n");
	       mnum = NoMenuNum;
	       break;
	 }
      }
      else
	 mnum = NoMenuNum;
   }
}


void init_command_handling()
{
   init_menus();
   install_commands();
   install_variables();

   install_user_commands();
   install_user_variables();
}


