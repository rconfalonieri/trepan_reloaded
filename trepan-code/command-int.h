#define MAX_MENUS       20
#define ONewMenu        1
#define OVariable       2
#define OCommand        3
#define OShowVariable   4
 
#define VInt            1
#define VFloat          2
#define VString         4
 

typedef struct option_rec
{
   char  name[40];
   int otype;
   int menunum;
   void (*func)();
   int vartype;
   int *varptr;
   struct option_rec *next;
   struct option_rec *vnext;
} OptionRec;
 
 
 
/* variables shared by command.c and user_command.c */
extern AttributeInfo active_attributes;
extern ExampleInfo train_examples;
extern ExampleInfo test_examples;
extern ExampleInfo validation_examples;
extern Options active_options;

extern int NoMenuNum;
extern int SetMenuNum;
extern int GetMenuNum;
extern int SaveMenuNum;
extern int ShowMenuNum;

extern char arg_buffer[2048];
extern int num_arguments;
extern char *arguments[256];

extern AttributeInfo active_attributes;
extern ExampleInfo train_examples;
extern float *train_mask;
extern ExampleInfo test_examples;
extern ExampleInfo validation_examples;
extern Options active_options;
extern TreeNode *tree;


/* functions shared by command.c and user_command.c */
extern char	*get_next_string();
extern void	install_command_option();
extern void     install_user_commands();
extern void     install_user_variables();
extern void	install_variable_option();
extern void	parse_args();
extern void	restore_options();
extern void	save_options();

