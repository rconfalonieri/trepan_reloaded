#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "network-exp.h"
#include "tree.h"
#include "sample-exp.h"
#include "mofn-exp.h"

TreeNode *tree_root = NULL; /* for debugging purposes */

Distribution **get_local_distributions(node)
    TreeNode *node;
{
   while (node != NULL && node->distributions == NULL)
      node = node->parent;

   if (node == NULL)
      return (NULL);

   return (node->distributions);
}

ValueType get_class(example, attr_info, options)
    Example *example;
AttributeInfo *attr_info;
Options *options;
{
   ValueType class;

   if (options->use_oracle)
   {
      if (example->oracle.missing)
      {
         class.discrete = options->oracle(example, attr_info);
         return (class);
      }
      else
         return (example->oracle.value);
   }
   else
      return (example->values[attr_info->class_index].value);
}

void cache_oracle_classifications(ex_info, attr_info, options)
    ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
{
   int i;
   Example *example;

   if (attr_info->attributes[attr_info->class_index].type == VECTOR_ATTR)
      error(prog_name, "Oracle stuff doesn't support class vectors yet", TRUE);

   for (i = 0; i < ex_info->number; ++i)
   {
      example = &ex_info->examples[i];
      example->oracle.missing = FALSE;
      example->oracle.value.discrete = (*options->oracle)(example, attr_info);
   }
}

void print_split(split, attr_info, branch, stream)
    Split *split;
AttributeInfo *attr_info;
int branch;
FILE *stream;
{
   int index;
   Attribute *attr;
   char *temp_label;
   Member *member;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      index = Get_Nominal_Attr(split);
      attr = &attr_info->attributes[index];
      temp_label = attr->labels[branch];
      fprintf(stream, "%s = %s", attr->name, temp_label);
      //fprintf(stream, "%s", attr->name);
      break;
   case BOOLEAN_SPLIT:
      index = Get_Boolean_Attr(split);
      attr = &attr_info->attributes[index];
      if (attr->type == BOOLEAN_ATTR)
      {
         temp_label = branch ? "false" : "true";
         fprintf(stream, "%s = %s", attr->name, temp_label);
      }
      else
      {
         temp_label = branch ? "!=" : "=";
         fprintf(stream, "%s %s %s", attr->name, temp_label,
                 attr->labels[Get_Boolean_Value(split)]);
      }
      break;
   case M_OF_N_SPLIT:
      if (branch)
         fprintf(stream, "NOT ");
      fprintf(stream, "%d of {", split->type_specific.mofn.m);
      member = Get_Members(split);
      while (member)
      {
         if (member != Get_Members(split))
            fprintf(stream, ", ");
         attr = &attr_info->attributes[member->attribute];
         if (attr->type == BOOLEAN_ATTR)
         {
            temp_label = member->value.discrete ? "true" : "false";
            fprintf(stream, "%s=%s", attr->name, temp_label);
         }
         else if (attr->type == NOMINAL_ATTR)
         {
            fprintf(stream, "%s=%s", attr->name,
                    attr->labels[member->value.discrete]);
         }
         else if (attr->type == REAL_ATTR)
         {
            if (!member->negated)
               fprintf(stream, "%s <= %f", attr->name, member->value.real);
            else
               fprintf(stream, "%s > %f", attr->name, member->value.real);
         }

         member = member->next;
      }
      fprintf(stream, "}");
      break;
   case REAL_SPLIT:
      index = Get_Real_Attr(split);
      attr = &attr_info->attributes[index];
      temp_label = branch ? ">" : "<=";
      fprintf(stream, "%s %s %.6f", attr->name, temp_label,
              Get_Threshold(split));
      break;
   }
}

void print_splits(attr_info, list, stream)
    AttributeInfo *attr_info;
Split *list;
FILE *stream;
{
   int count = 0;

   printf("========== SPLIT LIST ==========\n\n");

   while (list)
   {
      ++count;
      print_split(list, attr_info, 0, stream);
      printf(" %f\n", list->gain);
      list = list->next;
   }

   printf("%d splits in list\n", count);
}

void free_split(split)
    Split *split;
{
   Member *member, *temp_mem;
   int i;

   if (split->type == M_OF_N_SPLIT)
   {
      member = Get_Members(split);
      while (member)
      {
         temp_mem = member;
         member = member->next;
         check_free((void *)temp_mem);
      }
   }

   for (i = 0; i < split->arity; ++i)
      check_free((void *)split->class_distr[i]);
   check_free((void *)split->class_distr);
   check_free((void *)split->branch_distr);
   check_free((void *)split);
}

void free_tree(node)
    TreeNode *node;
{
   int i;
   Split *split;

   if (node->type == INTERNAL)
   {
      split = Get_Split(node);
      for (i = 0; i < split->arity; ++i)
         free_tree(Get_Nth_Child(node, i));
      if (--split->reference_count == 0)
         free_split(split);
      check_free((void *)Get_Children(node));
      check_free((void *)Get_Probs(node));
   }

   check_free((void *)node->e_distribution);
   check_free((void *)node->s_distribution);
   check_free((void *)node);
}

void example_distribution(node, ex_info, attr_info, options, mask)
    TreeNode *node;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
float *mask;
{
   ValueType class;
   int i, j;
   int class_is_vector = ClassIsVector(attr_info);

   node->e_distribution = (float *)check_malloc(sizeof(float) *
                                                attr_info->num_classes);
   node->s_distribution = (float *)check_malloc(sizeof(float) *
                                                attr_info->num_classes);
   for (i = 0; i < attr_info->num_classes; ++i)
   {
      node->e_distribution[i] = 0.0;
      node->s_distribution[i] = 0.0;
   }

   for (i = 0; i < ex_info->number; ++i)
   {
      class = get_class(&ex_info->examples[i], attr_info, options);
      if (class_is_vector)
      {
         for (j = 0; j < attr_info->num_classes; ++j)
            node->e_distribution[j] += mask[i] * class.vector[j];
      }
      else
         node->e_distribution[class.discrete] += mask[i];
   }

   node->class = NO_CLASS;
   node->e_total = 0.0;
   node->s_total = 0.0;
   for (i = 0; i < attr_info->num_classes; ++i)
   {
      node->e_total += node->e_distribution[i];
      if (node->e_distribution[i] > 0.0)
      {
         if (node->class == NO_CLASS ||
             node->e_distribution[i] > node->e_distribution[node->class])
            node->class = i;
      }
   }
}

static void sample_distribution(node, number, attr_info, options)
    TreeNode *node;
int number;
AttributeInfo *attr_info;
Options *options;
{
   ValueType class;
   Example *example;
   int i, j;
   int class_is_vector = ClassIsVector(attr_info);
   int done = FALSE;

   node->s_total = (float)number;
   reset_sample_index();
   for (i = 0; i < number && done == FALSE; ++i)
   {
      example = get_sample_instance();
      if (example != NULL)
      {
         class = get_class(example, attr_info, options);
         if (class_is_vector)
         {
            for (j = 0; j < attr_info->num_classes; ++j)
               node->s_distribution[j] += class.vector[j];
         }
         else
            node->s_distribution[class.discrete] += 1.0;
      }
      else
         done = TRUE;
   }

   for (j = 0; j < attr_info->num_classes; ++j)
      if (Get_Class_Total(node, j) > 0.0)
      {
         if (node->class == NO_CLASS ||
             Get_Class_Total(node, j) > Get_Class_Total(node, node->class))
            node->class = j;
      }
}

static float possible_information(split)
    Split *split;
{
   float sum = 0.0;
   float info;
   int i;

   for (i = 0; i < split->arity; ++i)
   {
      if (split->branch_distr[i] != 0.0)
         sum += split->branch_distr[i] * Log2((double)split->branch_distr[i]);
   }

   if (split->missing != 0.0)
      sum += split->missing * Log2((double)split->missing);

   info = (split->total * Log2((double)split->total) - sum) / split->total;

   return (info);
}

static float base_information(split, num_classes)
    Split *split;
int num_classes;
{
   float sum = 0.0;
   float info;
   float known;
   float count;
   int i, j;

   known = split->total - split->missing;
   if (known == 0.0)
      return (0.0);

   for (i = 0; i < num_classes; ++i)
   {
      count = 0.0;
      for (j = 0; j < split->arity; ++j)
         count += split->class_distr[j][i];

      if (count != 0.0)
         sum += count * Log2((double)count);
   }

   info = (known * Log2((double)known) - sum) / known;

   return (info);
}

static float split_information(split, num_classes)
    Split *split;
int num_classes;
{
   int i, j;
   float info = 0.0;
   float sum = 0.0;

   if (split->total == split->missing)
      return (0.0);

   for (i = 0; i < split->arity; ++i)
   {
      if (split->branch_distr[i] != 0.0)
      {
         sum = 0.0;
         for (j = 0; j < num_classes; ++j)
            if (split->class_distr[i][j] != 0.0)
               sum += split->class_distr[i][j] *
                      Log2((double)split->class_distr[i][j]);

         info += split->branch_distr[i] *
                     Log2((double)split->branch_distr[i]) -
                 sum;
      }
   }

   info /= (split->total - split->missing);
   return (info);
}

/*
   Make sure at least 2 of the branches have at least `min_objects'
   assigned to them.
*/
int trivial_split(split, min_objects)
    Split *split;
float min_objects;
{
   int i;
   int count = 0;

   for (i = 0; i < split->arity; ++i)
      if (split->branch_distr[i] >= min_objects)
      {
         ++count;

         if (count == 2)
            return (FALSE);
      }

   return (TRUE);
}

/*
   This could use a smarter algorithm for handling missing values
   in m-of-n splits.
*/
int which_branch(split, example)
    Split *split;
Example *example;
{
   int attr;
   int value;
   float r_value;
   Member *member;
   int satisfied, unknown;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      attr = Get_Nominal_Attr(split);
      if (example->values[attr].missing)
         return (MISSING);
      return (example->values[attr].value.discrete);
   case M_OF_N_SPLIT:
      satisfied = 0;
      unknown = 0;
      member = Get_Members(split);
      while (member)
      {
         attr = member->attribute;
         if (!example->values[attr].missing)
         {
            if (member->type == BOOLEAN_ATTR || member->type == NOMINAL_ATTR)
            {
               value = member->value.discrete;
               if (value == example->values[attr].value.discrete)
                  ++satisfied;
            }
            else if (member->type == REAL_ATTR)
            {
               r_value = example->values[attr].value.real;
               if (!member->negated && r_value <= member->value.real)
                  ++satisfied;
               else if (member->negated && r_value > member->value.real)
                  ++satisfied;
            }

            if (satisfied >= Get_M(split))
               return (0);
         }
         else
            ++unknown;
         member = member->next;
      }

      /* May return MISSING when it can be determined that a split
	    is not satisfiable (because multiple unknowns may be for
	    one attribute).
	 */
      if (satisfied >= Get_M(split))
         return (0);
      else if (satisfied + unknown >= Get_M(split))
         return (MISSING);
      else
         return (1);
   case REAL_SPLIT:
      attr = Get_Real_Attr(split);
      if (example->values[attr].missing)
         return (MISSING);
      r_value = example->values[attr].value.real;
      if (r_value <= Get_Threshold(split))
         return (0);
      else
         return (1);
   case BOOLEAN_SPLIT:
      attr = Get_Boolean_Attr(split);
      if (example->values[attr].missing)
         return (MISSING);
      value = Get_Boolean_Value(split);
      if (value == example->values[attr].value.discrete)
         return (0);
      else
         return (1);
   default:
      error("System error", "bad split type in which_branch", TRUE);
   }
}

void reset_statistics(split, num_classes)
    Split *split;
int num_classes;
{
   int i, j;

   split->total = 0.0;
   split->missing = 0.0;
   split->gain = 0.0;
   for (i = 0; i < split->arity; ++i)
   {
      split->branch_distr[i] = 0.0;
      for (j = 0; j < num_classes; ++j)
         split->class_distr[i][j] = 0.0;
   }
}

void update_statistics(split, attr_info, example, class, weight)
    Split *split;
AttributeInfo *attr_info;
Example *example;
ValueType class;
float weight;
{
   int branch;
   int i;
   int class_is_vector = ClassIsVector(attr_info);

   split->total += weight;
   branch = which_branch(split, example);

   if (branch == MISSING)
   {
      split->missing += weight;
   }
   else
   {
      split->branch_distr[branch] += weight;
      if (class_is_vector)
      {
         for (i = 0; i < attr_info->num_classes; ++i)
            split->class_distr[branch][i] += weight * class.vector[i];
      }
      else
         split->class_distr[branch][class.discrete] += weight;
   }
}

static Split *put_split_back(list, element)
    Split *list;
Split *element;
{
   if (element->prev == NULL)
   {
      if (element->next != NULL)
         element->next->prev = element;
      else if (list != NULL)
         error(prog_name, "bad list elements in put_split_back", TRUE);

      return (element);
   }
   else
   {
      element->prev->next = element;

      if (element->next != NULL)
         element->next->prev = element;

      return (list);
   }
}

Split *add_split(list, element)
    Split *list;
Split *element;
{
   element->prev = NULL;
   element->next = list;
   if (list)
      list->prev = element;
   return (element);
}

static Split *remove_split(list, element)
    Split *list;
Split *element;
{
   if (element->next)
      element->next->prev = element->prev;

   if (element->prev != NULL)
      element->prev->next = element->next;
   else
      list = element->next;

   return (list);
}

float **make_masks(node, ex_info, parent)
    TreeNode *node;
ExampleInfo *ex_info;
float *parent;
{
   float **masks;
   int i;
   int ex;
   int branch;
   int number = node->type_specific.internal.split->arity;

   masks = (float **)check_malloc(sizeof(float *) * number);
   for (i = 0; i < number; ++i)
      masks[i] = (float *)check_malloc(sizeof(float) * ex_info->number);

   for (ex = 0; ex < ex_info->number; ++ex)
   {
      branch = which_branch(Get_Split(node), &ex_info->examples[ex]);

      for (i = 0; i < number; ++i)
      {
         if (branch == MISSING)
            masks[i][ex] = Get_Nth_Prob(node, i) * parent[ex];
         else if (branch == i)
            masks[i][ex] = parent[ex];
         else
            masks[i][ex] = 0.0;
      }
   }

   return (masks);
}

int trivial_split_when_sampling(split, ex_info, mask, options)
    Split *split;
ExampleInfo *ex_info;
float *mask;
Options *options;
{
   float *weight;
   int i;
   int ex;
   int branch;
   int count;

   weight = (float *)check_malloc(sizeof(float) * split->arity);
   for (i = 0; i < split->arity; ++i)
      weight[i] = 0.0;

   for (ex = 0; ex < ex_info->number; ++ex)
   {
      branch = which_branch(split, &ex_info->examples[ex]);
      if (branch == MISSING)
      {
         for (i = 0; i < split->arity; ++i)
            weight[i] += mask[ex] * split->branch_distr[i] /
                         (split->total - split->missing);
      }
      else
         weight[branch] += mask[ex];

      count = 0;
      for (i = 0; i < split->arity; ++i)
         if (weight[i] >= options->min_objects)
         {
            ++count;
            if (count == 2)
            {
               check_free((void *)weight);
               return (FALSE);
            }
         }
   }

   check_free((void *)weight);

   return (TRUE);
}

static void free_masks(masks, number) float **masks;
int number;
{
   int i;

   for (i = 0; i < number; ++i)
      check_free((void *)masks[i]);

   check_free((void *)masks);
}

void free_unused_splits(split)
    Split *split;
{
   Split *temp_split;

   while (split)
   {
      temp_split = split;
      split = split->next;
      temp_split->next = temp_split->prev = NULL;
      if (--temp_split->reference_count == 0)
         free_split(temp_split);
   }
}

Split *get_new_split(type, arity, attr_info)
    SplitType type;
int arity;
AttributeInfo *attr_info;
{
   int i;
   Split *split;

   split = (Split *)check_malloc(sizeof(Split));

   split->type = type;
   split->arity = arity;
   split->reference_count = 1;
   split->can_use = TRUE;
   split->next = split->prev = NULL;
   split->frequency = 0.0;

   /* allocate & initialize distribution information */
   split->branch_distr = (float *)check_malloc(sizeof(float) * arity);
   split->class_distr = (float **)check_malloc(sizeof(float *) * arity);
   for (i = 0; i < arity; ++i)
   {
      split->class_distr[i] =
          (float *)check_malloc(sizeof(float) * attr_info->num_classes);
   }

   return (split);
}

static Split *make_real_valued_splits(attr_info, ex_info, example_mask,
                                      options, constraints, index, list)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *example_mask;
Options *options;
Constraint **constraints;
int index;
Split *list;
{
   int num_candidates;
   Order *candidates;
   Example *example;
   ValueType class;
   int class_index = attr_info->class_index;
   int low_index, high_index;
   int low_class;
   Split *split;
   int n = 0;
   int added = 0;
   int i;

   if (ClassIsVector(attr_info))
   {
      for (i = 0; i < ex_info->number; ++i)
      {
         example = &ex_info->examples[i];
         if (example_mask[i] != 0.0 && !example->values[index].missing)
         {
            split = get_new_split(REAL_SPLIT, 2, attr_info);
            split->type_specific.real.attribute = index;
            split->type_specific.real.threshold =
                example->values[index].value.real;
            list = add_split(list, split);
         }
      }
      return (list);
   }

   num_candidates = Max(ex_info->number, options->min_sample);
   candidates = (Order *)check_malloc(sizeof(Order) * num_candidates);

   for (i = 0; i < ex_info->number; ++i)
   {
      example = &ex_info->examples[i];
      if (example_mask[i] != 0.0 && !example->values[index].missing)
      {
         candidates[n].value = example->values[index].value.real;
         candidates[n].index = example->values[class_index].value.discrete;
         ++n;
      }
   }

   /* Now do sampling if necessary */
   /*
   if (options->min_sample)
   {
      example = check_malloc(sizeof(Example));
      example->oracle.missing = TRUE;
      example->values = (Value *)
                           check_malloc(sizeof(Value) * attr_info->number);
      for ( ; n < options->min_sample; ++n)
      {
         sample(attr_info, example, constraints, options);
         class = get_class(example, attr_info, options);
         candidates[n].value = example->values[index].value.real;
         candidates[n].index = class.discrete;
      }
      check_free((void *) example->values);
      check_free((void *) example);
   }
*/

   qsort((void *)candidates, (size_t)n, sizeof(Order), order_compare);

   low_index = 0;
   do
   {
      low_class = candidates[low_index].index;
      high_index = low_index + 1;
      while (high_index < n &&
             candidates[high_index].value == candidates[low_index].value)
      {
         if (candidates[high_index].index != low_class)
            low_class = MIXED_CLASS;
         ++high_index;
      }

      if (high_index < n && low_class != candidates[high_index].index)
      {
         split = get_new_split(REAL_SPLIT, 2, attr_info);
         split->type_specific.real.attribute = index;

         /* putting threshold between two values works better for sampling */
         split->type_specific.real.threshold = (candidates[low_index].value +
                                                candidates[high_index].value) /
                                               2.0;
         /* for debugging */
         split->gain = 0.0;
         //added by roberto
         if (options->use_ontology)
         {
            Attribute attribute = attr_info->attributes[i];
            split->attribute_is_in_ontology = attribute.is_in_ontology;
            if (attribute.frequency>0 && attribute.frequency<1)
               // printf("MAKE REAL SPLIT %f",attribute.frequency);
            // else 
            //    printf("MAKE REAL SPLIT - STRANGE STUFF %f",attribute.frequency);

            split->frequency = attribute.frequency;
            //split->attribute_value_is_in_ontology = attribute->value_is_in_ontology[j];
         }
         list = add_split(list, split);
         ++added;
      }
      low_index = high_index;
   } while (high_index < n);

   check_free((void *)candidates);

   /*
   printf("\tadded %d splits for attribute %s\n", added,
	  attr_info->attributes[index].name);
*/

   return (list);
}

static Split *add_real_valued_splits(attr_info, ex_info, example_mask, options,
                                     constraints, list)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *example_mask;
Options *options;
Constraint **constraints;
Split *list;
{
   Attribute *attribute;
   int i;

   for (i = attr_info->number - 1; i >= 0; --i)
      if (i != attr_info->class_index)
      {
         attribute = &attr_info->attributes[i];
         if (attribute->type == REAL_ATTR && attribute->relevant)
         {
            list = make_real_valued_splits(attr_info, ex_info, example_mask,
                                           options, constraints, i, list);
         }
      }

   return (list);
}

static Split *make_candidate_splits(attr_info, options)
    AttributeInfo *attr_info;
Options *options;
{
   Split *list = NULL;
   Split *split;
   Attribute *attribute;
   int i, j;

   for (i = attr_info->number - 1; i >= 0; --i)
   {
      attribute = &attr_info->attributes[i];
      if (i != attr_info->class_index && attribute->relevant)
      {
         if (attribute->type == NOMINAL_ATTR)
         {
            if (options->split_search_method == BEAM)
            {
               for (j = 0; j < attribute->num_values; ++j)
               {
                  split = get_new_split(BOOLEAN_SPLIT, 2, attr_info);
                  split->type_specific.boolean.attribute = i;
                  split->type_specific.boolean.value = j;
                  split->type_specific.boolean.bool_attr = FALSE;

                  //added by roberto
                  if (options->use_ontology)
                  {
                     split->frequency = attribute->frequency;
                     printf("attribute->frequency %f",split->frequency);
                     if (attribute->is_in_ontology == 1) {
                        split->attribute_is_in_ontology = TRUE;
                        // split->frequency = attribute->frequency;
                     }
                     else {
                        split->attribute_is_in_ontology = FALSE;
                        // split->frequency = attribute->frequency;
                     }
                     // split->attribute_is_in_ontology = attribute->is_in_ontology;
                     if (attribute->value_is_in_ontology[j] == 1) {
                        attribute->value_is_in_ontology[j] = TRUE;
                     }
                     else {
                        attribute->value_is_in_ontology[j] = FALSE;
                     // split->attribute_value_is_in_ontology = attribute->value_is_in_ontology[j];
                     }
                  }
                  list = add_split(list, split);
               }
            }
            else
            {
               split = get_new_split(NOMINAL_SPLIT, attribute->num_values,
                                     attr_info);
               split->type_specific.nominal.attribute = i;
               //added by roberto
               if (options->use_ontology)
               {
                  split->attribute_is_in_ontology = attribute->is_in_ontology;
                  split->frequency = attribute->frequency;
                  //split->attribute_value_is_in_ontology = attribute->value_is_in_ontology[j];
               }
               list = add_split(list, split);
            }
         }
         else if (attribute->type == BOOLEAN_ATTR)
         {
            split = get_new_split(BOOLEAN_SPLIT, 2, attr_info);
            split->type_specific.boolean.attribute = i;
            split->type_specific.boolean.value = 1;
            split->type_specific.boolean.bool_attr = TRUE;
            //added by roberto
            if (options->use_ontology)
            {
               split->attribute_is_in_ontology = attribute->is_in_ontology;
               split->frequency = attribute->frequency;
               //split->attribute_value_is_in_ontology = attribute->value_is_in_ontology[j];
            }
            list = add_split(list, split);
         }
      }
   }

   return (list);
}

void print_constraint(constraint, attr_info)
    Constraint *constraint;
AttributeInfo *attr_info;
{
   Attribute *attribute;
   int value;
   float threshold;
   char *label;

   switch (constraint->split->type)
   {
   case NOMINAL_SPLIT:
      attribute = &attr_info->attributes[Get_Nominal_Attr(constraint->split)];
      value = constraint->branch;
      printf("\t%s = %s\n", attribute->name, attribute->labels[value]);
      break;
   case M_OF_N_SPLIT:
      attribute = &attr_info->attributes[constraint->member->attribute];
      if (attribute->type == BOOLEAN_ATTR)
      {
         label = constraint->member->value.discrete ? "true" : "false";
         if (constraint->branch)
            printf("\tmofn(%s != %s)\n", attribute->name, label);
         else
            printf("\tmofn(%s = %s)\n", attribute->name, label);
      }
      else if (attribute->type == NOMINAL_ATTR)
      {
         value = constraint->member->value.discrete;
         label = attribute->labels[value];
         if (constraint->branch)
            printf("\tmofn(%s != %s)\n", attribute->name, label);
         else
            printf("\tmofn(%s = %s)\n", attribute->name, label);
      }
      else if (attribute->type == REAL_ATTR)
      {
         threshold = constraint->member->value.real;
         if (constraint->branch == (int)constraint->member->negated)
            printf("\tmofn(%s <= %f)\n", attribute->name, threshold);
         else
            printf("\tmofn(%s > %f)\n", attribute->name, threshold);
      }
      break;
   case REAL_SPLIT:
      attribute = &attr_info->attributes[Get_Real_Attr(constraint->split)];
      threshold = Get_Threshold(constraint->split);
      if (constraint->branch)
         printf("\t%s > %f\n", attribute->name, threshold);
      else
         printf("\t%s <= %f\n", attribute->name, threshold);
      break;
   case BOOLEAN_SPLIT:
      attribute = &attr_info->attributes[Get_Boolean_Attr(constraint->split)];
      if (attribute->type == BOOLEAN_ATTR)
      {
         label = (constraint->branch) ? "false" : "true";
         printf("\t%s = %s\n", attribute->name, label);
      }
      else
      {
         label = attribute->labels[Get_Boolean_Value(constraint->split)];
         if (constraint->branch)
            printf("\t%s != %s\n", attribute->name, label);
         else
            printf("\t%s = %s\n", attribute->name, label);
      }
      break;
   }
}

void print_constraints(constraints, attr_info)
    Constraint **constraints;
AttributeInfo *attr_info;
{
   Constraint *constraint;
   int i;

   for (i = 0; i < attr_info->number; ++i)
      if (constraints[i] != NULL)
      {
         printf("%s:\n", attr_info->attributes[i].name);
         constraint = constraints[i];
         while (constraint)
         {
            print_constraint(constraint, attr_info);
            constraint = constraint->next;
         }
      }
}

void unset_constraint(split, constraints)
    Split *split;
Constraint **constraints;
{
   int attribute;
   Constraint *temp, *prev;
   Member *member;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      attribute = Get_Nominal_Attr(split);
      prev = NULL;
      temp = constraints[attribute];
      while (temp->split != split)
      {
         prev = temp;
         temp = temp->next;
      }
      if (prev)
         prev->next = temp->next;
      else
         constraints[attribute] = temp->next;
      check_free((void *)temp);
      break;
   case M_OF_N_SPLIT:
      member = Get_Members(split);
      while (member)
      {
         attribute = member->attribute;
         prev = NULL;
         temp = constraints[attribute];
         while (temp != NULL)
         {
            if (temp->split == split)
            {
               if (prev)
                  prev->next = temp->next;
               else
                  constraints[attribute] = temp->next;
               check_free((void *)temp);
               temp = (prev == NULL) ? constraints[attribute] : prev->next;
            }
            else
            {
               prev = temp;
               temp = temp->next;
            }
         }
         member = member->next;
      }
      break;
   case REAL_SPLIT:
      attribute = Get_Real_Attr(split);
      prev = NULL;
      temp = constraints[attribute];
      while (temp->split != split)
      {
         prev = temp;
         temp = temp->next;
      }
      if (prev)
         prev->next = temp->next;
      else
         constraints[attribute] = temp->next;
      check_free((void *)temp);
      break;
   case BOOLEAN_SPLIT:
      attribute = Get_Boolean_Attr(split);
      prev = NULL;
      temp = constraints[attribute];
      while (temp->split != split)
      {
         prev = temp;
         temp = temp->next;
      }
      if (prev)
         prev->next = temp->next;
      else
         constraints[attribute] = temp->next;
      check_free((void *)temp);
      break;
   }
}

void set_constraint(split, branch, constraints)
    Split *split;
int branch;
Constraint **constraints;
{
   int attribute;
   Constraint *new_one;
   Member *member;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      attribute = Get_Nominal_Attr(split);
      new_one = (Constraint *)check_malloc(sizeof(Constraint));
      new_one->split = split;
      new_one->branch = branch;
      new_one->next = constraints[attribute];
      constraints[attribute] = new_one;
      break;
   case M_OF_N_SPLIT:
      member = Get_Members(split);
      while (member)
      {
         attribute = member->attribute;
         new_one = (Constraint *)check_malloc(sizeof(Constraint));
         new_one->split = split;
         new_one->branch = branch;
         new_one->member = member;
         new_one->next = constraints[attribute];
         constraints[attribute] = new_one;
         member = member->next;
      }
      break;
   case REAL_SPLIT:
      attribute = Get_Real_Attr(split);
      new_one = (Constraint *)check_malloc(sizeof(Constraint));
      new_one->split = split;
      new_one->branch = branch;
      new_one->next = constraints[attribute];
      constraints[attribute] = new_one;
      break;
   case BOOLEAN_SPLIT:
      attribute = Get_Boolean_Attr(split);
      new_one = (Constraint *)check_malloc(sizeof(Constraint));
      new_one->split = split;
      new_one->branch = branch;
      new_one->next = constraints[attribute];
      constraints[attribute] = new_one;
      break;
   }
}

static void make_leaf(node, parent, options, attr_info, constraints,
                      covered, stop_reason)
    TreeNode *node;
TreeNode *parent;
Options *options;
AttributeInfo *attr_info;
Constraint **constraints;
char covered;
StopReason stop_reason;
{
   node->type = LEAF;
   node->type_specific.leaf.covered = covered;
   node->type_specific.leaf.stop_reason = stop_reason;

   if (node->class == NO_CLASS)
      node->class = parent->class;
}

static int sampling_stop(node, options, attr_info, constraints)
    TreeNode *node;
Options *options;
AttributeInfo *attr_info;
Constraint **constraints;
{
   Example example;
   float prop;
   int needed;
   int success;
   Distribution **local_distributions;
   ValueType class;
   int instance = 0;
   int i;

   if (!options->oracle)
      return (FALSE);

   prop = Get_Predicted_Class_Total(node) / Get_Total(node);
   if (prop != 1.0)
      return (FALSE);

   if (node->class == NO_CLASS)
      node->class = 0;

   needed = (int)(options->stop_z * options->stop_z *
                  (1.0 - options->stop_epsilon) / options->stop_epsilon);

   if (Get_Total(node) > needed)
      return (TRUE);

   example.oracle.missing = TRUE;
   example.values = (Value *)check_malloc(sizeof(Value) * attr_info->number);
   local_distributions = (options->distribution_type == LOCAL) ? get_local_distributions(node) : NULL;

   for (i = (int)Get_Total(node); i < needed; ++i)
   {
      success = sample(attr_info, &example, constraints, options,
                       local_distributions);
      if (success)
      {
         class = get_class(&example, attr_info, options);
         check_sample(attr_info, tree_root, node, &example, constraints,
                      instance);
         ++instance;

         node->s_distribution[class.discrete] += 1.0;
         node->s_total += 1.0;
         if (Get_Class_Total(node, class.discrete) >
             Get_Predicted_Class_Total(node))
            node->class = class.discrete;

         prop = Get_Predicted_Class_Total(node) / Get_Total(node);
      }

      if (!success || prop != 1.0)
      {
         check_free((void *)example.values);
         return (FALSE);
      }
   }

   check_free((void *)example.values);
   return (TRUE);
}

static int children_predict_same(node)
    TreeNode *node;
{
   Split *split;
   TreeNode *child;
   int i;

   split = Get_Split(node);
   for (i = 0; i < split->arity; ++i)
   {
      child = Get_Nth_Child(node, i);
      if (child->type != LEAF || child->class != node->class)
         return (FALSE);
   }

   return (TRUE);
}

static void validation_prune(node, best)
    TreeNode *node;
int best;
{
   int num_children;
   int i;

   if (node->type == INTERNAL)
   {
      num_children = node->type_specific.internal.split->arity;
      if (node->number > best)
      {
         for (i = 0; i < num_children; ++i)
            free_tree(Get_Nth_Child(node, i));

         node->type = LEAF;
         node->type_specific.leaf.covered = FALSE;
         node->type_specific.leaf.stop_reason = S_GLOBAL;
      }
      else
      {
         for (i = 0; i < num_children; ++i)
            validation_prune(Get_Nth_Child(node, i), best);
      }
   }
}

static void unnecessary_node_prune(node)
    TreeNode *node;
{
   int num_children;
   int i;

   if (node->type == INTERNAL)
   {
      num_children = node->type_specific.internal.split->arity;
      for (i = 0; i < num_children; ++i)
      {
         unnecessary_node_prune(Get_Nth_Child(node, i));
      }

      if (children_predict_same(node))
      {
         for (i = 0; i < num_children; ++i)
            free_tree(Get_Nth_Child(node, i));

         node->type = LEAF;
         node->type_specific.leaf.covered = FALSE;
         node->type_specific.leaf.stop_reason = S_SIMPLIFIED;
      }
   }
}

static float split_ORT(attr_info, split)
    AttributeInfo *attr_info;
Split *split;
{
   float dot_product = 0.0;
   float magnitude_0 = 0.0;
   float magnitude_1 = 0.0;
   float ORT;
   int i;

   if (split->arity != 2)
      error("System error", "cannot use ORT measure for non-binary splits",
            TRUE);

   for (i = 0; i < attr_info->num_classes; ++i)
   {
      magnitude_0 += split->class_distr[0][i] * split->class_distr[0][i];
      magnitude_1 += split->class_distr[1][i] * split->class_distr[1][i];
      dot_product += split->class_distr[0][i] * split->class_distr[1][i];
   }

   magnitude_0 = sqrt((double)magnitude_0);
   magnitude_1 = sqrt((double)magnitude_1);

   if (magnitude_0 == 0.0 || magnitude_1 == 0.0)
      return (0.0);

   ORT = 1.0 - (dot_product / (magnitude_0 * magnitude_1));

   return (ORT);
}

void evaluate_splits(attr_info, ex_info, example_mask, options, splits)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *example_mask;
Options *options;
Split *splits;
{
   Example *example;
   Split *split;
   ValueType class;
   float info, base_info;
   float avg_gain, possible_info;
   int counted;
   int done = FALSE;
   int i;
   int ex;

   split = splits;
   while (split)
   {
      if (split->can_use)
         reset_statistics(split, attr_info->num_classes);
      split = split->next;
   }

   for (i = 0, ex = 0; i < ex_info->number; ++i)
      if (example_mask[i] != 0.0)
      {
         ++ex;
         class = get_class(&ex_info->examples[i], attr_info, options);
         split = splits;
         while (split)
         {
            if (split->can_use)
               update_statistics(split, attr_info, &ex_info->examples[i], class,
                                 example_mask[i]);
            split = split->next;
         }
      }

   if (options->do_sampling && options->min_sample)
   {
      reset_sample_index();
      for (; ex < options->min_sample && done == FALSE; ++ex)
      {
         example = get_sample_instance();
         if (example != NULL)
         {
            class = get_class(example, attr_info, options);
            split = splits;
            while (split)
            {
               if (split->can_use)
                  update_statistics(split, attr_info, example, class, 1.0);
               split = split->next;
            }
         }
         else
            done = TRUE;
      }
   }

   if (options->split_method == GAIN || options->split_method == GAIN_RATIO)
   {
      avg_gain = 0.0;
      counted = 0;
      split = splits;
      while (split)
      {
         if (split->can_use)
         {
            base_info = base_information(split, attr_info->num_classes);
            info = split_information(split, attr_info->num_classes);
            split->gain = (split->total - split->missing) / split->total *
                          (base_info - info);

            if (split->gain > -EPSILON &&
                split->arity < 0.3 * ex_info->number)
            {
               avg_gain += split->gain;
               ++counted;
            }
            // roberto: here we can add the penalty for not being in the ontology
            if (options->use_ontology)
            {  
               float inf_content = 0.0;
               if (split->frequency>0 && split->frequency<1) {
                  printf("\nevaluate_splits %f",split->frequency);
                  inf_content = split->frequency;
               }
               else if (split->frequency==0) {
                  inf_content = 0.0001;
               }
               else if (split->frequency==1) {
                  inf_content = 1;
               }
               // else
               //    printf("evaluate_splits STRANGE STUFF %f",split->frequency);
               // if (split->attribute_is_in_ontology == 0)
               // {
                  // split->gain = (1-inf_content)*split->gain;
               
               printf("\n----------------------------");
               printf("\nevaluate_splits: inf_content %f",split->frequency);
               printf("\nevaluate_splits: gain %f",split->gain);
               split->gain = inf_content*split->gain;
               printf("\nevaluate_splits: new gain %f",split->gain);
               printf("\n----------------------------");
               // }
            }
         }
         split = split->next;
      }

      if (options->split_method == GAIN_RATIO)
      {
         avg_gain = counted ? avg_gain / counted : 1E6;

         split = splits;
         while (split)
         {
            if (split->can_use)
            {
               possible_info = possible_information(split);
               if (split->gain >= avg_gain - EPSILON &&
                   possible_info > EPSILON)
                  split->gain /= possible_info;
            }

            split = split->next;
         }
      }
   }
   else if (options->split_method == ORT)
   {
      split = splits;
      while (split)
      {
         if (split->can_use)
            split->gain = split_ORT(attr_info, split);
         split = split->next;
      }
   }
}

Split *pick_split(options, splits, ex_info, example_mask)
    Options *options;
Split *splits;
ExampleInfo *ex_info;
float *example_mask;
{
   Split *split, *best_split;

   best_split = NULL;
   split = splits;
   while (split)
   {
      if (split->can_use && !trivial_split(split, options->min_objects) &&
          (!options->do_sampling ||
           !trivial_split_when_sampling(split, ex_info, example_mask, options)))
      {
         if (!best_split || split->gain > best_split->gain)
            best_split = split;
      }

      split = split->next;
   }

   if (best_split && best_split->gain == 0.0)
      best_split = NULL;

   return (best_split);
}

static Split *make_split(attr_info, ex_info, example_mask, options, splits)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *example_mask;
Options *options;
Split *splits;
{
   Split *best_split, *look_split;
   float best_gain;

   evaluate_splits(attr_info, ex_info, example_mask, options, splits);

   printf("make_split: start: print_splits");
   print_splits(attr_info, splits, stdout);
   printf("make_split: print_splits: end");

   best_split = pick_split(options, splits, ex_info, example_mask);

   /*
   if (options->split_search_method == LOOKAHEAD)
   {
      best_gain = (best_split != NULL) ? best_split->gain : 0.0;
      look_split = lookahead_make_split(attr_info, ex_info, example_mask,
					options, splits);
      if (look_split && look_split->gain > best_gain)
	 best_split = look_split;
   }
*/

   return (best_split);
}

static void unset_node_state(node, constraints)
    TreeNode *node;
Constraint **constraints;
{
   Split *split;

   while (node->parent)
   {
      node = node->parent;
      split = Get_Split(node);
      split->can_use = TRUE;
      unset_constraint(split, constraints);
   }
}

static void set_node_state(node, constraints)
    TreeNode *node;
Constraint **constraints;
{
   Split *split;
   int branch;

   while (node->parent)
   {
      branch = node->parent_branch;
      node = node->parent;
      split = Get_Split(node);
      split->can_use = FALSE;
      set_constraint(split, branch, constraints);
   }
}

static float calculate_node_priority(node)
    TreeNode *node;
{
   float priority;
   int branch;

   if (node->type != LEAF)
      error("System error", "non-leaf passed to calculate_node_priority", TRUE);

   priority = 1.0 - Get_Proportion(node);

   while (node->parent)
   {
      branch = node->parent_branch;
      node = node->parent;
      priority *= Get_Nth_Prob(node, branch);
   }

   return (priority);
}

static void free_queue(queue)
    PriorityQueue *queue;
{
   PriorityQueue *temp;

   while (queue != NULL)
   {
      temp = queue;
      queue = queue->next;
      check_free((void *)temp->mask);
      check_free((void *)temp);
   }
}

static PriorityQueue *insert_node_into_queue(node, priority, mask, queue)
    TreeNode *node;
float priority;
float *mask;
PriorityQueue *queue;
{
   PriorityQueue *new_one;
   PriorityQueue *current, *prev;

   new_one = (PriorityQueue *)check_malloc(sizeof(PriorityQueue));
   new_one->node = node;
   new_one->priority = priority;
   new_one->mask = mask;
   new_one->next = NULL;

   // printf("INSERTING NODE WITH PRIORITY %.3f INTO QUEUE\n", priority);

   current = queue;
   prev = NULL;
   while (current && current->priority >= new_one->priority)
   {
      prev = current;
      current = current->next;
   }

   if (prev)
   {
      prev->next = new_one;
      new_one->next = current;
   }
   else
   {
      queue = new_one;
      new_one->next = current;
   }

   return (queue);
}

static PriorityQueue *remove_node_from_queue(queue, node, mask)
    PriorityQueue *queue;
TreeNode **node;
float **mask;
{
   PriorityQueue *temp;

   if (queue)
   {
      // printf("REMOVING NODE WITH PRIORITY %.3f FROM QUEUE\n\n", queue->priority);
      *node = queue->node;
      *mask = queue->mask;
      temp = queue;
      queue = queue->next;
      check_free((void *)temp);
   }
   else
   {
      *node = NULL;
      *mask = NULL;
   }

   return (queue);
}

static PriorityQueue *expand_tree_node(node, ex_info, example_mask, splits,
                                       attr_info, constraints, options, queue)
    TreeNode *node;
ExampleInfo *ex_info;
float *example_mask;
Split *splits;
AttributeInfo *attr_info;
Constraint **constraints;
Options *options;
PriorityQueue *queue;
{
   Split *discrete_splits;
   Split *best_split;
   TreeNode *child;
   float **children_masks;
   float priority;
   int samples_needed;
   Distribution **local_distributions;
   Distribution **ancestor_distributions;
   int i;

   discrete_splits = splits;
   splits = add_real_valued_splits(attr_info, ex_info, example_mask,
                                   options, constraints, splits);

   if (options->split_search_method == BEAM)
   {
      best_split = ID2_of_3_beam(attr_info, ex_info, example_mask, constraints,
                                 options, splits);
   }
   else
   {
      best_split = make_split(attr_info, ex_info, example_mask, options,
                              splits);
   }

   if (!best_split)
   {
      node->type_specific.leaf.stop_reason = S_NO_PICK_SPLIT;
      return (queue);
   }

   node->type = INTERNAL;
   node->type_specific.internal.split = best_split;
   ++best_split->reference_count;

   if (discrete_splits != splits)
   {
      if (discrete_splits)
      {
         discrete_splits->prev->next = NULL;
         discrete_splits->prev = NULL;
      }
      free_unused_splits(splits);
      splits = discrete_splits;
   }

   node->type_specific.internal.probs =
       (float *)check_malloc(sizeof(float) * best_split->arity);
   for (i = 0; i < best_split->arity; ++i)
      node->type_specific.internal.probs[i] = best_split->branch_distr[i] /
                                              (best_split->total - best_split->missing);

   children_masks = make_masks(node, ex_info, example_mask);

   node->type_specific.internal.children =
       (TreeNode **)check_malloc(sizeof(TreeNode *) * best_split->arity);

   /* for debugging */
   for (i = 0; i < best_split->arity; ++i)
      node->type_specific.internal.children[i] = NULL;

   for (i = 0; i < best_split->arity; ++i)
   {
      node->type_specific.internal.children[i] = (TreeNode *)
          check_malloc(sizeof(TreeNode));
      child = node->type_specific.internal.children[i];
      child->parent = node;
      child->number = -1;
      child->parent_branch = i;
      child->distributions = NULL;
      example_distribution(child, ex_info, attr_info, options,
                           children_masks[i]);

      set_constraint(best_split, i, constraints);

      if (options->do_sampling)
      {
         if (options->distribution_type == LOCAL &&
             child->e_total >= options->min_estimation_sample)
         {
            ancestor_distributions = get_local_distributions(child);
            child->distributions = determine_local_distributions(attr_info,
                                                                 ex_info, children_masks[i], constraints,
                                                                 ancestor_distributions, options);
         }

         samples_needed = options->min_sample - (int)child->e_total;
         if (samples_needed > 0)
         {
            local_distributions = (options->distribution_type == LOCAL) ? get_local_distributions(child) : NULL;
            get_new_sample(attr_info, constraints, options, samples_needed,
                           local_distributions, child);
            sample_distribution(child, samples_needed, attr_info, options);
         }
      }

      make_leaf(child, node, options, attr_info, constraints, FALSE, S_GLOBAL);

      if (options->do_sampling && options->sampling_stop &&
          sampling_stop(child, options, attr_info, constraints))
      {
         child->type_specific.leaf.stop_reason = S_SAMPLING;
         check_free((void *)children_masks[i]);
      }
      else if (Get_Total(child) < 2 * options->min_objects)
      {
         child->type_specific.leaf.stop_reason = S_MIN_OBJECTS;
         check_free((void *)children_masks[i]);
      }
      else if (Get_Total_Error(child) == 0.0)
      {
         child->type_specific.leaf.stop_reason = S_ERROR;
         check_free((void *)children_masks[i]);
      }
      else if ((priority = calculate_node_priority(child)) == 0.0)
      {
         child->type_specific.leaf.stop_reason = S_ZERO_BRANCH_PROB;
         check_free((void *)children_masks[i]);
      }
      else
      {
         priority = calculate_node_priority(child);
         queue = insert_node_into_queue(child, priority, children_masks[i],
                                        queue);
      }

      unset_constraint(best_split, constraints);
   }

   check_free((void *)children_masks);

   return (queue);
}

float measure_fidelity(tree, ex_info, attr_info, options, matrix)
    TreeNode *tree;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
int **matrix;
{
   int **confusion_matrix;
   int correct;
   float fidelity;
   int (*saved_oracle)();
   int saved_use_oracle_flag;
   int i;

   if (matrix == NULL)
      confusion_matrix = get_confusion_matrix(attr_info->num_classes);
   else
      confusion_matrix = matrix;

   saved_oracle = options->oracle;
   saved_use_oracle_flag = options->use_oracle;
   register_network_oracle(&options->oracle);
   options->use_oracle = TRUE;

   classify_using_tree(tree, ex_info, attr_info, options, confusion_matrix,
                       NULL, FALSE);

   for (i = 0, correct = 0; i < attr_info->num_classes; ++i)
      correct += confusion_matrix[i][i];

   options->oracle = saved_oracle;
   options->use_oracle = saved_use_oracle_flag;

   if (matrix == NULL)
      free_confusion_matrix(confusion_matrix, attr_info->num_classes);

   fidelity = 1.0 * correct / ex_info->number;
   return (fidelity);
}

static float measure_accuracy(tree, ex_info, attr_info, options, matrix)
    TreeNode *tree;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
int **matrix;
{
   int **confusion_matrix;
   int correct;
   float accuracy;
   int (*saved_oracle)();
   int saved_use_oracle_flag;
   int i;

   if (matrix == NULL)
      confusion_matrix = get_confusion_matrix(attr_info->num_classes);
   else
      confusion_matrix = matrix;

   saved_oracle = options->oracle;
   saved_use_oracle_flag = options->use_oracle;
   options->oracle = NULL;
   options->use_oracle = FALSE;

   classify_using_tree(tree, ex_info, attr_info, options, confusion_matrix,
                       NULL, FALSE);

   for (i = 0, correct = 0; i < attr_info->num_classes; ++i)
      correct += confusion_matrix[i][i];

   options->oracle = saved_oracle;
   options->use_oracle = saved_use_oracle_flag;

   if (matrix == NULL)
      free_confusion_matrix(confusion_matrix, attr_info->num_classes);

   accuracy = 1.0 * correct / ex_info->number;
   return (accuracy);
}

static int compute_tree_leaves_nr(tree, attr_info)
TreeNode *tree;
AttributeInfo *attr_info;
{
   TreeStats stats;
   float NL = 0.0;
   int size;
   int i;
   float covered = 0.0;
   float correctness = 0.0;

   stats.leaves = 0;
   stats.total_branches = 0;
   stats.internal = 0;
   stats.values = 0;
   stats.rules = check_malloc(sizeof(int) * attr_info->num_classes);
   stats.antes = check_malloc(sizeof(int) * attr_info->num_classes);
   for (i = 0; i < attr_info->num_classes; ++i)
   {
      stats.rules[i] = 0;
      stats.antes[i] = 0;
   }

   tree_stats(tree, &stats, 0);

   check_free((void *)stats.rules);
   check_free((void *)stats.antes);

   return stats.leaves;

}

static int compute_tree_branches_nr(tree, attr_info)
TreeNode *tree;
AttributeInfo *attr_info;
{
   TreeStats stats;
   float NL = 0.0;
   int size;
   int i;
   float covered = 0.0;
   float correctness = 0.0;

   stats.leaves = 0;
   stats.total_branches = 0;
   stats.internal = 0;
   stats.values = 0;
   stats.rules = check_malloc(sizeof(int) * attr_info->num_classes);
   stats.antes = check_malloc(sizeof(int) * attr_info->num_classes);
   for (i = 0; i < attr_info->num_classes; ++i)
   {
      stats.rules[i] = 0;
      stats.antes[i] = 0;
   }

   tree_stats(tree, &stats, 0);

   check_free((void *)stats.rules);
   check_free((void *)stats.antes);

   return stats.total_branches;

}


static float measure_comprehensibility_based_on_leaves(leaves_nr)
// TreeNode *tree;
// AttributeInfo *attr_info;
{
   // if (!tree)
   //    error(prog_name, "measure_comprehensibility_based_on_leaves fatal error tree is null", TRUE);

   // float leaves_nr = compute_tree_leaves_nr(tree,attr_info);
   float comprehensibility = 0.166f * leaves_nr + 1.0f;
   return (comprehensibility);
}

static float measure_comprehensibility_based_on_branches(branches_nr)
// TreeNode *tree;
{

   // float branches_nr = 0;
   // branches_nr = compute_tree_branches_nr(tree,attr_info);
   float comprehensibility = 0.04f * branches_nr + 1.0f;
   return (comprehensibility);
}

/*
	is proportion information accurately maintained for leaves
	test stopping criteria before putting root on queue
*/
static TreeNode *best_first(train_examples, train_mask, splits, attr_info,
                            constraints, options, size, test_examples,
                            validation_examples, pfname)
    ExampleInfo *train_examples;
float *train_mask;
Split *splits;
AttributeInfo *attr_info;
Constraint **constraints;
Options *options;
int size;
ExampleInfo *test_examples;
ExampleInfo *validation_examples;
char *pfname;
{
   TreeNode *root, *current;
   PriorityQueue *queue = NULL;
   int internal_nodes = 0;
   float priority;
   FILE *pfile = NULL;
   float fidelity, accuracy, comprehensibility;
   float last_fidelity;
   int samples_needed;
   int changed;
   int patience_counter = 0;
   int patience_stop = FALSE;
   Distribution **local_distributions;
   float *fidelity_values;
   ExampleInfo *validation_set = NULL;
   float *example_mask;

   root = (TreeNode *)check_malloc(sizeof(TreeNode));

   tree_root = root;
   example_distribution(root, train_examples, attr_info, options, train_mask);
   if (root->class == NO_CLASS)
      error(prog_name, "none of the training examples has a class label", TRUE);
   make_leaf(root, NULL, options, attr_info, constraints, FALSE, S_GLOBAL);
   root->number = 0;
   root->parent = NULL;
   root->distributions = NULL;

   if (options->do_sampling && options->distribution_type == LOCAL &&
       root->e_total >= options->min_estimation_sample)
   {
      root->distributions = determine_local_distributions(attr_info,
                                                          train_examples, train_mask, constraints,
                                                          NULL, options);
   }

   priority = calculate_node_priority(root);
   /*
   priority = new_calculate_node_priority(root, train_examples, options);
*/

   queue = insert_node_into_queue(root, priority, train_mask, queue);

   if (options->patience_threshold > 0.0)
   {
      fidelity = measure_fidelity(root, train_examples, attr_info,
                                  options, NULL);
      last_fidelity = fidelity;
   }

   if (options->validation_stop)
   {
      if (validation_examples->number == 0)
         validation_set = train_examples;
      else
         validation_set = validation_examples;
      fidelity_values = (float *)check_malloc(sizeof(float) * (size + 1));
      fidelity_values[0] = measure_fidelity(root, validation_set, attr_info,
                                            options, NULL);
   }

   if (pfname)
   {
      pfile = check_fopen(pfname, "w");
      fprintf(pfile, "internal_nodes\ttrain fidelity\ttrain accuracy");
      if (validation_examples->number != 0)
         fprintf(pfile, "\tvalid fidelity\tvalid accuracy");
      if (test_examples->number != 0)
         fprintf(pfile, "\ttest fidelity\ttest accuracy");
      fprintf(pfile, "\tleaves_nr\tcomprehensibility_m1");
      fprintf(pfile, "\tbranches_nr\tcomprehensibility_m2");
      fprintf(pfile, "\tlast gain\tchanged\n\n");
      if (options->patience_threshold <= 0.0)
         fidelity = measure_fidelity(root, train_examples, attr_info,
                                     options, NULL);
      accuracy = measure_accuracy(root, train_examples, attr_info,
                                  options, NULL);
      fprintf(pfile, "%d\t%f\t%f", internal_nodes, fidelity, accuracy);
      if (validation_examples->number != 0)
      {
         if (validation_set == validation_examples)
            fidelity = fidelity_values[0];
         else
            fidelity = measure_fidelity(root, validation_examples, attr_info,
                                        options, NULL);
         accuracy = measure_accuracy(root, validation_examples, attr_info,
                                     options, NULL);
         fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
      }
      if (test_examples->number != 0)
      {
         fidelity = measure_fidelity(root, test_examples, attr_info,
                                     options, NULL);
         accuracy = measure_accuracy(root, test_examples, attr_info,
                                     options, NULL);
         fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
      }

      int leaves_nr = compute_tree_leaves_nr(root,attr_info);
      fprintf(pfile, "\t%d", leaves_nr);
      // comprehensibility = measure_comprehensibility_based_on_leaves(root, attr_info);
      fprintf(pfile, "\t%f", measure_comprehensibility_based_on_leaves(leaves_nr));
      int branches_nr = compute_tree_branches_nr(root,attr_info);
      fprintf(pfile, "\t%d", branches_nr);
      fprintf(pfile, "\t%f", measure_comprehensibility_based_on_branches(branches_nr));

      fprintf(pfile, "\n");
      fflush(pfile);
   }

   while (queue != NULL && internal_nodes < size && !patience_stop)
   {
      queue = remove_node_from_queue(queue, &current, &example_mask);

      set_node_state(current, constraints);
      if (options->do_sampling)
      {
         samples_needed = options->min_sample - (int)current->e_total;
         if (samples_needed > 0)
         {
            local_distributions = (options->distribution_type == LOCAL) ? get_local_distributions(current) : NULL;
            get_new_sample(attr_info, constraints, options, samples_needed,
                           local_distributions, current);
         }
      }

      /*
if (options->do_sampling && options->distribution_type == LOCAL)
{
   local_distributions = (options->distribution_type == LOCAL) ?
			  get_local_distributions(current) : NULL;
   printf("LOCAL DISTRIBUTIONS:\n");
   print_attribute_distributions(attr_info, options, local_distributions);
}
*/

      queue = expand_tree_node(current, train_examples, example_mask, splits,
                               attr_info, constraints, options, queue);

      unset_node_state(current, constraints);

      if (current->type == INTERNAL)
      {
         ++internal_nodes;
         current->number = internal_nodes;

         changed = !children_predict_same(current);
         if (changed && options->patience_threshold > 0.0)
         {
            fidelity = measure_fidelity(root, train_examples, attr_info,
                                        options, NULL);
            if (fidelity - last_fidelity < options->patience_threshold)
               ++patience_counter;
            else
               patience_counter = 0;

            if (patience_counter == options->patience_counter)
            {
               patience_stop = TRUE;
               printf("Stopping patience reached: ");
               printf("last fidelity = %f, this fidelity = %f\n",
                      last_fidelity, fidelity);
            }
            last_fidelity = fidelity;
         }

         if (options->validation_stop)
         {
            fidelity_values[internal_nodes] = measure_fidelity(root,
                                                               validation_set, attr_info, options, NULL);
         }

         if (pfile)
         {
            if (validation_set == train_examples)
               fidelity = fidelity_values[internal_nodes];
            else
               fidelity = measure_fidelity(root, train_examples, attr_info,
                                           options, NULL);
            accuracy = measure_accuracy(root, train_examples, attr_info,
                                        options, NULL);
            fprintf(pfile, "%d\t%f\t%f", internal_nodes, fidelity, accuracy);
            if (validation_examples->number != 0)
            {
               if (validation_set == validation_examples)
                  fidelity = fidelity_values[internal_nodes];
               else
                  fidelity = measure_fidelity(root, validation_examples,
                                              attr_info, options, NULL);
               accuracy = measure_accuracy(root, validation_examples, attr_info,
                                           options, NULL);
               fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
            }
            if (test_examples->number != 0)
            {
               fidelity = measure_fidelity(root, test_examples, attr_info,
                                           options, NULL);
               accuracy = measure_accuracy(root, test_examples, attr_info,
                                           options, NULL);
               fprintf(pfile, "\t%f\t%f", fidelity, accuracy);
            }

            int leaves_nr = compute_tree_leaves_nr(root,attr_info);
            fprintf(pfile, "\t%d", leaves_nr);
            // comprehensibility = measure_comprehensibility_based_on_leaves(root, attr_info);
            fprintf(pfile, "\t%f", measure_comprehensibility_based_on_leaves(leaves_nr));
            int branches_nr = compute_tree_branches_nr(root,attr_info);
            fprintf(pfile, "\t%d", branches_nr);
            fprintf(pfile, "\t%f", measure_comprehensibility_based_on_branches(branches_nr));

            fprintf(pfile, "\t%f", Get_Split(current)->gain);
            if (changed)
               fprintf(pfile, "\t*\n");
            else
               fprintf(pfile, "\n");
            fflush(pfile);
         }
      }

      if (example_mask != train_mask)
         check_free((void *)example_mask);
   }

   printf("\nSTOPPING CRITERIA MET:\n");
   if (patience_stop)
      printf("\tpatience reached\n");
   if (internal_nodes >= size)
      printf("\tsize limit reached\n");
   if (queue == NULL)
      printf("\tqueue empty\n");

   if (options->validation_stop)
   {
      int i;
      int best = 0;

      for (i = 1; i <= internal_nodes; ++i)
         if (fidelity_values[i] > fidelity_values[best])
            best = i;

      printf("BEST TREE HAS %d NODES\n", best);

      check_free((void *)fidelity_values);
      validation_prune(root, best);
   }

   if (pfile)
      fclose(pfile);
   free_queue(queue);

   return (root);
}

static TreeNode *make_subtree(ex_info, example_mask, splits, attr_info,
                              parent, constraints, options, depth)
    ExampleInfo *ex_info;
float *example_mask;
Split *splits;
AttributeInfo *attr_info;
TreeNode *parent;
Constraint **constraints;
Options *options;
int depth;
{
   int i;
   Split *best_split;
   Split *discrete_splits;
   TreeNode *node;
   float **children_masks;
   int samples_needed;
   Distribution **local_distributions;
   Distribution **ancestor_distributions;

   /* add candidate splits for real-valued attributes */
   discrete_splits = splits;
   splits = add_real_valued_splits(attr_info, ex_info, example_mask,
                                   options, constraints, splits);

   node = (TreeNode *)check_malloc(sizeof(TreeNode));
   node->distributions = NULL;
   node->parent = parent;
   if (!parent)
      tree_root = node;
   else
   {
      /* for debugging only */
      for (i = 0; parent->type_specific.internal.children[i]; ++i)
         ;
      parent->type_specific.internal.children[i] = node;
   }

   example_distribution(node, ex_info, attr_info, options, example_mask);

   node->error = 0.0;

   if (options->do_sampling)
   {
      if (options->distribution_type == LOCAL &&
          node->e_total >= options->min_estimation_sample)
      {
         ancestor_distributions = get_local_distributions(node);
         node->distributions = determine_local_distributions(attr_info,
                                                             ex_info, example_mask, constraints,
                                                             ancestor_distributions, options);
      }

      samples_needed = options->min_sample - (int)node->e_total;
      if (samples_needed > 0)
      {
         local_distributions = (options->distribution_type == LOCAL) ? get_local_distributions(node) : NULL;
         get_new_sample(attr_info, constraints, options, samples_needed,
                        local_distributions, node);
         sample_distribution(node, samples_needed, attr_info, options);
      }
   }

   /* test to see if this should be a leaf */
   if (options->do_sampling && options->sampling_stop &&
       sampling_stop(node, options, attr_info, constraints))
   {
      make_leaf(node, parent, options, attr_info, constraints, TRUE,
                S_SAMPLING);
      return (node);
   }
   else if (Get_Total(node) < 2 * options->min_objects)
   {
      make_leaf(node, parent, options, attr_info, constraints, TRUE,
                S_MIN_OBJECTS);
      return (node);
   }
   else if (Get_Total_Error(node) == 0.0)
   {
      make_leaf(node, parent, options, attr_info, constraints, TRUE, S_ERROR);
      return (node);
   }
   else if (splits == NULL)
   {
      make_leaf(node, parent, options, attr_info, constraints, TRUE,
                S_NO_SPLITS);
      return (node);
   }
   else if (depth == options->stop_depth)
   {
      make_leaf(node, parent, options, attr_info, constraints, FALSE, S_DEPTH);
      return (node);
   }

   if (options->split_search_method == BEAM)
   {
      best_split = ID2_of_3_beam(attr_info, ex_info, example_mask, constraints,
                                 options, splits);
   }
   else
   {
      best_split = make_split(attr_info, ex_info, example_mask,
                              options, splits);
   }

   if (!best_split)
   {
      make_leaf(node, parent, options, attr_info, constraints, FALSE,
                S_NO_PICK_SPLIT);
      return (node);
   }

   node->type = INTERNAL;
   node->type_specific.internal.split = best_split;
   ++best_split->reference_count;

   /* remove candidate splits for real-valued attributes */
   if (discrete_splits != splits)
   {
      if (discrete_splits)
      {
         discrete_splits->prev->next = NULL;
         discrete_splits->prev = NULL;
      }
      free_unused_splits(splits);
      splits = discrete_splits;
   }

   if (best_split->type != M_OF_N_SPLIT && best_split->type != REAL_SPLIT)
      splits = remove_split(splits, best_split);

   node->type_specific.internal.probs =
       (float *)check_malloc(sizeof(float) * best_split->arity);
   for (i = 0; i < best_split->arity; ++i)
      node->type_specific.internal.probs[i] = best_split->branch_distr[i] /
                                              (best_split->total - best_split->missing);

   children_masks = make_masks(node, ex_info, example_mask);

   node->type_specific.internal.children =
       (TreeNode **)check_malloc(sizeof(TreeNode *) * best_split->arity);

#ifdef DEBUG
#endif
   for (i = 0; i < best_split->arity; ++i)
      node->type_specific.internal.children[i] = NULL;

   node->error = 0.0;
   for (i = 0; i < best_split->arity; ++i)
   {
      set_constraint(best_split, i, constraints);
      node->type_specific.internal.children[i] =
          make_subtree(ex_info, children_masks[i], splits, attr_info,
                       node, constraints, options, depth + 1);

      if (!options->do_sampling)
         node->error += node->type_specific.internal.children[i]->error;
      else
         node->error += node->type_specific.internal.probs[i] *
                        node->type_specific.internal.children[i]->error;

      unset_constraint(best_split, constraints);
   }
   free_masks(children_masks, best_split->arity);

   /*
   if (node->error >= Get_Example_Error(node) - EPSILON ||
       children_predict_same(node))
*/

   /*
   if (children_predict_same(node))
   {
      printf("COLLAPSE: children error = %.3f, parent error = %.3f\n",
	     node->error, Get_Example_Error(node));

      split = Get_Split(node);
      for (i = 0; i < split->arity; ++i)
         free_tree(Get_Nth_Child(node, i));
      make_leaf(node, parent, options, attr_info, constraints, TRUE, S_GLOBAL);
   }
*/

   if (best_split->type != M_OF_N_SPLIT && best_split->type != REAL_SPLIT)
      splits = put_split_back(splits, best_split);

   return (node);
}

static void reset_leaf_statistics(node)
    TreeNode *node;
{
   Split *split;
   int branch;

   if (node->type == LEAF)
   {
      node->type_specific.leaf.total = 0.0;
      node->type_specific.leaf.error = 0.0;
   }
   else
   {
      split = Get_Split(node);
      for (branch = 0; branch < split->arity; ++branch)
         reset_leaf_statistics(Get_Nth_Child(node, branch));
   }
}

static void determine_class(node, example, weight, distribution,
                            covered, attr_info, actual)
    TreeNode *node;
Example *example;
float weight;
float *distribution;
int *covered;
AttributeInfo *attr_info;
int actual;
{
   int branch;
   Split *split;
   int i;

   if (node->type == LEAF)
   {
      if (Get_Total(node) > 0.0)
         for (i = 0; i < attr_info->num_classes; ++i)
            distribution[i] += weight * Get_Class_Total(node, i) /
                               Get_Total(node);
      else
         distribution[node->class] += weight;

      node->type_specific.leaf.total += weight;
      if (node->class != actual)
         node->type_specific.leaf.error += weight;

      if (covered)
      {
         if (weight == 1.0)
         {
            if (node->type_specific.leaf.covered)
               *covered = TRUE;
            else
               *covered = FALSE;
         }
         else
            *covered = UNDETERMINED;
      }
   }
   else
   {
      branch = which_branch(Get_Split(node), example);
      if (branch == MISSING)
      {
         split = Get_Split(node);
         for (branch = 0; branch < split->arity; ++branch)
            determine_class(Get_Nth_Child(node, branch), example,
                            weight * Get_Nth_Prob(node, branch),
                            distribution, covered, attr_info, actual);
      }
      else
      {
         node = Get_Nth_Child(node, branch);
         determine_class(node, example, weight, distribution, covered,
                         attr_info, actual);
      }
   }
}

void classify_example(tree, example, covered, attr_info, distribution, actual)
    TreeNode *tree;
Example *example;
int *covered;
AttributeInfo *attr_info;
float *distribution;
int actual;
{
   int i;

   for (i = 0; i < attr_info->num_classes; ++i)
      distribution[i] = 0.0;

   determine_class(tree, example, 1.0, distribution, covered,
                   attr_info, actual);
}

int get_predicted_class(attr_info, distribution)
    AttributeInfo *attr_info;
float *distribution;
{
   int class;
   int i;

   class = 0;
   for (i = 1; i < attr_info->num_classes; ++i)
      if (distribution[i] > distribution[class])
         class = i;

   return (class);
}

void classify_using_tree(tree, ex_info, attr_info, options,
                         matrix, covered_matrix, use_test_fold)
    TreeNode *tree;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
int **matrix;
int **covered_matrix;
int use_test_fold;
{
   int i;
   int predicted;
   ValueType actual;
   Example *example;
   int covered;
   int correct;
   float *distribution;

   if (ClassIsVector(attr_info))
   {
      error("system error",
            "tried to use classify_using_tree for class vectors", TRUE);
   }

   distribution = (float *)check_malloc(sizeof(float) *
                                        attr_info->num_classes);

   reset_leaf_statistics(tree);

   for (i = 0; i < ex_info->number; ++i)
   {
      example = &ex_info->examples[i];
      if ((example->fold == ex_info->test_fold) == use_test_fold)
      {
         actual = get_class(example, attr_info, options);
         classify_example(tree, example, &covered, attr_info, distribution,
                          actual.discrete);
         predicted = get_predicted_class(attr_info, distribution);
         ++matrix[predicted][actual.discrete];

         /*
printf("%-10d %-20s %d\n", i,
       attr_info->attributes[attr_info->class_index].labels[predicted],
      (int) (predicted == actual.discrete));
*/

         if (covered_matrix && covered != UNDETERMINED)
         {
            correct = (predicted == actual.discrete);
            ++covered_matrix[covered][correct];
         }
      }
   }

   check_free((void *)distribution);
}

void match_any(tree, ex_info, attr_info, options, matrix)
    TreeNode *tree;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
Options *options;
int **matrix;
{
   int i, j;
   int predicted;
   int actual_class;
   ValueType actual;
   Example *example;
   float *distribution;

   if (!ClassIsVector(attr_info))
   {
      error("system error",
            "tried to use match_any for non-vector classes", TRUE);
   }

   distribution = (float *)check_malloc(sizeof(float) *
                                        attr_info->num_classes);

   for (i = 0; i < ex_info->number; ++i)
   {
      example = &ex_info->examples[i];
      actual = get_class(&ex_info->examples[i], attr_info, options);
      classify_example(tree, example, NULL, attr_info, distribution,
                       actual.discrete);
      predicted = get_predicted_class(attr_info, distribution);

      if (actual.vector[predicted] > 0.0)
         actual_class = predicted;
      else
      {
         /* we'll say the "actual" class is the one w/ largest probability */
         actual_class = 0;
         for (j = 1; j < attr_info->num_classes; ++j)
            if (actual.vector[j] > actual.vector[actual_class])
               actual_class = j;
      }

      ++matrix[predicted][actual_class];
   }

   check_free((void *)distribution);
}

float calculate_sum_squared_error(tree, ex_info, attr_info)
    TreeNode *tree;
ExampleInfo *ex_info;
AttributeInfo *attr_info;
{
   int i, j;
   Example *example;
   float *distribution;
   float target, part;
   float SS_error = 0.0;
   int class_is_vector = ClassIsVector(attr_info);

   distribution = (float *)check_malloc(sizeof(float) *
                                        attr_info->num_classes);

   for (i = 0; i < ex_info->number; ++i)
   {
      example = &ex_info->examples[i];
      classify_example(tree, example, NULL, attr_info, distribution, NONE);

      for (j = 0; j < attr_info->num_classes; ++j)
      {
         if (class_is_vector)
            target = example->values[attr_info->class_index].value.vector[j];
         else
         {
            target =
                (j == example->values[attr_info->class_index].value.discrete) ? 1.0 : 0.0;
         }
         part = target - distribution[j];
         SS_error += 0.5 * part * part;
      }
   }

   check_free((void *)distribution);

   return (SS_error);
}

static void determine_min_estimation_sample(train_examples, options)
    ExampleInfo *train_examples;
Options *options;
{
   int n = 0;
   int i;

   for (i = 0; i < train_examples->number; ++i)
      if (train_examples->examples[i].fold != train_examples->test_fold)
         ++n;

   options->min_estimation_sample = options->min_estimation_fraction * n;
}

void create_fidelity_file_pruned(char *pfname,int internal_nodes_after_pruning) 
{
   
   // create a pruned fidelity file    
   char *fp2 = ".pruned";
   // strcat(pfname,fp2);
   char * line = NULL;
   size_t len = 0;
   ssize_t read;
   int internal_nodes_before_pruning;

   FILE *pfile = check_fopen(pfname, "r");
   FILE *pfile2 = check_fopen(strcat(pfname,fp2), "w");
   while ((read = getline(&line, &len, pfile)) != -1) {
      
      int i = 0;
      char *pch;
      // printf("Retrieved line of length %zu:\n", read);
      
      char *line_copy = my_strcopy(line);

      // printf("Retrieved line of length %zu:\n", read);
      // printf("%s", line);
      // printf ("Splitting string \"%s\" into tokens:\n",line);
      pch = strtok (line," \t");
      while (pch != NULL && i == 0)
      {
         // printf ("%s\n",pch);
         // pch = strtok (NULL, " \t");
         i++;
      }
   
      if (strncmp(pch,'i',0)==1 || strncmp(pch,' ',0)==1) {
         // printf("HERE! %d\n",line[0]);
         fprintf(pfile2, line_copy); 
      }
      else {
         internal_nodes_before_pruning = atoi(pch);
         if (internal_nodes_before_pruning <= internal_nodes_after_pruning) {
            fprintf(pfile2, line_copy);
         }
         // else {
         //    // printf("NADA!\n");
         // }
      }  
   }
   close(pfile);
   fflush(pfile2);

   char *fp3 = ".nodes";
   FILE *pfile3 = check_fopen(strcat(pfname,fp3), "w");
   fprintf(pfile3, "%s\t%s\n", "tree_size_limit_nodes", "tree_size_pruned_internal");
   fprintf(pfile3, "%d\t%d\n", internal_nodes_before_pruning , internal_nodes_after_pruning);
   fflush(pfile3);
}

TreeNode *induce_tree(attr_info, train_examples, train_mask, test_examples,
                      validation_examples, options, pfname)
    AttributeInfo *attr_info;
ExampleInfo *train_examples;
float *train_mask;
ExampleInfo *test_examples;
ExampleInfo *validation_examples;
Options *options;
char *pfname;
{
   Split *splits;
   TreeNode *tree;
   Constraint **constraints;
   int i;

   if (options->do_sampling && !options->use_oracle)
   {
      error("System error", "do_sampling and use_oracle disagree", TRUE);
   }

   if (options->use_oracle)
   {
      if (options->oracle == NULL)
         error(prog_name, "tried to use oracle before one loaded", TRUE);

      cache_oracle_classifications(train_examples, attr_info, options);

      if (options->do_sampling)
         determine_min_estimation_sample(train_examples, options);
   }
   //roberto: it seems that it produces only a list of splits, one for each relevant feature. But what
   //does relevant mean?
   splits = make_candidate_splits(attr_info, options);

   constraints = (Constraint **)
       check_malloc(sizeof(Constraint *) * attr_info->number);
   for (i = 0; i < attr_info->number; ++i)
      constraints[i] = NULL;

   if (options->expansion_method == BEST_FIRST)
   {
      tree = best_first(train_examples, train_mask, splits, attr_info,
                        constraints, options, options->tree_size_limit,
                        test_examples, validation_examples, pfname);
   }
   else
   {
      tree = make_subtree(train_examples, train_mask, splits, attr_info, NULL,
                          constraints, options, 0);
   }
   //added by roberto to know which split to use in the draw_tree_revisited method
   tree->split_node_type = options->split_node_type;

   // printf("\nWITHOUT SIMPLIFICATION:\n");
   printf("\nBEFORE SIMPLIFICATION:\n");
   int internal_nodes = report_tree_statistics(tree, attr_info);
   unnecessary_node_prune(tree);

   printf("AFTER SIMPLIFICATION:\n");
   int internal_nodes_after_pruning = report_tree_statistics(tree, attr_info);
   printf("internal_nodes_after_pruning %d\n",internal_nodes_after_pruning);
   
   create_fidelity_file_pruned(pfname,internal_nodes_after_pruning);
   
   check_free((void *)constraints);
   free_unused_splits(splits);

   return (tree);
}

void print_tree(node, attr_info, level)
    TreeNode *node;
AttributeInfo *attr_info;
int level;
{
   int index;
   Attribute *attr;
   int i, j;
   Split *split;
   char *temp_label;

   if (!node)
   {
      printf("NULL\n");
   }
   else if (node->type == LEAF)
   {
      index = node->class;
      attr = &attr_info->attributes[attr_info->class_index];
      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
         temp_label = attr->labels[index];
      else
         temp_label = index ? "true" : "false";
      printf("%s ", temp_label);

      /*
      if (Get_Example_Error(node) == 0.0)
	 printf("(%.1f)", node->e_total);
      else
	 printf("(%.1f/%.1f)", node->e_total, Get_Example_Error(node));

      printf("  (%.1f/%.1f)", node->type_specific.leaf.total,
	     node->type_specific.leaf.error);
*/

      /*
      switch(node->type_specific.leaf.stop_reason)
      {
	 case S_GLOBAL:
	    printf("  GLOBAL\n");
	    break;
	 case S_DEPTH:
	    printf("  DEPTH\n");
	    break;
	 case S_NO_SPLITS:
	    printf("  NO_SPLITS\n");
	    break;
	 case S_NO_PICK_SPLIT:
	    printf("  NO_PICK_SPLIT\n");
	    break;
	 case S_MIN_OBJECTS:
	    printf("  MIN_OBJECTS\n");
	    break;
	 case S_ERROR:
	    printf("  ERROR\n");
	    break;
	 case S_SAMPLING:
	    printf("  SAMPLING\n");
	    break;
	 case S_SIMPLIFIED:
	    printf("  SIMPLIFIED\n");
	    break;
	 case S_PRUNED:
	    printf("  PRUNED\n");
	    break;
	 case S_ZERO_BRANCH_PROB:
	    printf("  BRANCH-PROB=0\n");
	    break;
	 default:
	    error("system error", "bad stop_reason in print_tree", TRUE);
      }
*/

      printf("  [");
      for (i = 0; i < attr_info->num_classes; ++i)
      {
         if (i > 0)
            printf(", ");
         printf("%.1f", node->e_distribution[i]);
      }
      printf("]  [");
      for (i = 0; i < attr_info->num_classes; ++i)
      {
         if (i > 0)
            printf(", ");
         printf("%d", (int)node->s_distribution[i]);
      }
      printf("]\n");
   }
   else
   {
      printf("\n");
      split = Get_Split(node);
      for (i = 0; i < split->arity; ++i)
      {
         for (j = 0; j < level; ++j)
            printf("|   ");

         print_split(split, attr_info, i, stdout);
         printf(": ");

         /*
	 if (i== 0 && node->distributions != NULL)
	    printf("(D) ");
*/

         print_tree(node->type_specific.internal.children[i],
                    attr_info, level + 1);
      }
   }
}

/* revisited method by Roberto that takes full labels (concepts) from ontology into account */ 
void print_split_revisited(split, attr_info, branch, stream, split_node_type)
    Split *split;
AttributeInfo *attr_info;
int branch;
FILE *stream;
SplitNodeType split_node_type;
{
   int index;
   Attribute *attr;
   char *temp_label;
   Member *member;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      index = Get_Nominal_Attr(split);
      attr = &attr_info->attributes[index];
      // temp_label = attr->full_labels[branch];
      temp_label = attr->full_labels_for_draw[branch];
      if (split_node_type != LO_MOFN)
         fprintf(stream, "%s = %s", attr->full_name, temp_label);
      else
         fprintf(stream, "%s", attr->full_name);
      //fprintf(stream, "%s", attr->name);
      break;
   case BOOLEAN_SPLIT:
      index = Get_Boolean_Attr(split);
      attr = &attr_info->attributes[index];
      if (attr->type == BOOLEAN_ATTR)
      {
         temp_label = branch ? "false" : "true";
         if (split_node_type != LO_MOFN)
            fprintf(stream, "%s = %s", attr->full_name, temp_label);
         else
            fprintf(stream, "%s", attr->full_name);
      }
      else
      {
         temp_label = branch ? "!=" : "=";
         if (split_node_type != LO_MOFN)
            fprintf(stream, "%s %s %s", attr->full_name, temp_label,
                    attr->full_labels_for_draw[Get_Boolean_Value(split)]);
         else
            fprintf(stream, "%s", attr->full_name);
      }
      break;
   case M_OF_N_SPLIT:
      if (branch)
         fprintf(stream, "NOT ");
      fprintf(stream, "%d of {", split->type_specific.mofn.m);
      member = Get_Members(split);
      while (member)
      {
         if (member != Get_Members(split))
            fprintf(stream, ", ");
         attr = &attr_info->attributes[member->attribute];
         if (attr->type == BOOLEAN_ATTR)
         {
            temp_label = member->value.discrete ? "true" : "false";
            fprintf(stream, "%s=%s", attr->full_name, temp_label);
         }
         else if (attr->type == NOMINAL_ATTR)
         {
            fprintf(stream, "%s=%s", attr->full_name,
                    attr->full_labels_for_draw[member->value.discrete]);
         }
         else if (attr->type == REAL_ATTR)
         {
            float original_value = calculate_unnormalized_value(attr->original_range->min, attr->original_range->max, member->value.real);
            if (!member->negated)
               // fprintf(stream, "%s <= %f", attr->full_name, member->value.real);
               fprintf(stream, "%s <= %.2f", attr->full_name, original_value);
            else
               // fprintf(stream, "%s > %f", attr->full_name, member->value.real);
               fprintf(stream, "%s > %.2f", attr->full_name, original_value);
         }

         member = member->next;
      }
      fprintf(stream, "}");
      break;
   case REAL_SPLIT:
      index = Get_Real_Attr(split);
      attr = &attr_info->attributes[index];
      temp_label = branch ? ">" : "<=";
      // if (split_node_type != LO_MOFN)
      float unnormalized_value = calculate_unnormalized_value(attr->original_range->min, attr->original_range->max, Get_Threshold(split));
      // fprintf(stream, "%s %s %.6f", attr->full_name, temp_label, Get_Threshold(split));
      fprintf(stream, "%s %s %.2f", attr->full_name, temp_label, unnormalized_value);
      // else
      //    fprintf(stream, "%s", attr->full_name);
      break;
   }
}

/* revisited method by Roberto that takes full labels (concepts) from ontology into account */ 
void print_split_revisited_2(split, attr_info, branch, stream, split_node_type)
    Split *split;
AttributeInfo *attr_info;
int branch;
FILE *stream;
SplitNodeType split_node_type;
{
   int index;
   Attribute *attr;
   char *temp_label;
   Member *member;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
      index = Get_Nominal_Attr(split);
      attr = &attr_info->attributes[index];
      // temp_label = attr->full_labels[branch];
      temp_label = attr->full_labels_for_draw[branch];
      if (split_node_type != LO_MOFN)
         fprintf(stream, "%s = %s", attr->full_name, temp_label);
      else
         fprintf(stream, "%s", attr->full_name);
      //fprintf(stream, "%s", attr->name);
      break;
   case BOOLEAN_SPLIT:
      index = Get_Boolean_Attr(split);
      attr = &attr_info->attributes[index];
      if (attr->type == BOOLEAN_ATTR)
      {
         temp_label = branch ? "false" : "true";
         if (split_node_type != LO_MOFN)
            fprintf(stream, "%s = %s", attr->full_name, temp_label);
         else
            fprintf(stream, "%s", attr->full_name);
      }
      else
      {
         temp_label = branch ? "!=" : "=";
         if (split_node_type != LO_MOFN)
            fprintf(stream, "%s %s %s", attr->full_name, temp_label,
                    attr->full_labels_for_draw[Get_Boolean_Value(split)]);
         else
            fprintf(stream, "%s", attr->full_name);
      }
      break;
   case M_OF_N_SPLIT:
      if (branch)
         fprintf(stream, "NOT ");
      fprintf(stream, "%d of {", split->type_specific.mofn.m);
      member = Get_Members(split);
      while (member)
      {
         if (member != Get_Members(split))
            fprintf(stream, ", ");
         attr = &attr_info->attributes[member->attribute];
         if (attr->type == BOOLEAN_ATTR)
         {
            temp_label = member->value.discrete ? "true" : "false";
            fprintf(stream, "%s=%s", attr->full_name, temp_label);
         }
         else if (attr->type == NOMINAL_ATTR)
         {
            fprintf(stream, "%s=%s", attr->full_name,
                    attr->full_labels_for_draw[member->value.discrete]);
         }
         else if (attr->type == REAL_ATTR)
         {
            float original_value = calculate_unnormalized_value(attr->original_range->min, attr->original_range->max, member->value.real);
            if (!member->negated)
               // fprintf(stream, "%s <= %f", attr->full_name, member->value.real);
               fprintf(stream, "%s <= %.2f", attr->full_name, original_value);
            else
               // fprintf(stream, "%s > %f", attr->full_name, member->value.real);
               fprintf(stream, "%s > %.2f", attr->full_name, original_value);
         }

         member = member->next;
      }
      fprintf(stream, "}");
      break;
   case REAL_SPLIT:
      index = Get_Real_Attr(split);
      attr = &attr_info->attributes[index];
      temp_label = branch ? ">" : "<=";
      // if (split_node_type != LO_MOFN)
      float unnormalized_value = calculate_unnormalized_value(attr->original_range->min, attr->original_range->max, Get_Threshold(split));
      // fprintf(stream, "%s %s %.6f", attr->full_name, temp_label, Get_Threshold(split));
      fprintf(stream, "%s %s %.2f", attr->full_name, temp_label, unnormalized_value);
      // else
      //    fprintf(stream, "%s", attr->full_name);
      break;
   }
}

void print_rules(node, attr_info, level, stream)
    TreeNode *node;
   AttributeInfo *attr_info;
   int level;
   FILE *stream;
{
   int index;
   Attribute *attr;
   int i, j;
   Split *split;
   char *temp_label;

   if (!node)
   {
      printf("NULL\n");
      fprintf(stream,"NULL\n");
   }
   else if (node->type == LEAF)
   {
      index = node->class;
      attr = &attr_info->attributes[attr_info->class_index];
      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
         // temp_label = attr->labels[index];
         temp_label = attr->full_labels_for_draw[index];
      else
         temp_label = index ? "true" : "false";
      printf("THEN '%s' ", temp_label);
      printf("\n");
      
      fprintf(stream, "THEN '%s' ", temp_label);
      fprintf(stream, "\n");
      
      // printf("  [");
      // for (i = 0; i < attr_info->num_classes; ++i)
      // {
      //    if (i > 0)
      //       printf(", ");
      //    printf("%.1f", node->e_distribution[i]);
      // }
      // // printf("]\n");
      // printf("]  [");
      // for (i = 0; i < attr_info->num_classes; ++i)
      // {
      //    if (i > 0)
      //       printf(", ");
      //    printf("%d", (int)node->s_distribution[i]);
      // }
      // printf("]\n");
   }
   else
   {
      printf("\n");
      fprintf(stream, "\n");
      split = Get_Split(node);
      for (i = 0; i < split->arity; ++i)
      {  
         if (level == 0) {
            printf("IF ");
            fprintf(stream, "IF ");
         }
         // else {
         //    printf("AND ");
         //    fprintf(stream, "AND ");
         // }
         for (j = 0; j < level; ++j) {
            printf("|   ");
            fprintf(stream,"|   ");
            // if (j == level-1) {
            //    // printf("|   ");
            //    printf("AND   ");
            //    fprintf(stream, "AND ");
            // }
            // else {
            //    printf("   ");
            //    fprintf(stream, "   ");
            // }
         }
         if (level != 0) {
            printf("AND ");
            fprintf(stream, "AND ");
         }
         printf("(");
         fprintf(stream, "(");
         print_split_revisited(split, attr_info, i, stdout);
         print_split_revisited(split, attr_info, i, stream);
         // printf(": ");
         printf(") ");
         fprintf(stream, ") ");

         /*
	 if (i== 0 && node->distributions != NULL)
	    printf("(D) ");
*/

         print_rules(node->type_specific.internal.children[i],
                    attr_info, level + 1, stream);
      }
   }
}

// void print_rules_2(node, attr_info, level, stream)
//     TreeNode *node;
//    AttributeInfo *attr_info;
//    int level;
//    FILE *stream;
// {
//    int index;
//    Attribute *attr;
//    int i, j;
//    Split *split;
//    // Split *parent_split;
//    char *temp_label;
//    // char *temp;

//    if (!node)
//    {
//       printf("NULL\n");
//       fprintf(stream, "NULL\n");
//    }
//    else if (node->type == LEAF)
//    {
//       index = node->class;
//       attr = &attr_info->attributes[attr_info->class_index];
//       if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
//          // temp_label = attr->labels[index];
//          temp_label = attr->full_labels_for_draw[index];
//       else
//          temp_label = index ? "true" : "false";
      
//       printf("THEN '%s' ", temp_label);
//       printf("\n");
      
//       fprintf(stream, "THEN '%s' ", temp_label);
//       fprintf(stream, "\n");
   
      
//    }
//    else
//    {
//       // printf("\n");
      
//       split = Get_Split(node);

//       for (i = 0; i < split->arity; ++i)
//       {
//          if (level == 0) {
//             printf("IF ");
//             fprintf(stream, "IF");
//          }
//          // else {
//          //    printf("\t");   
//          //    fprintf(stream, "\t");
//          // }
//          for (j = 0; j < level; ++j) {
//             if (j<level-1) {
//                printf("|   ");   
//                fprintf(stream, "|   ");
//             } 
//             else {
//                printf("AND ");
//                fprintf(stream, "AND ");
//             }
//          }
//          printf("(");
//          fprintf(stream, "(");
//          print_split_revisited_2(split, attr_info, i, stdout);
//          print_split_revisited_2(split, attr_info, i, stream);
//          // printf(": ");
//          printf(") ");
//          fprintf(stream, ") ");

//          /*
// 	 if (i== 0 && node->distributions != NULL)
// 	    printf("(D) ");
// */

//          print_rules_2(node->type_specific.internal.children[i],
//                     attr_info, level + 1, stream);
//       }
//    }
// }

//static void draw_node(node, attr_info, branch,stream)
static void draw_node(node, attr_info, stream)
    TreeNode *node;
AttributeInfo *attr_info;
//int branch;

FILE *stream;
{
   int index;
   Attribute *attr;
   int i;
   TreeNode *child;
   Split *split;
   char *class_label;
   char *font_color = "black";
   char *temp_label;

   if (node->type == LEAF)
   {
      index = node->class;
      attr = &attr_info->attributes[attr_info->class_index];
      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR)
         class_label = attr->labels[index];
      else
         class_label = index ? "true" : "false";

      if (attr_info->num_classes == 2)
         font_color = index ? "green" : "red";

      fprintf(stream, "\t%d [color=blue,fontcolor=%s,label=\"%s\"];\n",
              (int)node, font_color, class_label);
   }
   else
   {
      split = Get_Split(node);
      fprintf(stream, "\t%d [color=blue,label=\"", (int)node);
      print_split(split, attr_info, 0, stream);
      fprintf(stream, "\",shape=box];\n");

      for (i = 0; i < split->arity; ++i)
      {
         //temp_label = attr->labels[branch];
         child = node->type_specific.internal.children[i];
         //fprintf(stream, "\t%d -> %d [label=%s];\n", (int) node, (int) child, temp_label);
         //draw_node(child, attr_info, branch, stream);
         fprintf(stream, "\t%d -> %d ;\n", (int)node, (int)child);
         draw_node(child, attr_info, stream);
      }
   }
}

//void draw_tree(node, attr_info, branch, fname)
void draw_tree(node, attr_info, fname)
    TreeNode *node;
AttributeInfo *attr_info;
//int branch;
char *fname;
{
   FILE *stream;

   stream = check_fopen(fname, "w");
   fprintf(stream, "digraph tree\n{\n");

   //draw_node(node, attr_info, branch,stream);
   draw_node(node, attr_info, stream);

   fprintf(stream, "}\n");
   fclose(stream);
}

static int get_split_index(split)
    Split *split;
{
   int index;
   switch (split->type)
   {
   case NOMINAL_SPLIT:
      index = Get_Nominal_Attr(split);
      return index;
      break;
   case BOOLEAN_SPLIT:
      index = Get_Boolean_Attr(split);
      return index;
      break;
   case REAL_SPLIT:
      index = Get_Real_Attr(split);
      return index;
      break;
   default:
      sprintf(err_buffer, "invalid split->type %d ", split->type);
      break;
   }
}

//static void draw_node(node, attr_info, branch,stream)
static void draw_node_revisited(node, attr_info, stream, split_node_type)
    TreeNode *node;
AttributeInfo *attr_info;
//int branch;
FILE *stream;
SplitNodeType split_node_type;
{
   int index;
   Attribute *attr;
   int i;
   TreeNode *child;
   Split *split;
   char *class_label;
   char *font_color = "black";
   char *temp_label;

   if (node->type == LEAF)
   {
      index = node->class;
      attr = &attr_info->attributes[attr_info->class_index];
      if (attr->type == NOMINAL_ATTR || attr->type == VECTOR_ATTR) {
         // class_label = attr->labels[index];
         // class_label = attr->full_labels[index];
         class_label = attr->full_labels_for_draw[index];
      }
      else {
         // class_label = index ? "true" : "false";
         class_label = attr->full_labels_for_draw[index];
      }

      if (attr_info->num_classes == 2)
         font_color = index ? "green" : "red";

      fprintf(stream, "\t%d [color=blue,fontcolor=%s,label=\"%s\"];\n",
              (int)node, font_color, class_label);
   }
   else
   {
      split = Get_Split(node);
      fprintf(stream, "\t%d [color=blue,label=\"", (int)node);
      print_split_revisited(split, attr_info, 0, stream, split_node_type);
      fprintf(stream, "\",shape=box];\n");

      if (split->type == MOFN)
      {
         int index = get_split_index(split);
         attr = &attr_info->attributes[index];

         for (i = 0; i < split->arity; ++i)
         {
            child = node->type_specific.internal.children[i];
            //fprintf(stream, "\t%d -> %d ;\n", (int)node, (int)child);
            fprintf(stream, "\t%d -> %d [label=\"%s\"];\n", (int)node, (int)child, attr->full_labels_for_draw[i]);
            draw_node_revisited(child, attr_info, stream, split_node_type);
         }
      }
      else
      {
         for (i = 0; i < split->arity; ++i)
         {
            child = node->type_specific.internal.children[i];
            //fprintf(stream, "\t%d -> %d ;\n", (int)node, (int)child);
            if (i == 0)
               fprintf(stream, "\t%d -> %d [label=\"true\"];\n", (int)node, (int)child);
            else
               fprintf(stream, "\t%d -> %d [label=\"false\"];\n", (int)node, (int)child);
            draw_node_revisited(child, attr_info, stream, split_node_type);
         }
      }
   }
}

/* revisted method by roberto to take into account full labels (concepts in an ontology) */
void draw_tree_revisited(node, attr_info, fname)
    TreeNode *node;
AttributeInfo *attr_info;
//int branch;
char *fname;
//SplitNodeType split_node_type;
{
   FILE *stream;

   stream = check_fopen(fname, "w");
   fprintf(stream, "digraph tree\n{\n");

   //draw_node(node, attr_info, branch,stream);
   draw_node_revisited(node, attr_info, stream, node->split_node_type);

   fprintf(stream, "}\n");
   fclose(stream);
}

static int count_values(split)
    Split *split;
{
   Member *member;
   int count = 0;

   switch (split->type)
   {
   case NOMINAL_SPLIT:
   case BOOLEAN_SPLIT:
   case REAL_SPLIT:
      return (1);
   case M_OF_N_SPLIT:
   {
      member = Get_Members(split);
      while (member)
      {
         ++count;
         member = member->next;
      }
      return (count);
   }
   default:
      error("System error", "bad split type in count_values", TRUE);
   }
}

void tree_stats(node, stats, value_count)
    TreeNode *node;
TreeStats *stats;
int value_count;
{
   int i;
   int count;

   if (node->type == LEAF)
   {
      ++stats->leaves;

      ++stats->rules[node->class];
      stats->antes[node->class] += value_count;
   }
   else
   {
      ++stats->internal;
      count = count_values(Get_Split(node));
      stats->values += count;
      value_count += count;
      //added by roberto
      stats->total_branches += node->type_specific.internal.split->arity;
      for (i = 0; i < node->type_specific.internal.split->arity; ++i)
         tree_stats(Get_Nth_Child(node, i), stats, value_count);
   }
}

static void fraction_covered(node, fraction, correctness, size)
    TreeNode *node;
float *fraction;
float *correctness;
double size;
{
   Split *split;
   int i;
   double multiplier;

   if (node->type == LEAF)
   {
      if (node->type_specific.leaf.covered)
         *fraction += size;
      *correctness += size * (1.0 - node->e_total);
   }
   else
   {
      split = Get_Split(node);
      multiplier = 1.0 / split->arity;
      for (i = 0; i < split->arity; ++i)
         fraction_covered(node->type_specific.internal.children[i],
                          fraction, correctness, multiplier * size);
   }
}

static void determine_non_linearity(node, NL, size)
    TreeNode *node;
float *NL;
int *size;
{
   int arity;
   float left_NL, right_NL;
   int left_size, right_size;

   if (node->type == LEAF)
   {
      *size = 0;
      *NL = 0.0;
   }
   else
   {
      arity = node->type_specific.internal.split->arity;
      if (arity != 2)
      {
         error(prog_name,
               "tree non-linearity only computed for binary trees currently",
               TRUE);
      }

      determine_non_linearity(Get_Nth_Child(node, 0), &left_NL, &left_size);
      determine_non_linearity(Get_Nth_Child(node, 1), &right_NL, &right_size);
      if (left_size > right_size)
         *NL = 0.5 * (right_NL + right_size + left_NL);
      else
         *NL = 0.5 * (left_NL + left_size + right_NL);
      *size = 1 + left_size + right_size;
   }
}

int report_tree_statistics(node, attr_info)
    TreeNode *node;
AttributeInfo *attr_info;
{
   TreeStats stats;
   float NL = 0.0;
   int size;
   int i;
   float covered = 0.0;
   float correctness = 0.0;

   stats.leaves = 0;
   stats.total_branches = 0;
   stats.internal = 0;
   stats.values = 0;
   stats.rules = check_malloc(sizeof(int) * attr_info->num_classes);
   stats.antes = check_malloc(sizeof(int) * attr_info->num_classes);
   for (i = 0; i < attr_info->num_classes; ++i)
   {
      stats.rules[i] = 0;
      stats.antes[i] = 0;
   }

   tree_stats(node, &stats, 0);

   /*
   determine_non_linearity(node, &NL, &size);

   if (size != stats.internal)
   {
      error("system error", "inconsistent tree size in report_tree_statistics",
	    TRUE);
   }
*/

   printf("\tTree has %d internal nodes, %d leaves, and %d values\n",
          stats.internal, stats.leaves, stats.values);
   /*
   printf("\tNon-linearity measure = %.2f\n", NL);
   fraction_covered(node, &covered, &correctness, 1.0);
   printf("Fraction of instance space adequately covered = %.2f\n", covered);
   printf("Estimated correctness of tree = %.3f\n", correctness);

   printf("   class       rules   antecedents\n");
   for (i = 0; i < attr_info->num_classes; ++i)
      printf("   %-10s  %6d  %6d\n",
	     attr_info->attributes[attr_info->class_index].labels[i],
	     stats.rules[i], stats.antes[i]);

*/

   check_free((void *)stats.rules);
   check_free((void *)stats.antes);

   return stats.internal;
}

void echo_key_parameters(msg, options) char *msg;
Options *options;
{
   char *method;

   printf("%s:\n", msg);

   switch (options->expansion_method)
   {
   case DEPTH_FIRST:
      method = "depth first";
      break;
   case BEST_FIRST:
      method = "best first";
      break;
   default:
      method = "unknown";
      break;
   }
   printf("\t%-40s: %s\n", "expansion method", method);
   if (options->expansion_method == DEPTH_FIRST)
   {
      printf("\t%-40s: %d\n", "stop depth", options->stop_depth);
   }
   else if (options->expansion_method == BEST_FIRST)
   {
      printf("\t%-40s: %d\n", "tree size limit", options->tree_size_limit);
      printf("\t%-40s: %f\n", "patience threshold",
             options->patience_threshold);
      printf("\t%-40s: %d\n", "patience counter",
             options->patience_counter);
   }

   switch (options->split_search_method)
   {
   case GREEDY:
      method = "greedy";
      break;
   case BEAM:
      method = "beam";
      break;
   case LOOKAHEAD:
      method = "lookahead";
      break;
   default:
      method = "unknown";
      break;
   }
   printf("\t%-40s: %s\n", "split search method", method);
   if (options->split_search_method == BEAM)
   {
      printf("\t%-40s: %d\n", "beam width", options->beam_width);
      printf("\t%-40s: %f\n", "mofn significance level", options->mofn_level);
   }

   switch (options->split_method)
   {
   case GAIN:
      method = "gain";
      break;
   case GAIN_RATIO:
      method = "gain ratio";
      break;
   case ORT:
      method = "ORT";
      break;
   default:
      method = "unknown";
      break;
   }
   printf("\t%-40s: %s\n", "split evaluation method", method);

   if (options->use_oracle)
   {
      printf("\t%-40s: %s\n", "use oracle", "yes");
   }
   else
   {
      printf("\t%-40s: %s\n", "use oracle", "no");
   }

   if (options->do_sampling)
   {
      printf("\t%-40s: %s\n", "use sampling", "yes");
      printf("\t%-40s: %d\n", "minimum sample", options->min_sample);
      switch (options->estimation_method)
      {
      case KERNEL:
         method = "kernel";
         break;
      case GAUSSIAN:
         method = "gaussian";
         break;
      case UNIFORM:
         method = "uniform";
         break;
      default:
         method = "unknown";
         break;
      }
      printf("\t%-40s: %s\n", "density estimation method", method);

      switch (options->distribution_type)
      {
      case LOCAL:
         method = "local";
         break;
      case GLOBAL:
         method = "global";
         break;
      default:
         method = "unknown";
         break;
      }
      printf("\t%-40s: %s\n", "estimated distributions", method);

      if (options->distribution_type == LOCAL)
      {
         printf("\t%-40s: %f\n", "minimum estimation fraction",
                options->min_estimation_fraction);
         printf("\t%-40s: %f\n", "local distribution significance level",
                options->distribution_alpha);
      }
   }
   else
   {
      printf("\t%-40s: %s\n", "sampling used", "no");
   }

   printf("\t%-40s: %f\n", "minimum objects", options->min_objects);
   printf("\n");
}


