#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "tree.h"
#include "command-exp.h"
// #include "java-interface.h"



// int main(int argc, char **argv)
// {
//     JavaVM *jvm;
//     JNIEnv *env;
//     env = create_vm(&jvm);
//     if(env == NULL)
//         return 1;
//     invoke_class(env);
//     return 0;
// }


main(argc, argv)
   int argc;
   char **argv;
{
   long int random_seed = DEFAULT_SEED;
   FILE *in_stream = stdin;

   if (prog_name = strrchr(argv[0], '/'))
      ++prog_name;
   else
      prog_name = argv[0];

   if (argc == 2)
   {
      in_stream = check_fopen(argv[1], "r");
   }
   else if (argc > 2)
   {
      sprintf(err_buffer, "%s [command-file]", prog_name);
      error("usage", err_buffer, TRUE);
   }

   
   printf("Hello! This is a trepan version using a fucking ontology!\n");
   my_srandom(random_seed);
   init_data_structures();
   init_command_handling();
   run_commands(in_stream);

}


