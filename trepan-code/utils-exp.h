#define	TRUE		1
#define FALSE		0
#define DEFAULT_SEED	100
#define EPSILON		0.001

/* return a random number in [0.1] */
#define Rnd() ((float)random()*0.4656612875e-9)

#define Min(a, b) (((a) > (b)) ? (b) : (a))
#define Max(a, b) (((a) < (b)) ? (b) : (a))

extern int			strncasecmp();
#define Startsame(s1,s2)        (!strncasecmp(s1,s2,strlen(s1)))

typedef struct
{
   float value;
   int index;
} Order;


extern char	err_buffer[];
extern char	*prog_name;


//extern void	bzero();
extern FILE	*check_fopen();
extern void	check_free();
extern void	*check_malloc();
extern void	check_system();
extern void	error();
extern int	float_compare();
extern void	free_confusion_matrix();
extern int	**get_confusion_matrix();
extern double	my_random();
extern void	my_srandom();
extern int	order_compare();
extern void	print_measure();
extern void	print_confusion_matrix();
extern void	reset_confusion_matrix();
extern char *my_strcopy(char *);
extern float extract_float_from_string(char*);
extern char *extract_char_from_string(char*); 
extern char *extract_attribute_value_from_string(char*,char*);
extern char *extract_attribute_value_from_string_to_draw(char*,char*);
extern float calculate_unnormalized_value(float,float,float);
