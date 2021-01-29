#define MAX_ATTR_VALUES		256
#define MEAN_INDEX		0
#define SIGMA_INDEX		1
#define NULL_ATTR		-1
#define NONE			-1



typedef enum attr_type {NOMINAL_ATTR, REAL_ATTR,
			BOOLEAN_ATTR, VECTOR_ATTR} AttributeType;




typedef struct
{
   int num_levels;
   int *level_counts;
   Order *order;
} Stratification;


typedef struct
{
   int num_states;
   int *num_parameters;
   int *num_examples;
   float **parameters;
} Distribution;


typedef struct
{
   float min;
   float max;
} Range;


typedef struct
{
   int size;
   float **vectors;
} Map;


typedef struct
{
   AttributeType type;			/* type of the attribute */
   char *name;				/* name of the attribute */
   int num_values;			/* number of possible values for
					   discete attribute; should be set
					   to 1 for real attribute */
   char **labels;			/* names of values for discrete att */
   Map *map;				/* input-vector representation of
					   discrete values */
   Range *range;
   int dependency;
   char relevant;
   Distribution *distribution;
   /*added by roberto*/
   char is_in_ontology;
   float frequency;
   char *value_is_in_ontology;
   float *value_frequency_in_ontology;
   char *full_name; /*full name of the attribute*/
   char **full_labels; /*string array with names of values*/
   char **full_labels_for_draw; /*string array with names of values for drawing*/
   Range *original_range; /*min and max values before the normalization (only for real values)*/
} Attribute;


typedef struct
{
   int number;					/* number of attributes */
   int class_index;				/* index of class attribute */
   int num_classes;				/* number of classes */
   Attribute *attributes;			/* attribute descriptors */
   Stratification *stratification;		/* obsolete field */
   char* ontology_filename;
} AttributeInfo;


typedef union
{
   float real;
   float *vector;
   int discrete;
} ValueType;


typedef struct
{
   char missing;
   ValueType value;
} Value;


typedef struct
{
   char *name;			/* name of example */
   Value *values;		/* array of values -- one per attribute */
   Value oracle;		/* cached value of membership query */
   int fold;
} Example;


typedef struct
{
   int number;			/* number of examples actually loaded */
   int size;			/* size of data structure */ 
   int test_fold;
   Example *examples;		/* example descriptors */
} ExampleInfo;


#define Get_Class(ex, attr_info) ((int)(ex)->values[(attr_info)->class_index].value.discrete)

#define ClassIsVector(attr_info) ((attr_info)->attributes[(attr_info)->class_index].type == VECTOR_ATTR)
  

extern void		assign_to_folds();
extern void		free_attributes();
extern void		free_examples();
extern void		read_attribute_dependencies();
extern void		reset_fold_info();

