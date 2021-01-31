#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "tree.h"
#include "command-int.h"
#include "network-exp.h"
#include "mofn-exp.h"
#include "sample-exp.h"
// #include "java-interface.h"

void cmd_read_ontology(in_stream)
   FILE *in_stream;
{
   char *name;

   if ((name = get_next_string(in_stream)) == NULL)
      error(prog_name, "file name for attribute file not specified", TRUE);

   read_attributes_ontology(name, &active_attributes);
}

void cmd_read_ontology_filename(in_stream)
   FILE *in_stream;
{
   char *name;

   if ((name = get_next_string(in_stream)) == NULL)
      error(prog_name, "file name for ontology file not specified", TRUE);

   // const char* extension = ".owl";
   // char* ontology_filename;
   printf("ONTOLOGY FILE IS %s",name);
   active_attributes.ontology_filename = malloc(strlen(name)+1); /* make space for the new string (should check the return value ...) */
   strcpy(active_attributes.ontology_filename, name); /* copy name into the new var */
   printf("ONTOLOGY FILE IS %s",active_attributes.ontology_filename);
  
   // active_attributes.ontology_filename = name;
   // active_options.ontology_filename = name;
}


void cmd_read_attribute_values(in_stream)
   FILE *in_stream;
{
   char *name;

   if ((name = get_next_string(in_stream)) == NULL)
      error(prog_name, "file name for attribute file not specified", TRUE);
   
   read_attribute_values(name, &active_attributes);
}

void cmd_draw_tree_revisited(in_stream)
   FILE *in_stream;
{
   char *fname;
   char buffer[BUFSIZ];

   if (!tree)
      error(prog_name, "draw_tree_revisited called before tree learned", TRUE);

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (fname == NULL)
      error(prog_name, "unable to read file name in draw_tree_revisited", TRUE);

   draw_tree_revisited(tree, &active_attributes, fname);
}

void cmd_use_ontology(in_stream)
   FILE *in_stream;
{
   int use_ontology;

   if (fscanf(in_stream, "%d", &use_ontology) != 1)
   {
      error(prog_name, "unable to read value for use ontology seed", FALSE);
      return;
   }
   if (use_ontology == 0) {
      active_options.use_ontology = 0;
      printf("\ncmd_use_ontology NO use onto");
   }
   else {
      active_options.use_ontology = 1;
      printf("\ncmd_use_ontology YES use onto");
   }
}

void cmd_print_rules(in_stream)
   FILE *in_stream;
   
{
   char *fname;
   char buffer[BUFSIZ];

   if (!tree)
      error(prog_name, "print_rules called before tree learned", TRUE);

   fgets(buffer, BUFSIZ, in_stream);
   fname = strtok(buffer, " \t\n\"");

   if (fname == NULL)
      error(prog_name, "unable to read file name in print_rules", TRUE);

   printf("\nDecision rules:");
   printf("\n----------------------\n");
   FILE *stream = check_fopen(fname, "w");
   // print_rules_2(tree, &active_attributes, 0, stream);
   print_rules(tree, &active_attributes, 0, stream);
   close(stream);
   printf("\n\n");
}

// void cmd_compute_metrics(in_stream)
//    FILE *in_stream;
// {
//    char *fname;
//    char buffer[BUFSIZ];

//    if (!tree)
//       error(prog_name, "cmd_compute_metrics called before tree learned", TRUE);

//    fgets(buffer, BUFSIZ, in_stream);
//    fname = strtok(buffer, " \t\n\"");

//    if (fname == NULL)
//       error(prog_name, "unable to read file name in cmd_compute_metrics", TRUE);

//    compute_metrics(tree, fname);
// }


void install_user_commands()
{
   install_command_option("attribute_values", GetMenuNum, cmd_read_attribute_values);
   install_command_option("ontofilename", GetMenuNum, cmd_read_ontology_filename);
   install_command_option("ontology", GetMenuNum, cmd_read_ontology);
   install_command_option("draw_tree_revisited", NoMenuNum, cmd_draw_tree_revisited);
   install_command_option("use_ontology", SetMenuNum, cmd_use_ontology);
   install_command_option("print_rules", NoMenuNum, cmd_print_rules);
}


void install_user_variables()
{
   
}


