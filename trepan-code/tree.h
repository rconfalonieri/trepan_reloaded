#define MIXED_CLASS -1
#define NO_CLASS -2
#define MISSING -3

#define UNDETERMINED 3

#define Log2(x) (log(x) / 0.69314718055994530942)

//added by roberto
#define PENALTY 0.5

typedef enum split_type
{
   NOMINAL_SPLIT,
   M_OF_N_SPLIT,
   REAL_SPLIT,
   BOOLEAN_SPLIT
} SplitType;

typedef struct member
{
   int attribute;
   float posterior;
   ValueType value;
   AttributeType type;
   char negated; /* used only for real-valued splits */
   struct member *next;
} Member;

typedef struct split
{
   SplitType type;
   int arity;
   int reference_count;
   char can_use;
   union {
      struct /* split on nominal or boolean attribute */
      {
         int attribute;
      } nominal;
      struct /* M-of-N split */
      {
         int m;
         Member *members;
         char expanded;
         unsigned int sample_key;
         float chi_square_prob;
      } mofn;
      struct /* split on real attribute */
      {
         int attribute;
         float threshold;
      } real;
      struct /* boolean split on nominal attribute */
      {
         int attribute;
         int value;
         char bool_attr;
      } boolean;
   } type_specific;
   float total;
   float missing;
   float *branch_distr;
   float **class_distr; /* arity X classes */
   float gain;
   struct split *next;
   struct split *prev;
   //added by roberto
   char attribute_is_in_ontology;       /* true or false depending on the whether the attribute is in the ontology or not*/
   char attribute_value_is_in_ontology; /* true or false depending on the whether the value is in the ontology or not*/
   float frequency;
} Split;

#define Get_Nominal_Attr(a) ((a)->type_specific.nominal.attribute)
#define Get_M(a) ((a)->type_specific.mofn.m)
#define Get_N(a) ((a)->type_specific.mofn.n)
#define Get_Members(a) ((a)->type_specific.mofn.members)
#define Get_Real_Attr(a) ((a)->type_specific.real.attribute)
#define Get_Threshold(a) ((a)->type_specific.real.threshold)
#define Get_Boolean_Attr(a) ((a)->type_specific.boolean.attribute)
#define Get_Boolean_Value(a) ((a)->type_specific.boolean.value)
#define Is_Boolean_Attr(a) ((a)->type_specific.boolean.bool_attr)

typedef enum node_type
{
   INTERNAL,
   LEAF
} NodeType;
typedef enum stop_reason
{
   S_GLOBAL,
   S_DEPTH,
   S_NO_SPLITS,
   S_NO_PICK_SPLIT,
   S_MIN_OBJECTS,
   S_ERROR,
   S_SAMPLING,
   S_SIMPLIFIED,
   S_PRUNED,
   S_ZERO_BRANCH_PROB
} StopReason;
//added by roberto
typedef enum split_node_type
{
   MOFN,
   DISJ,
   CONJ,
   LO_MOFN
} SplitNodeType;

typedef struct tree_node
{
   NodeType type;
   int number;
   union {
      struct
      {
         Split *split;
         struct tree_node **children;
         float *probs;
      } internal;
      struct
      {
         char covered; /* does this leaf meet covering criteria */
         StopReason stop_reason;
         float total; /* classification statistic */
         float error; /* classification statistic */
      } leaf;
   } type_specific;
   Distribution **distributions;
   struct tree_node *parent;
   int parent_branch;
   int class;
   float error; /* error as calculated in C4.5 */
   float *s_distribution;
   float s_total; /* total # of samples at node */
   float *e_distribution;
   float e_total; /* total # of examples/samples at node */
   //added by roberto
   SplitNodeType split_node_type;
} TreeNode;

#define Get_Split(a) ((a)->type_specific.internal.split)
#define Get_Children(a) ((a)->type_specific.internal.children)
#define Get_Nth_Child(a, n) ((a)->type_specific.internal.children[(n)])
#define Get_Probs(a) ((a)->type_specific.internal.probs)
#define Get_Nth_Prob(a, n) ((a)->type_specific.internal.probs[(n)])

#define Get_Class_Total(a, i) ((a)->e_distribution[(i)] + \
                               (a)->s_distribution[(i)])
#define Get_Predicted_Class_Total(a) ((a)->e_distribution[(a)->class] + \
                                      (a)->s_distribution[(a)->class])
#define Get_Total(a) ((a)->e_total + (a)->s_total)
#define Get_Example_Error(a) ((a)->e_total - (a)->e_distribution[(a)->class])
#define Get_Total_Error(a) ((a)->e_total + (a)->s_total -     \
                            (a)->e_distribution[(a)->class] - \
                            (a)->s_distribution[(a)->class])
#define Get_Example_Proportion(a) ((a)->e_distribution[(a)->class] / (a)->e_total)
#define Get_Sample_Proportion(a) ((a)->s_distribution[(a)->class] / (a)->s_total)
#define Get_Proportion(a) (Get_Predicted_Class_Total((a)) / Get_Total((a)))

typedef struct constraint
{
   Split *split;
   Member *member;
   int branch;
   struct constraint *next;
} Constraint;

typedef struct
{
   int internal;
   int leaves;
   int values;
   int total_branches;
   int *rules;
   int *antes;
} TreeStats;

typedef enum expansion__method
{
   DEPTH_FIRST,
   BEST_FIRST
} ExpansionMethod;
typedef enum split_search_method
{
   GREEDY,
   BEAM,
   LOOKAHEAD
} SplitSearchMethod;
typedef enum estimation_method
{
   KERNEL,
   GAUSSIAN,
   UNIFORM
} EstimationMethod;
typedef enum split_eval_method
{
   GAIN,
   GAIN_RATIO,
   ORT
} SplitEvalMethod;
typedef enum distribution_type
{
   LOCAL,
   GLOBAL
} DistributionType;

typedef struct
{
   /* key control parameters */
   ExpansionMethod expansion_method;
   SplitSearchMethod split_search_method;
   int use_oracle;
   int do_sampling;

   /* other control parameters */
   SplitEvalMethod split_method;

   /* stopping parameters */
   int stop_depth;
   int tree_size_limit;
   float min_objects;
   float patience_threshold;
   int patience_counter;

   /* sampling parameters */
   int min_sample;
   int (*oracle)();
   DistributionType distribution_type;
   float min_estimation_fraction;
   float distribution_alpha;
   int min_estimation_sample;
   EstimationMethod estimation_method;
   double (*kernel_width_fn)();
   int print_distributions;
   float stop_z;
   float stop_epsilon;
   int sampling_stop;
   int validation_stop;

   /* m-of-n search parameters */
   int num_mofn_ops;
   void (**mofn_ops)();
   float mofn_level;
   int beam_width;

   /* roberto: allow ontology in tree generation */
   int use_ontology;
   SplitNodeType split_node_type;

} Options;

typedef struct priority_queue
{
   TreeNode *node;
   float priority;
   float *mask;
   struct priority_queue *next;
} PriorityQueue;

extern TreeNode *tree_root;

extern Split *add_split();
extern void cache_oracle_classifications();
extern float calculate_sum_squared_error();
extern void classify_example();
extern void draw_tree();
extern void draw_tree_revisited();
extern void example_distribution();
extern void classify_using_tree();
extern Split *copy_split();
extern void echo_key_parameters();
extern void evaluate_splits();
extern void free_split();
extern void free_tree();
extern void free_unused_splits();
extern ValueType get_class();
extern Distribution **get_local_distributions();
extern Split *get_new_split();
extern int get_predicted_class();
extern TreeNode *induce_tree();
extern float **make_masks();
extern void match_any();
extern float measure_fidelity();
extern Split *pick_split();
extern void print_constraint();
extern void print_constraints();
extern void print_split();
extern void print_tree();
extern void print_rules();
extern void print_rules2();
extern int report_tree_statistics();
extern void reset_statistics();
extern int trivial_split();
extern int trivial_split_when_sampling();
extern void set_constraint();
extern void update_statistics();
extern void unset_constraint();
extern int which_branch();
extern void tree_stats();