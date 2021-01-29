#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "utils-exp.h"
#include "examples-exp.h"


extern char *strdup();



void free_examples(ex_info, attr_info)
   ExampleInfo *ex_info;
   AttributeInfo *attr_info;
{
   int i;

   for (i = 0; i < ex_info->size; ++i)
   {
      check_free((void *) ex_info->examples[i].name);

      if (ClassIsVector(attr_info))
         check_free((void *)
	      ex_info->examples[i].values[attr_info->class_index].value.vector);

      check_free((void *) ex_info->examples[i].values);
   }

   check_free((void *) ex_info->examples);
   ex_info->number = 0;
   ex_info->test_fold = NONE;
}


void free_attributes(attr_info)
   AttributeInfo *attr_info;
{
   int i, j;
   Attribute *attribute;

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      if (attribute->type == NOMINAL_ATTR)
      {
         for (j = 0; j < attr_info->number; ++j) {
            check_free((void *) attribute->labels[j]);
            check_free((void *) attribute->full_labels[j]);
            check_free((void *) attribute->full_labels_for_draw[j]);
            check_free((void *) attribute->value_is_in_ontology[j]);
            // check_free((void *) attribute->value_frequency_in_ontology[j]);
         }
         check_free((void *) attribute->labels);
         check_free((void *) attribute->full_labels);
         check_free((void *) attribute->full_labels_for_draw);
         check_free((void *) attribute->value_is_in_ontology);
         // check_free((void *) attribute->frequency);
         
         check_free((void *) attribute->map);
      }
      else if (attribute->type == REAL_ATTR)
      {
         check_free((void *) attribute->range);
         check_free((void *) attribute->original_range);
      }

      check_free((void *) attribute->name);
      check_free((void *) attribute->full_name);
   }

   check_free((void *) attr_info->attributes);
   attr_info->number = 0;
}


void reset_fold_info(examples)
   ExampleInfo *examples;
{
   int i;

   for (i = 0; i < examples->number; ++i)
      examples->examples[i].fold = 0;

   examples->test_fold = NONE;
}


void assign_to_folds(examples, num_folds)
   ExampleInfo *examples;
   int num_folds;
{
   Order *order;
   int fold;
   int i;

   order = (Order *) check_malloc(sizeof(Order) * examples->number);
   for (i = 0; i < examples->number; ++i)
   {
      order[i].index = i;
      order[i].value = my_random();
   }
   qsort((char *) order, examples->number, sizeof(Order), order_compare);

   for (i = 0; i < examples->number; ++i)
   {
      fold = num_folds * i / examples->number;
      examples->examples[order[i].index].fold = fold;
   }

   check_free((void *) order);
}



