#define UNINITIALIZED_KEY	1


/*exported functions */
extern void		check_sample();
extern void		determine_attribute_distributions();
extern Distribution	**determine_local_distributions();
extern int		generate_discrete_attribute_value();
extern float		generate_real_attribute_value();
extern void		get_new_sample();
extern Example		*get_sample_instance();
extern void		print_attribute_distributions();
extern void		reset_sample_index();
extern int		sample();

