#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "tree.h"
#include "stats-exp.h"
#include "sample-int.h"


static ExampleInfo samples = {0, 0, NONE, NULL};
static int sample_index = 0;


/*
   John & Langley use 1/sqrt(n) but this doesn't seem to smooth enough
   with large data sets.  1/log(n) seems to work better.
*/
static float kernel_width(distribution, index, kernel_width_fn)
   Distribution *distribution;
   int index;
   double (*kernel_width_fn)();
{
   float width;

   width = 1.0 / (*kernel_width_fn)((double)
				    distribution->num_parameters[index]);

   return(width);
}


static void plot_real_attribute_pdf(attribute, distribution, kernel_width_fn)
   Attribute *attribute;
   Distribution *distribution;
   double (*kernel_width_fn)();
{
   char fname[BUFSIZ];
   FILE *stream;
   float increment = 0.005;
   float x, y;
   float sigma, normalizer, temp;
   int i, j;

   for (i = 0; i < distribution->num_states; ++i)
   {
      sprintf(fname, "%s.%d.pdf", attribute->name, i);
      stream = check_fopen(fname, "w");

      sigma = kernel_width(distribution, i, kernel_width_fn);
      normalizer = 1.0 / sqrt(2.0 * M_PI) / sigma;
      for (x = attribute->range->min; x <= attribute->range->max;
	   x += increment)
      {
         y = 0.0;
         for (j = 0; j < distribution->num_parameters[i]; ++j)
         {
	    temp = (x - distribution->parameters[i][j]) / sigma;
	    y += normalizer * exp(-0.5 * temp * temp);
         }
         y /= distribution->num_parameters[i];
         fprintf(stream, "%f\t%f\n", x, y);
      }

      fclose(stream);
   }
}


void print_attribute_distributions(attr_info, options, local_distributions)
   AttributeInfo *attr_info;
   Options *options;
   Distribution **local_distributions;
{
   int i, j, k;
   Attribute *attribute;
   Distribution *distribution;

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      distribution = (local_distributions == NULL) ? attribute->distribution:
		                                     local_distributions[i];

      if (attribute->type == VECTOR_ATTR)
      {
         error("System error",
	   "vector attributes not handled in print_attribute_distributions",
	   TRUE);
      }
      else if (attribute->type == REAL_ATTR)
      {
	 if (options->estimation_method == GAUSSIAN)
	 {
            printf("%-20s mean = %f  stddev = %f\n", attribute->name,
		   attribute->distribution[MEAN_INDEX],
		   attribute->distribution[SIGMA_INDEX]);
/*
*/
	 }
	 else
	 {
            printf("%-20s: using kernel method to estimate density\n",
		   attribute->name);
/*
            plot_real_attribute_pdf(attribute, distribution,
				    options->kernel_width_fn);
*/
	 }
      }
      else
      {
	 for (j = 0; j < distribution->num_states; ++j)
	 {
	    if (j == 0)
               printf("%-20s  ", attribute->name);
	    printf("\t");
            for (k = 0; k < attribute->num_values; ++k)
	       printf("  %.2f", distribution->parameters[j][k]);
            printf("\n");
	 }
      }
   }
}


static void free_attribute_stratification(attr_info)
   AttributeInfo *attr_info;
{
   if (attr_info->stratification)
   {
      check_free((void *) attr_info->stratification->level_counts);
      check_free((void *) attr_info->stratification->order);
      check_free((void *) attr_info->stratification);
      attr_info->stratification = NULL;
   }
}


static Stratification *determine_attribute_stratification(attr_info)
   AttributeInfo *attr_info;
{
   Stratification *strat;
   int *levels;
   int prev;
   int index;
   int i, j;

   strat = (Stratification *) check_malloc(sizeof(Stratification));

   /* determine the level of each attribute */
   levels = (int *) check_malloc(sizeof(int) * attr_info->number);
   strat->num_levels = 0;
   for (i = 0; i < attr_info->number; ++i)
   {
      levels[i] = 0;
      prev = attr_info->attributes[i].dependency;
      while (prev != NULL_ATTR)
      {
	 ++levels[i];
         prev = attr_info->attributes[prev].dependency;
      }

      if (levels[i] > strat->num_levels)
	 strat->num_levels = levels[i];
   }
   ++strat->num_levels;

   /* determine the number of attributes at each level */
   strat->level_counts = (int *) check_malloc(sizeof(int) * strat->num_levels);
   for (i = 0; i < strat->num_levels; ++i)
      strat->level_counts[i] = 0;
   for (i = 0; i < attr_info->number; ++i)
      ++strat->level_counts[ levels[i] ];

   /* order the attributes according to level */
   index = 0;
   strat->order = (Order *) check_malloc(sizeof(Order) * attr_info->number);
   for (i = 0; i < strat->num_levels; ++i)
      for (j = 0; j < attr_info->number; ++j)
	 if (levels[j] == i)
	    strat->order[index++].index = j;

   check_free((void *) levels);

   return(strat);
}


void free_attribute_distributions(attribute)
   Attribute *attribute;
{
   int i;
   Distribution *distribution = attribute->distribution;

   for (i = 0; i < distribution->num_states; ++i)
      check_free((void *) distribution->parameters[i]);
   check_free((void *) distribution->parameters);
   check_free((void *) distribution->num_parameters);

   check_free((void *) distribution);
   attribute->distribution = NULL;
}


static Distribution *set_attribute_distribution(distribution)
   Distribution *distribution;
{
   int i, j;
   Distribution *distr;

   distr = check_malloc(sizeof(Distribution));
   distr->num_states = distribution->num_states;
   distr->num_parameters = (int *) check_malloc(sizeof(int) *
						distribution->num_states);
   distr->num_examples = (int *) check_malloc(sizeof(int) *
				              distribution->num_states);
   distr->parameters = (float **) check_malloc(sizeof(float *) *
					       distribution->num_states);

   for (i = 0; i < distribution->num_states; ++i)
   {
      distr->num_parameters[i] = distribution->num_parameters[i]; 
      distr->num_examples[i] = distribution->num_examples[i]; 
      distr->parameters[i] = (float *) check_malloc(sizeof(float) *
						    distr->num_parameters[i]);
      for (j = 0; j < distribution->num_parameters[i]; ++j)
	 distr->parameters[i][j] = distribution->parameters[i][j];
   }

   return(distr);
}


/*
   Doesn't worry if some values of an attribute have zero occurrences.
*/
static void discrete_attribute_distribution(index, attr_info, ex_info, ex_mask,
					    distribution)
   int index;
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
   float *ex_mask;
   Distribution *distribution;
{
   Attribute *attribute = &attr_info->attributes[index];
   int depend_index = attribute->dependency;
   int dist_index;
   int num_states;
   int d_value;
   int i, j;

   num_states = (depend_index == NULL_ATTR) ? 1 : 
                attr_info->attributes[depend_index].num_values;
   distribution->num_states = num_states;

   /* initialize distributions, counts */
   for (i = 0; i < num_states; ++i)
   {
      distribution->num_parameters[i] = attribute->num_values;
      distribution->num_examples[i] = 0.0;
      for (j = 0; j < attribute->num_values; ++j)
         distribution->parameters[i][j] = 0.0;
   }

   for (i = 0; i < ex_info->number; ++i)
      if (!ex_info->examples[i].values[index].missing && ex_mask[i] > 0.0)
      {
	 dist_index = (depend_index == NULL_ATTR) ? 0 :
		      ex_info->examples[i].values[depend_index].value.discrete;
	 d_value = ex_info->examples[i].values[index].value.discrete;
	 distribution->parameters[dist_index][d_value] += ex_mask[i];
	 distribution->num_examples[dist_index] += ex_mask[i];
      }

   for (i = 0; i < num_states; ++i)
      for (j = 0; j < attribute->num_values; ++j)
      {
	 if (distribution->num_examples[i] != 0.0)
            distribution->parameters[i][j] /= distribution->num_examples[i];
	 else
            distribution->parameters[i][j] = 0.0; 
      }
}


/*
   FOR NOW, PARTIAL EXAMPLES (EX_MASK[I] < 1.0) ARE TREATED AS WHOLE EXAMPLES.
*/
static void real_attribute_distribution(index, attr_info, ex_info, ex_mask,
					distribution)
   int index;
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
   float *ex_mask;
   Distribution *distribution;
{
   Attribute *attribute = &attr_info->attributes[index];
   int depend_index = attribute->dependency;
   int dist_index;
   float value;
   int num_states;
   int i;

   num_states = (depend_index == NULL_ATTR) ? 1 : 
                attr_info->attributes[depend_index].num_values;
   distribution->num_states = num_states;

   for (i = 0; i < num_states; ++i)
   {
      distribution->num_parameters[i] = 0;
      distribution->num_examples[i] = 0.0;
   }

   for (i = 0; i < ex_info->number; ++i)
      if (!ex_info->examples[i].values[index].missing && ex_mask[i] > 0.0)
      {
	 dist_index = (depend_index == NULL_ATTR) ? 0 :
		      ex_info->examples[i].values[depend_index].value.discrete;

         value = ex_info->examples[i].values[index].value.real;

	 distribution->parameters[dist_index][distribution->num_parameters[dist_index]] = value; 
	 ++distribution->num_parameters[dist_index];
         distribution->num_examples[dist_index] += ex_mask[i];
      }

   for (i = 0; i < num_states; ++i)
   {
      qsort((void *) distribution->parameters[i],
            (size_t) distribution->num_parameters[i], sizeof(float),
	    float_compare);
   }
}


static void real_attribute_ranges(index, attr_info, ex_info)
   int index;
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
{
   float value;
   Attribute *attribute = &attr_info->attributes[index];
   int i;

   for (i = 0; i < ex_info->number; ++i)
      if (!ex_info->examples[i].values[index].missing)
      {
         value = ex_info->examples[i].values[index].value.real;

	 if (value < attribute->range->min)
	    attribute->range->min = value;
	 else if (value > attribute->range->max)
	    attribute->range->max = value;
      }
}


void real_attribute_distribution_gaussian(index, attr_info, ex_info,
					  distribution)
   int index;
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
   Distribution *distribution;
{
   Attribute *attribute = &attr_info->attributes[index];
   int depend_index = attribute->dependency;
   float *sum_values;
   float *sum_squares;
   float *counts;
   int dist_index;
   float r_value, variance;
   int num_states;
   int i;

   num_states = (depend_index == NULL_ATTR) ? 1 : 
                attr_info->attributes[depend_index].num_values;

   sum_values = (float *) check_malloc(sizeof(float) * num_states);
   sum_squares = (float *) check_malloc(sizeof(float) * num_states);
   counts = (float *) check_malloc(sizeof(float) * num_states);
   for (i = 0; i < num_states; ++i)
   {
      sum_values[i] = 0.0;
      sum_squares[i] = 0.0;
      counts[i] = 0.0;
   }

   for (i = 0; i < ex_info->number; ++i)
      if (!ex_info->examples[i].values[index].missing)
      {
	 dist_index = (depend_index == NULL_ATTR) ? 0 :
		      ex_info->examples[i].values[depend_index].value.discrete;

         r_value = ex_info->examples[i].values[index].value.real;
         sum_values[dist_index] += r_value; 
         sum_squares[dist_index] += r_value * r_value; 
         ++counts[dist_index];
      }

   for (i = 0; i < num_states; ++i)
   {
      distribution->num_parameters[i] = 2;

      if (counts[i] == 0.0)
      {
         sprintf(err_buffer, "real-valued distribution (%s)with no values",
                 attribute->name);
         error(prog_name, err_buffer, TRUE);
      }

      variance = (sum_squares[i] - sum_values[i] * sum_values[i] / counts[i]) /
		 counts[i];
      variance = (variance < 0.0) ? 0.0 : variance;
      distribution->parameters[i][MEAN_INDEX] = sum_values[i] / counts[i];
      distribution->parameters[i][SIGMA_INDEX] = sqrt((double) variance);
   }


   check_free((void *) sum_values);
   check_free((void *) sum_squares);
   check_free((void *) counts);
}


/*
   Ensure that each value is assigned at least 1%
*/
void determine_attribute_distributions(attr_info, ex_info, ex_mask)
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
   float *ex_mask;
{
   Attribute *attribute;
   Distribution distribution;
   int i;

   free_attribute_stratification(attr_info);
   attr_info->stratification = determine_attribute_stratification(attr_info);

   /* make this big enough for max # of parameters for kernel method */
   distribution.parameters = (float **) check_malloc(sizeof(float **));
   distribution.parameters[0] = (float *) check_malloc(sizeof(float) *
                                                       ex_info->number);
   distribution.num_parameters = (int *) check_malloc(sizeof(int));
   distribution.num_examples = (int *) check_malloc(sizeof(int));

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];

      if (attribute->type == VECTOR_ATTR)
      {
         error("System error",
	   "vector attributes not handled in determine_attribute_distributions",
	   TRUE);
      }
      else if (attribute->type == REAL_ATTR)
      {
         real_attribute_distribution(i, attr_info, ex_info, ex_mask,
				     &distribution);
         real_attribute_ranges(i, attr_info, ex_info);
      }
      else
      {
         discrete_attribute_distribution(i, attr_info, ex_info, ex_mask,
				         &distribution);
      }

      attribute->distribution = set_attribute_distribution(&distribution);
   }

   check_free((void *) distribution.parameters[0]);
   check_free((void *) distribution.parameters);
   check_free((void *) distribution.num_parameters);
   check_free((void *) distribution.num_examples);
}


static void free_distributions(distributions, attr_info)
   Distribution **distributions;
   AttributeInfo *attr_info;
{
   int i, j;
   Distribution *distribution;

   for (i = 0; i < attr_info->number; ++i)
   {
      distribution = distributions[i];
      check_free((void *) distribution->num_parameters);
      check_free((void *) distribution->num_examples);
      for (j = 0; j < distribution->num_states; ++j)
         check_free((void *) distribution->parameters[j]);
      check_free((void *) distribution->parameters);
      check_free((void *) distribution);
   }

   check_free((void *) distributions);
}


static int use_local_distributions(attr_info, local_distributions,
			           ancestor_distributions, constraints, alpha)
   AttributeInfo *attr_info;
   Distribution **local_distributions;
   Distribution **ancestor_distributions;
   Constraint **constraints;
   float alpha;
{
   float prob;
   float bonf_alpha;
   int num_tests;
   int dummy1;
   float dummy2;
   Attribute *attribute;
   Distribution *local;
   Distribution *ancestor;
   float local_values[MAX_ATTR_VALUES], ancestor_values[MAX_ATTR_VALUES];
   int i, j;

   if (ancestor_distributions == NULL)
      return(TRUE);

   num_tests = 0;
   for (i = 0; i < attr_info->number; ++i)
      if (i != attr_info->class_index)
      {
	 if (local_distributions[i]->num_examples[0] == 0.0)
	    return(FALSE);
      
         if (attr_info->attributes[i].relevant && constraints[i] == NULL)
	    ++num_tests;
      }

   bonf_alpha = alpha / num_tests;

/*
printf("===  alpha = %.3f\tBonferroni alpha = %.3f  ====\n", alpha, bonf_alpha);
*/

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      if (attribute->relevant && i != attr_info->class_index &&
	  constraints[i] == NULL)
      {
         local = local_distributions[i];
         ancestor = ancestor_distributions[i];

         if (attribute->type == REAL_ATTR)
         {
	    kolomogorov_smirnov(local->parameters[0], local->num_parameters[0],
			        ancestor->parameters[0],
			        ancestor->num_parameters[0], &dummy2, &prob);
         }
         else
         {

            for (j = 0; j < attribute->num_values; ++j)
	    {
	       local_values[j] = local->parameters[0][j] *
				 local->num_examples[0];
	       ancestor_values[j] = ancestor->parameters[0][j] *
				    ancestor->num_examples[0];
/*
printf("\t%.2f\t%.2f\n", local_values[j], ancestor_values[j]);
*/
	    }

	    chi_square_unequal(local_values, ancestor_values, 
			       attribute->num_values, 0, &dummy1, 
			       &dummy2, &prob);
         }

/*
printf("\t\tp = %.2f\n", prob);
*/

         if (prob <= bonf_alpha)
	    return(TRUE);
      }
   }

   return(FALSE);
}


Distribution **determine_local_distributions(attr_info, ex_info, ex_mask,
					     constraints, 
					     ancestor_distributions, options)
   AttributeInfo *attr_info;
   ExampleInfo *ex_info;
   float *ex_mask;
   Constraint **constraints;
   Distribution **ancestor_distributions;
   Options *options;
{
   Attribute *attribute;
   Distribution distribution;
   Distribution **local_distributions;
   int i;

   /* make this big enough for max # of parameters for kernel method */
   distribution.parameters = (float **) check_malloc(sizeof(float **));
   distribution.parameters[0] = (float *) check_malloc(sizeof(float) *
                                                       ex_info->number);
   distribution.num_parameters = (int *) check_malloc(sizeof(int));
   distribution.num_examples = (int *) check_malloc(sizeof(int));

   local_distributions = (Distribution **) check_malloc(sizeof(Distribution *) *
				                        attr_info->number);

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      if (attribute->type == VECTOR_ATTR)
      {
         error("System error",
	   "vector attributes not handled in determine_local_distributions",
	   TRUE);
      }
      else if (attribute->type == REAL_ATTR)
      {
         real_attribute_distribution(i, attr_info, ex_info, ex_mask,
				     &distribution);
      }
      else
      {
         discrete_attribute_distribution(i, attr_info, ex_info, ex_mask,
				         &distribution);
      }

      local_distributions[i] = set_attribute_distribution(&distribution);
   }

   check_free((void *) distribution.parameters[0]);
   check_free((void *) distribution.parameters);
   check_free((void *) distribution.num_parameters);
   check_free((void *) distribution.num_examples);

   if (use_local_distributions(attr_info, local_distributions,
			       ancestor_distributions, constraints,
			       options->distribution_alpha))
   {
      return(local_distributions);
   }
   else
   {
      free_distributions(local_distributions, attr_info);
      return(NULL);
   }
}



/*
   Uses the "polarity method" from B. D. Ripley, "Computer Generation
   of Random Variables: A Tutorial", International Statistics Review,
   51 (1983), page 310.  This method generates two values at a time
   so the function runs the method every other call.
*/
static float new_generate_using_gaussian()
{
   static float run_method = TRUE;
   static float x, y;
   float v1, v2;
   double w, c;

   if (run_method)
   {
      do
      {
         v1 = 2 * my_random() - 1.0;
         v2 = 2 * my_random() - 1.0;
         w = v1 * v1 + v2 * v2;
      } while (w > 1.0);

      c = sqrt(-2.0 * log(w) / w);
      x = c * v1;
      y = c * v2;

      run_method = FALSE;
      return(x);
   }
   else
   {
      run_method = TRUE;
      return(y);
   }
}


/*
   Uses the "rejection method" from p. 290 of _Numerical Recipes in C_.
   Assume that the attribute distribution is normal; bound it above by
   a constant function.
*/
static float generate_using_gaussian(mean, sigma, lower, upper)
   float mean;
   float sigma;
   float lower;
   float upper;
{
   float ceiling;
   float temp, pdf_value;
   float x, y;
   int rejected;
   float normalizer; 

   normalizer = 1.0 / sqrt(2.0 * M_PI);

   if (mean >= lower && mean <= upper)
      ceiling = normalizer / sigma;
   else if (mean < lower)
   {
      temp = (lower - mean) / sigma;
      ceiling = normalizer / sigma * exp(-0.5 * temp * temp);
   }
   else
   {
      temp = (upper - mean) / sigma;
      ceiling = normalizer / sigma * exp(-0.5 * temp * temp);
   }

   do
   {
      x = lower + my_random() * (upper - lower);
      y = ceiling * my_random();

      temp = (x - mean) / sigma;
      pdf_value = normalizer / sigma * exp(-0.5 * temp * temp);
      rejected =  (y > pdf_value) ? TRUE : FALSE;
   } while (rejected);

   return(x);
}

#define MAX_TRIES	100

/*
   Adapted from p. 143 of _Density Estimation for Statistics and Data
   Analysis_, by B. W. Silverman.
*/
static float generate_using_kernel(attr_distr, index, lower, upper,
				   kernel_width_fn)
   Distribution *attr_distr;
   int index;
   float lower;
   float upper;
   double (*kernel_width_fn)();
{
   int first, last;
   int which;
   float epsilon, perturbation;
   float x;
   float width;
   int tries = 0;

   width = kernel_width(attr_distr, index, kernel_width_fn);

   do
   {
      epsilon = new_generate_using_gaussian();
      perturbation = epsilon * width; 

      for (first = 0; first < attr_distr->num_parameters[index] &&
           attr_distr->parameters[index][first] + perturbation < lower; ++first)
         ;

      ++tries;
   } while (tries < MAX_TRIES && (first == attr_distr->num_parameters[index] || 
	    attr_distr->parameters[index][first] + perturbation > upper));

   if (tries == MAX_TRIES)
   {
      x = lower + my_random() * (upper - lower);
/*
      printf("Reached %d tries in generate_using_kernel:\n", MAX_TRIES);
      printf("\tlower = %f, upper = %f, x = %f\n", lower, upper, x);
*/
   }
   else
   {
      for (last = first; last < attr_distr->num_parameters[index] - 1 &&
	   attr_distr->parameters[index][last + 1] + perturbation <= upper;
	   ++last)
         ;

      which = first + (int) (my_random() * (last - first));
      if (which == attr_distr->num_parameters[index])
         --which;

      x = attr_distr->parameters[index][which] + perturbation;
   }

   if (x < lower || x > upper)
   {
      error("System error", "bad value in generate_using_kernel", TRUE);
   }

   return(x);
}


static float generate_using_uniform(lower, upper)
   float lower;
   float upper;
{
   float x;

   x = lower + my_random() * (upper - lower);
   return(x);
}


float generate_real_attribute_value(distribution, index, lower, upper,
					   options)
   Distribution *distribution;
   int index;
   float lower;
   float upper;
   Options *options;
{
   float value;

   if (options->estimation_method == GAUSSIAN)
   {
      value =
	 generate_using_gaussian(distribution->parameters[index][MEAN_INDEX],
				 distribution->parameters[index][SIGMA_INDEX],
				 lower, upper); 
   }
   else if (options->estimation_method == UNIFORM)
   {
      value = generate_using_uniform(lower, upper);
   }
   else
   {
      value = generate_using_kernel(distribution, index, lower, upper,
				    options->kernel_width_fn);
   }

   return(value);
}



int generate_discrete_attribute_value(probs, num_values)
   float *probs;
   int num_values;
{
   int i;
   float sum;
   float value;

   sum = 0.0;
   for (i = 0; i < num_values; ++i)
      sum += probs[i];

   if (sum == 0.0)
      error("system error", "bad vector in generate_discrete_attribute_value",
	    TRUE);

   do { value = my_random() * sum; } while (value == sum);

   sum = 0.0;
   for (i = 0; i < num_values; ++i)
   {
      if (probs[i] != 0.0 && value >= sum && value < sum + probs[i])
	 return(i);
      sum += probs[i];
   }

   error("system error",
	 "failed to generate value in generate_discrete_attribute_value", TRUE);
}


static void print_example(example, attr_info)
   Example *example;
   AttributeInfo *attr_info;
{
   int i;
   Attribute *attribute;

   for (i = 0; i < attr_info->number; ++i)
      if (i != attr_info->class_index)
      {
         attribute = &attr_info->attributes[i];
         switch (attribute->type)
         {
	    case NOMINAL_ATTR:
	       printf("%s ",
		      attribute->labels[example->values[i].value.discrete]);
	       break;
	    case BOOLEAN_ATTR:
	       if (example->values[i].value.discrete)
	          printf("true ");
	       else
	          printf("false ");
	       break;
	    case REAL_ATTR:
	       printf("%f ", example->values[i].value.real);
	       break;
         }
      }
   printf("\n\n");
}


static int node_in_subtree(root, node)
   TreeNode *root;
   TreeNode *node;
{
   int i;

   if (root == node)
      return(TRUE);
   else if (root->type == LEAF)
      return(FALSE);
   else
   {
      for (i = 0; i < root->type_specific.internal.split->arity; ++i)
	 if (Get_Nth_Child(root, i) && 
	     node_in_subtree(Get_Nth_Child(root, i), node))
	    return(TRUE);
   }

   return(FALSE);
}


static void print_path(attr_info, root, node)
   AttributeInfo *attr_info;
   TreeNode *root;
   TreeNode *node;
{
   TreeNode *current = root;
   int depth = 0;
   int i, j;

   while (current != node)
   {
      for (i = 0; i < current->type_specific.internal.split->arity &&
	   !node_in_subtree(Get_Nth_Child(current, i), node); ++i)
	 ;

      if (i == current->type_specific.internal.split->arity)
	 error("System error", "couldn't find path in print_path", TRUE);

      for (j = 0; j < depth; ++j)
	 printf("|   ");
      print_split(Get_Split(current), attr_info, i, stdout);
      printf("\n");

      current = Get_Nth_Child(current, i);
      ++depth;
   }
}


/*  Assumes that children pointers are initialized to NULL */ 
void check_sample(attr_info, root, node, example, constraints, number)
   AttributeInfo *attr_info;
   TreeNode *root;
   TreeNode *node;
   Example *example;
   Constraint **constraints;
   int number;
{
   TreeNode *current = root;
   int branch;
   int i, j;
   int depth = 0;
   int branch_trace[BUFSIZ];
   TreeNode *node_trace[BUFSIZ];

   /* descend tree until we (a) reach the correct node, (b) reach
      an incorrect leaf, or (c) reach an incomplete node */ 
   while (current != node)
   {
      if (current->type == LEAF)
      {
	 printf("\nCONSTRAINTS:\n");
	 print_constraints(constraints, attr_info);
	 printf("\nEXAMPLE:\n");
	 print_example(example, attr_info);
	 printf("\nBRANCH TRACE:\n");
	 for (i = 0; i < depth; ++i)
	 {
	    for (j = 0; j < i; ++j)
	       printf("|   ");
	    print_split(Get_Split(node_trace[i]), attr_info,
			branch_trace[i], stdout);
	    printf("\n");
	 }
	 printf("\n");
	 printf("\nPATH TO NODE:\n");
         print_path(attr_info, root, node);
	 sprintf(err_buffer,
		 "problem on example (%d) in check_sample: reached leaf",
		 number);
	 error("System Error", err_buffer, TRUE);
      }

      branch = which_branch(Get_Split(current), example);
      node_trace[depth] = current;
      branch_trace[depth++] = branch;
      current  = Get_Nth_Child(current, branch);
      if (!current)
      {
	 printf("\nCONSTRAINTS:\n");
	 print_constraints(constraints, attr_info);
	 printf("\nEXAMPLE:\n");
	 print_example(example, attr_info);
	 printf("\nBRANCH TRACE:\n");
	 for (i = 0; i < depth; ++i)
	 {
	    for (j = 0; j < i; ++j)
	       printf("|   ");
	    print_split(Get_Split(node_trace[i]), attr_info,
			branch_trace[i], stdout);
	    printf("\n");
	 }
	 printf("\n");
	 printf("\nPATH TO NODE:\n");
         print_path(attr_info, root, node);
	 sprintf(err_buffer,
		 "problem on example (%d) in check_sample: reached null branch",
		 number);
	 error("System Error", err_buffer, TRUE);
      }
   }
}


void reset_sample_index()
{
   sample_index = 0;
}


Example *get_sample_instance()
{
   Example *sample;

   if (sample_index >= samples.number)
      return(NULL);

   sample = &samples.examples[sample_index++];

   return(sample);
}


/*
	node is needed only for debugging
*/
void get_new_sample(attr_info, constraints, options, number,
		    local_distributions, node)
   AttributeInfo *attr_info;
   Constraint **constraints;
   Options *options;
   int number;
   Distribution **local_distributions;
   TreeNode *node;
{
   int success = TRUE;
   int i;
   int counter = 0;

   if (number > samples.size)
   {
      free_examples(&samples, attr_info);
      samples.examples = (Example *) check_malloc(sizeof(Example) * number);
      for (i = 0; i < number; ++i)
      {
	 samples.examples[i].name = NULL;
	 samples.examples[i].values =
	    (Value *) check_malloc(sizeof(Value) * attr_info->number);
      }
      samples.size = number;
   }

   for (i = 0; i < number && success; ++i)
   {
      success = sample(attr_info, &samples.examples[i], constraints, options,
	               local_distributions);

if (success)
{
   check_sample(attr_info, tree_root, node, &samples.examples[i], constraints,
                counter);
   ++counter;
}

   }
   samples.number = success ? number : i - 1;
   sample_index = 0;

   cache_oracle_classifications(&samples, attr_info, options);
}


static int bad_discrete_distribution(attribute, posterior)
   Attribute *attribute;
   Posterior *posterior;
{
   int i;

   for (i = 0; i < attribute->num_values; ++i)
      if (posterior->discrete.probs[i] != 0.0)
	 return(FALSE);

   return(TRUE);
}


static void initialize_posterior_with_constraints(attribute, constraints, posterior)
   Attribute *attribute;
   Constraint *constraints;
   Posterior *posterior;
{
   Split *split;
   float threshold;
   int i;

   if (attribute->type == REAL_ATTR)
   {
      while (constraints)
      {
         split = constraints->split;
         if (split->type == REAL_SPLIT)
         {
            threshold = Get_Threshold(constraints->split);
            if (constraints->branch)
               posterior->real.min = Max(posterior->real.min, threshold);
            else
               posterior->real.max = Min(posterior->real.max, threshold);
         }
         constraints = constraints->next;
      }
   }
   else if (attribute->type == BOOLEAN_ATTR)
   {
      while (constraints)
      {
         split = constraints->split;
         if (split->type == BOOLEAN_SPLIT)
            posterior->discrete.probs[constraints->branch] = 0.0; 
         constraints = constraints->next;
      }
   }
   else /* NOMINAL_ATTR */
   {
      while (constraints)
      {
         split = constraints->split;
         if (split->type == BOOLEAN_SPLIT)
         {
            if (constraints->branch == 0)
            {
               for (i = 0; i < attribute->num_values; ++i)
                  if (i != Get_Boolean_Value(split))
                     posterior->discrete.probs[i] = 0.0; 
            }
            else
            {
               posterior->discrete.probs[Get_Boolean_Value(split)] = 0.0; 
            }
         }
         else if (split->type == NOMINAL_SPLIT)
         {
            for (i = 0; i < attribute->num_values; ++i)
               if (i != constraints->branch)
                  posterior->discrete.probs[i] = 0.0; 
         }
         constraints = constraints->next;
      }
   }
}


static Posterior *initialize_posteriors(attr_info, constraints,
					local_distributions, options)
   AttributeInfo *attr_info;
   Constraint **constraints;
   Distribution **local_distributions;
   Options *options;
{
   int i, j;
   Posterior *posteriors;
   Posterior *post;
   Attribute *attribute;
   Distribution *distribution;

   posteriors = (Posterior *) check_malloc(sizeof(Posterior) *
					   attr_info->number);

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      post = &posteriors[i];
      distribution = (local_distributions == NULL) ? attribute->distribution :
                                                     local_distributions[i];

      if (attribute->type == REAL_ATTR)
      {
	 post->real.min = attribute->range->min - SAMPLING_EPSILON;
	 post->real.max = attribute->range->max;
         initialize_posterior_with_constraints(attribute, constraints[i], post);
      }
      else if (attribute->type == BOOLEAN_ATTR)
      {
	 post->discrete.probs = (float *) check_malloc(sizeof(float) * 2);
	 if (options->estimation_method == UNIFORM)
	 {
	    for (j = 0; j < 2; ++j)
	       post->discrete.probs[j] = 0.5; 
	 }
	 else
	 {
	    for (j = 0; j < 2; ++j)
	       post->discrete.probs[j] = distribution->parameters[0][j];
	 }
         initialize_posterior_with_constraints(attribute, constraints[i], post);

         if (bad_discrete_distribution(attribute, post))
	 {
	    for (j = 0; j < 2; ++j)
	       post->discrete.probs[j] = 0.5; 
            initialize_posterior_with_constraints(attribute, constraints[i], post);
	 }
      }
      else /* NOMINAL_ATTR */
      {
	 post->discrete.probs = (float *) check_malloc(sizeof(float) * 
						       attribute->num_values);
	 if (options->estimation_method == UNIFORM)
	 {
	    for (j = 0; j < attribute->num_values; ++j)
	       post->discrete.probs[j] = 1.0 / attribute->num_values; 
	 }
	 else
	 {
	    for (j = 0; j < attribute->num_values; ++j)
	       post->discrete.probs[j] = distribution->parameters[0][j];
	 }
         initialize_posterior_with_constraints(attribute, constraints[i], post);

         if (bad_discrete_distribution(attribute, post))
	 {
	    for (j = 0; j < attribute->num_values; ++j)
	       post->discrete.probs[j] = 1.0 / attribute->num_values; 
            initialize_posterior_with_constraints(attribute, constraints[i], post);
	 }
      }
   }

   return(posteriors);
}


/*
	USES EMPIRICAL DISTRIBUTION FOR REAL-VALUED PARAMETERS
*/
static float calculate_posterior(member, posteriors, attr_info,
				 local_distributions)
   Member *member;
   Posterior *posteriors;
   AttributeInfo *attr_info;
   Distribution **local_distributions;
{
   float sum;
   float prob;
   Attribute *attribute;
   Posterior *post;
   Distribution *distribution;
   int i;
   int n;
   int satisfy;

   if (member->type == NOMINAL_ATTR || member->type == BOOLEAN_ATTR)
   {
      sum = 0.0;
      attribute = &attr_info->attributes[member->attribute];
      post = &posteriors[member->attribute];
      for (i = 0; i < attribute->num_values; ++i)
	 sum += post->discrete.probs[i];

      prob = post->discrete.probs[member->value.discrete] / sum;
   }
   else
   {
      attribute = &attr_info->attributes[member->attribute];
      distribution = (local_distributions == NULL) ? attribute->distribution :
		     local_distributions[member->attribute];
      post = &posteriors[member->attribute];
      n = 0;
      satisfy = 0;
      for (i = 0; i < distribution->num_parameters[0]; ++i)
      {
	 if (distribution->parameters[0][i] > post->real.min &&
	     distribution->parameters[0][i] <= post->real.max)
	 {
	    ++n;

	    if ((member->negated &&
	         distribution->parameters[0][i] <= post->real.max &&
	         distribution->parameters[0][i] > member->value.real) ||
                (!member->negated &&
	         distribution->parameters[0][i] > post->real.min &&
	         distribution->parameters[0][i] <= member->value.real))
	       ++satisfy;
	 }
      }

      if (n == 0)
      {
	 /* no data for empirical distribution: assume uniform */
	 if (member->negated)
	    prob = (post->real.max - member->value.real) /
		   (post->real.max - post->real.min);
	 else
	    prob = (member->value.real - post->real.min) /
		   (post->real.max - post->real.min);
      }
      else
         prob = 1.0 * satisfy / n;
   }

   if (prob < 0.0 || prob > 1.0)
      error("system error", "bad probability in calculate_posterior", TRUE);

   return(prob);
}


static void update_posterior(member, posterior, attr_info, negated)
   Member *member;
   Posterior *posterior;
   AttributeInfo *attr_info;
   char negated;
{
   int i;

   if (member->type == NOMINAL_ATTR || member->type == BOOLEAN_ATTR)
   {
      if (negated)
      {
	 posterior->discrete.probs[member->value.discrete] = 0.0;
      }
      else
      {
         for (i = 0; i < attr_info->attributes[member->attribute].num_values;
	      ++i)
	    if (i != member->value.discrete)
	       posterior->discrete.probs[i] = 0.0;
      }
   }
   else
   {
      if (member->negated != negated)
	 posterior->real.min = Max(posterior->real.min, member->value.real);
      else
	 posterior->real.max = Min(posterior->real.max, member->value.real);
   }
}


static void satisfy_mofn_split(split, posteriors, attr_info,
			       local_distributions)
   Split *split;
   Posterior *posteriors;
   AttributeInfo *attr_info;
   Distribution **local_distributions;
{
   Member *member;
   float sum;
   float value;
   float satisfied;

   do
   {
      satisfied = 0;
      /* determine posterior of each condition */
      sum = 0.0;
      member = Get_Members(split);
      while (member != NULL)
      {
         member->posterior = calculate_posterior(member, posteriors,
						 attr_info,
						 local_distributions);
	 if (member->posterior == 1.0)
	 {
	    ++satisfied;

	    /* HACK TO ACCOUNT FOR USING EMPIRICAL DISTRIBUTIONS */
	    if (member->type == REAL_ATTR)
	       update_posterior(member, &posteriors[member->attribute],
		                attr_info, FALSE);
	 }
	 else
	    sum += member->posterior;

	 member = member->next;
      }

      if (satisfied < Get_M(split))
      {
         if (sum == 0.0)
         {
	    error("system error",
	          "unable to set condition in satisfy_mofn_split", TRUE);
         }

         /* pick a condition */
         do { value = my_random() * sum; } while (value == sum);
         sum = 0.0;
         member = Get_Members(split);
         while (member != NULL)
         {
	    if (member->posterior != 1.0)
	    {
	       if (member->posterior != 0.0 && value >= sum &&
	           value < sum + member->posterior)
	       {
	          break;
	       }
	       sum += member->posterior;
	    }
	    member = member->next;
         }

         if (member == NULL)
         {
	    error("system error",
	          "failed to set a condition in satisfy_mofn_split", TRUE);
         }

         /* adjust posterior of selected attribute */
         update_posterior(member, &posteriors[member->attribute],
		          attr_info, FALSE);
      }

   } while (satisfied < Get_M(split));
}


static void negated_satisfy_mofn_split(split, posteriors, attr_info,
				       local_distributions)
   Split *split;
   Posterior *posteriors;
   AttributeInfo *attr_info;
   Distribution **local_distributions;
{
   Member *member;
   float sum;
   float value;
   int satisfiable;

   do
   {
      satisfiable = 0;
      /* determine posterior of each condition */
      sum = 0.0;
      member = Get_Members(split);
      while (member != NULL)
      {
	 member->posterior = 1.0 - calculate_posterior(member, posteriors,
						       attr_info,
						       local_distributions);
	 if (member->posterior < 1.0)
	 {
	    ++satisfiable;
	    sum += member->posterior;
         }
	 else if (member->type == REAL_ATTR)
	 {
	    /* HACK TO ACCOUNT FOR USING EMPIRICAL DISTRIBUTIONS */
	    update_posterior(member, &posteriors[member->attribute],
		             attr_info, TRUE);
	 }

	 member = member->next;
      }

      if (satisfiable >= Get_M(split))
      {
         if (sum == 0.0)
         {
	    error("system error",
	          "unable to set condition in satisfy_mofn_split", TRUE);
         }

         /* pick a condition */
         do { value = my_random() * sum; } while (value == sum);
         sum = 0.0;
         member = Get_Members(split);
         while (member != NULL)
         {
	    if (member->posterior != 1.0)
	    {
	       if (member->posterior != 0.0 && value >= sum &&
	           value < sum + member->posterior)
	       {
	          break;
	       }
	       sum += member->posterior;
	    }
	    member = member->next;
         }

         if (member == NULL)
         {
	    error("system error",
	          "failed to set a condition in negated_satisfy_mofn_split",
		  TRUE);
         }
   
         /* adjust posterior of selected attribute */
         update_posterior(member, &posteriors[member->attribute],
			  attr_info, TRUE);
      }

   } while (satisfiable >= Get_M(split));
}


static void set_attribute_values(example, attr_info, posteriors,
			         local_distributions, options)
   Example *example;
   AttributeInfo *attr_info;
   Posterior *posteriors;
   Distribution **local_distributions;
   Options *options;
{
   int i;
   Posterior *post;
   Attribute *attribute;
   Distribution *distribution;

   for (i = 0; i < attr_info->number; ++i)
      if (i != attr_info->class_index)
      {
	 attribute = &attr_info->attributes[i];
         distribution = (local_distributions == NULL) ?
			attribute->distribution : local_distributions[i];
	 post = &posteriors[i];
	 example->values[i].missing = FALSE;

	 if (attribute->type == REAL_ATTR)
	 {
	    if (options->estimation_method == UNIFORM)
	    {
	       example->values[i].value.real =
	       generate_using_uniform(post->real.min + SAMPLING_EPSILON,
				      post->real.max);
	    }
	    else
	    {
	       example->values[i].value.real =
	       generate_using_kernel(distribution, 0,
				  post->real.min + SAMPLING_EPSILON,
				  post->real.max, options->kernel_width_fn);
	    }
	 }
	 else
	 {
	    example->values[i].value.discrete =
	    generate_discrete_attribute_value(post->discrete.probs,
					      attribute->num_values);
	 }
      }
}


static void free_posteriors(posteriors, attr_info)
   Posterior *posteriors;
   AttributeInfo *attr_info;
{
   int i;

   for (i = 0; i < attr_info->number; ++i)
      if (attr_info->attributes[i].type != REAL_ATTR)
      {
	 check_free((void *) posteriors[i].discrete.probs);
      }

   check_free((void *) posteriors);
}


/*
	WOULD BE MORE EFFICIENT IF PASSED SPLITS INSTEAD OF CONSTRAINTS
	TO SAMPLE WITH GAUSSIAN METHOD, EXTEND DETERMINE CALCULATE_POSTERIOR
*/
int sample(attr_info, example, constraints, options, local_distributions)
   AttributeInfo *attr_info;
   Example *example;
   Constraint **constraints;
   Options *options;
   Distribution **local_distributions;
{
   Posterior *posteriors;
   static unsigned int sample_key = UNINITIALIZED_KEY + 1;
   Constraint *constraint;
   Split *split;
   int i;

   if (options->estimation_method == GAUSSIAN)
      error(prog_name, "cannot sample with gaussian method yet", TRUE);

   posteriors = initialize_posteriors(attr_info, constraints,
				      local_distributions, options);

   for (i = 0; i < attr_info->number; ++i)
   {
      constraint = constraints[i];
      while (constraint)
      {
	 split = constraint->split;
	 if (split->type == M_OF_N_SPLIT &&
	     split->type_specific.mofn.sample_key != sample_key)
	 {
	    if (constraint->branch)
	    {
               negated_satisfy_mofn_split(split, posteriors, attr_info,
					  local_distributions);
	    }
            else
	    {
               satisfy_mofn_split(split, posteriors, attr_info,
				  local_distributions);
	    }

	    split->type_specific.mofn.sample_key = sample_key;
	 }
	 constraint = constraint->next;
      }
   }
   set_attribute_values(example, attr_info, posteriors,
		        local_distributions, options);

   ++sample_key;

   free_posteriors(posteriors, attr_info);

   return(TRUE);
}


