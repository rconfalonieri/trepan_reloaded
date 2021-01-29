#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "tree.h"
#include "sample-exp.h"
#include "mofn-int.h"
#include "stats-exp.h"

static int same_member(a, b)
    Member *a;
Member *b;
{
   if (a->attribute != b->attribute)
      return (FALSE);

   if (a->type == REAL_ATTR)
   {
      if (a->value.real != b->value.real)
         return (FALSE);

      if (a->negated != b->negated)
         return (FALSE);
   }
   else if (a->value.discrete != b->value.discrete)
      return (FALSE);

   return (TRUE);
}

static int same_split(a, b)
    Split *a;
Split *b;
{
   Member *a_member, *b_member;
   int match;

   if (a->type != b->type)
      return (FALSE);
   else if (a->type == NOMINAL_SPLIT)
   {
      if (Get_Nominal_Attr(a) == Get_Nominal_Attr(b))
         return (TRUE);
      else
         return (FALSE);
   }
   else if (a->type == M_OF_N_SPLIT)
   {
      if (Get_M(a) != Get_M(b))
         return (FALSE);

      /* check to see if they have the same number of values */
      a_member = Get_Members(a);
      b_member = Get_Members(b);
      while (a_member && b_member)
      {
         a_member = a_member->next;
         b_member = b_member->next;
      }
      if (a_member || b_member)
         return (FALSE);

      a_member = Get_Members(a);
      while (a_member)
      {
         b_member = Get_Members(b);
         match = FALSE;
         while (!match && b_member)
         {
            if (same_member(a_member, b_member))
               match = TRUE;
            b_member = b_member->next;
         }
         if (!match)
            return (FALSE);

         a_member = a_member->next;
      }

      return (TRUE);
   }
   else if (a->type == REAL_SPLIT)
   {
      if (Get_Real_Attr(a) == Get_Real_Attr(b) &&
          Get_Threshold(a) == Get_Threshold(b))
         return (TRUE);
      else
         return (FALSE);
   }
   else if (a->type == BOOLEAN_SPLIT)
   {
      if (Get_Boolean_Attr(a) == Get_Boolean_Attr(b) &&
          Get_Boolean_Value(a) == Get_Boolean_Value(b))
         return (TRUE);
      else
         return (FALSE);
   }
   else
   {
      error("System error", "bad split type in same_split", TRUE);
   }
}

static Split *split_already_in_list(split, list)
    Split *split;
Split *list;
{
   while (list)
   {
      if (same_split(split, list))
         return (list);

      list = list->next;
   }

   return (FALSE);
}

Split *copy_split(attr_info, split)
    AttributeInfo *attr_info;
Split *split;
{
   Split *new_one;
   Member *member, *new_member;
   Member *list = NULL;
   Member *last_member = NULL;
   int i, j;

   new_one = get_new_split(split->type, split->arity, attr_info);
   new_one->gain = split->gain;

   for (i = 0; i < split->arity; ++i)
      for (j = 0; j < attr_info->num_classes; ++j)
         new_one->class_distr[i][j] = split->class_distr[i][j];

   if (split->type == NOMINAL_SPLIT)
   {
      new_one->type_specific.nominal.attribute = Get_Nominal_Attr(split);
   }
   else if (split->type == M_OF_N_SPLIT)
   {
      new_one->type_specific.mofn.m = split->type_specific.mofn.m;
      new_one->type_specific.mofn.sample_key = UNINITIALIZED_KEY;
      member = split->type_specific.mofn.members;
      while (member)
      {
         new_member = (Member *)check_malloc(sizeof(Member));
         memcpy((void *)new_member, (void *)member, sizeof(Member));
         /* keep list in same order */
         new_member->next = NULL;
         if (last_member)
            last_member->next = new_member;
         else
            list = new_member;
         last_member = new_member;

         member = member->next;
      }
      new_one->type_specific.mofn.members = list;
   }
   else if (split->type == REAL_SPLIT)
   {
      new_one->type_specific.real.attribute = Get_Real_Attr(split);
      new_one->type_specific.real.threshold = Get_Threshold(split);
   }
   else if (split->type == BOOLEAN_SPLIT)
   {
      new_one->type_specific.boolean.attribute = Get_Boolean_Attr(split);
      new_one->type_specific.boolean.value = Get_Boolean_Value(split);
      new_one->type_specific.boolean.bool_attr = Is_Boolean_Attr(split);
   }
   else
   {
      error("system error", "bad split type in copy_split", TRUE);
   }

   return (new_one);
}

static char **copy_and_update_used_structure(attr_info, source, copy, split)
    AttributeInfo *attr_info;
char **source;
char **copy;
Split *split;
{
   int i, j;
   Member *member;
   Attribute *attribute;

   if (!copy)
   {
      copy = (char **)check_malloc(sizeof(char *) * attr_info->number);
      for (i = 0; i < attr_info->number; ++i)
      {
         if (source[i])
         {
            attribute = &attr_info->attributes[i];
            copy[i] = check_malloc(sizeof(char) * attribute->num_values);
         }
         else
            copy[i] = NULL;
      }
   }

   for (i = 0; i < attr_info->number; ++i)
      if (source[i])
      {
         attribute = &attr_info->attributes[i];
         for (j = 0; j < attribute->num_values; ++j)
            copy[i][j] = source[i][j];
      }

   if (split->type == M_OF_N_SPLIT)
   {
      member = Get_Members(split);
      while (member)
      {
         if (member->type != REAL_ATTR)
            copy[member->attribute][member->value.discrete] = TRUE;
         member = member->next;
      }
   }
   else
   {
      error("system error",
            "only m-of-n splits handled in copy_and_update_used_structure",
            TRUE);
   }

   return (copy);
}

static void free_used_structure(attr_info, used)
    AttributeInfo *attr_info;
char **used;
{
   int i;

   for (i = 0; i < attr_info->number; ++i)
      if (used[i])
         check_free((void *)used[i]);

   check_free((void *)used);
}

static Member *remove_attribute(list, index)
    Member *list;
int index;
{
   Member *member, *last_member, *temp;

   last_member = NULL;
   member = list;
   while (member)
   {
      if (member->attribute == index)
      {
         if (last_member)
            last_member->next = member->next;
         else
            list = member->next;
         temp = member;
         member = member->next;
         check_free((void *)temp);
      }
      else
      {
         last_member = member;
         member = member->next;
      }
   }

   return (list);
}

static int superfluous_real_splits(member)
    Member *member;
{
   Member *temp;

   temp = member->next;
   while (temp)
   {
      if (temp->attribute == member->attribute &&
          temp->value.real == member->value.real)
         return (TRUE);

      temp = temp->next;
   }

   return (FALSE);
}

static void remove_superfluous_values(attr_info, split, base_used)
    AttributeInfo *attr_info;
Split *split;
char **base_used;
{
   int all_values_in_split;
   int i, j;
   char **used;
   Attribute *attribute;
   Member *member, *last_member;

   used = copy_and_update_used_structure(attr_info, base_used,
                                         (char **)NULL, split);

   /* check discrete-valued attributes */
   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      if (attribute->type != REAL_ATTR && used[i])
      {
         all_values_in_split = TRUE;
         for (j = 0; j < attribute->num_values; ++j)
         {
            if (!used[i][j])
            {
               all_values_in_split = FALSE;
               break;
            }
         }

         if (all_values_in_split)
         {
            --split->type_specific.mofn.m;
            split->type_specific.mofn.members =
                remove_attribute(split->type_specific.mofn.members, i);
         }
      }
   }

   /* check real-valued attributes */
   last_member = NULL;
   member = split->type_specific.mofn.members;
   while (member)
   {
      if (member->type == REAL_ATTR && superfluous_real_splits(member))
      {
         --split->type_specific.mofn.m;
         member = remove_attribute(member, member->attribute);
         if (last_member)
            last_member->next = member;
         else
            split->type_specific.mofn.members = member;
      }
      else
      {
         last_member = member;
         member = member->next;
      }
   }

   free_used_structure(attr_info, used);
}

static void insert_split_in_beam(split, beam)
    Split *split;
Beam *beam;
{
   Split *current, *temp;

   if (split->type == M_OF_N_SPLIT)
      split->type_specific.mofn.expanded = FALSE;

   if (beam->head == NULL)
   {
      beam->head = beam->tail = split;
      beam->n = 1;
   }
   else
   {
      /* find the right spot in the beam */
      current = beam->head;
      while (current && current->gain >= split->gain)
         current = current->next;

      if (current && !split_already_in_list(split, beam->head))
      {
         /* add the split to the beam */
         split->prev = current->prev;
         split->next = current;
         current->prev = split;
         if (split->prev)
            split->prev->next = split;
         else
            beam->head = split;

         /* bump a split out of the beam if necessary */
         if (beam->n == beam->width)
         {
            beam->tail->prev->next = NULL;
            temp = beam->tail;
            beam->tail = beam->tail->prev;
            free_split(temp);
         }
         else
         {
            ++beam->n;
         }
      }
      else if (beam->n < beam->width &&
               !split_already_in_list(split, beam->head))
      {
         split->prev = beam->tail;
         split->next = NULL;
         beam->tail->next = split;
         beam->tail = split;
         ++beam->n;
      }
      else
      {
         free_split(split);
      }
   }
}

static int splits_significantly_different(attr_info, old_split,
                                          new_split, options)
    AttributeInfo *attr_info;
Split *old_split;
Split *new_split;
Options *options;
{
   int degrees;
   float chi_square_value;
   float prob;

   chi_square(old_split->class_distr[0], new_split->class_distr[0],
              attr_info->num_classes, 0, &degrees, &chi_square_value, &prob);

   /*
printf("(%.0f, %.0f) (%.0f, %.0f)\tChi Square value = %f\n",
       old_split->class_distr[0][0], old_split->class_distr[0][1],
       new_split->class_distr[0][0], new_split->class_distr[0][1], prob);
*/

   new_split->type_specific.mofn.chi_square_prob = prob;

   if (prob < options->mofn_level)
      return (TRUE);
   else
      return (FALSE);
}

static void evaluate_candidate(attr_info, ex_info, ex_mask, options,
                               beam, used, split, old_split)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
Beam *beam;
char **used;
Split *split;
Split *old_split;
{

   remove_superfluous_values(attr_info, split, used);

   if (Get_M(split) == 0 || Get_Members(split) == NULL)
      free_split(split);
   else
   {
      evaluate_splits(attr_info, ex_info, ex_mask, options, split);

      if (!trivial_split(split, options->min_objects) &&
          splits_significantly_different(attr_info, old_split, split, options) &&
          (!options->do_sampling ||
           !trivial_split_when_sampling(split, ex_info, ex_mask, options)))
         insert_split_in_beam(split, beam);
      else
         free_split(split);
   }
}

static int okay_to_add_discrete(to_add, used)
    Split *to_add;
char **used;
{
   int attr_index;
   int value;

   if (to_add->type != BOOLEAN_SPLIT)
      error("System error", "bad split type in okay_to_add_discrete", TRUE);

   if (!to_add->can_use)
      return (FALSE);

   attr_index = Get_Boolean_Attr(to_add);
   value = Get_Boolean_Value(to_add);
   if (!used[attr_index])
      return (FALSE);

   if (!Is_Boolean_Attr(to_add) && used[attr_index][value])
      return (FALSE);

   return (TRUE);
}

static int okay_to_add_real(current, to_add, used, other)
    Split *current;
Split *to_add;
char **used;
Member **other;
{
   Member *member;
   int attr_index;

   if (to_add->type != REAL_SPLIT)
      error("System error", "bad split type in okay_to_add_real", TRUE);

   if (!to_add->can_use)
      return (FALSE);

   attr_index = Get_Real_Attr(to_add);
   if (!used[attr_index])
      return (FALSE);

   /* disallow if there are alreay 2 conditions for this attribute */
   *other = NULL;
   for (member = Get_Members(current); member != NULL; member = member->next)
   {
      if (member->attribute == attr_index)
      {
         if (*other)
            return (FALSE);
         else
            *other = member;
      }
   }

   return (TRUE);
}

static int okay_together(to_add, negated, other)
    Split *to_add;
Member *other;
char negated;
{
   if (!other)
      return (TRUE);

   /* make sure new condition isn't implied by exisiting one */
   if (other->negated == FALSE && negated == FALSE)
   {
      if (Get_Threshold(to_add) <= other->value.real)
         return (FALSE);
   }
   else if (other->negated == TRUE && negated == TRUE)
   {
      if (Get_Threshold(to_add) > other->value.real)
         return (FALSE);
   }

   return (TRUE);
}

void mofn_plus_1(attr_info, ex_info, ex_mask, options,
                 beam, current, splits, used)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
Beam *beam;
Split *current;
Split *splits;
char **used;
{
   int attr_index;
   Split *new_split, *to_add;
   Member *new_member;
   Member *other;

   to_add = splits;
   while (to_add)
   {
      attr_index = Get_Boolean_Attr(to_add);
      if (to_add->type == REAL_SPLIT)
      {
         other = NULL;
         if (okay_to_add_real(current, to_add, used, &other))
         {
            if (!other || okay_together(to_add, FALSE, other))
            {
               new_split = copy_split(attr_info, current);
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Real_Attr(to_add);
               new_member->value.real = Get_Threshold(to_add);
               new_member->type = REAL_ATTR;
               new_member->negated = FALSE;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }

            if (!other || okay_together(to_add, TRUE, other))
            {
               new_split = copy_split(attr_info, current);
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Real_Attr(to_add);
               new_member->value.real = Get_Threshold(to_add);
               new_member->type = REAL_ATTR;
               new_member->negated = TRUE;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }
         }
      }
      else if (Is_Boolean_Attr(to_add))
      {
         if (okay_to_add_discrete(to_add, used))
         {
            /* make a new split where boolean is false */
            if (!used[attr_index][0])
            {
               new_split = copy_split(attr_info, current);
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Boolean_Attr(to_add);
               new_member->value.discrete = 0;
               new_member->type = BOOLEAN_ATTR;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }

            /* make a new split where boolean is true */
            if (!used[attr_index][1])
            {
               new_split = copy_split(attr_info, current);
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Boolean_Attr(to_add);
               new_member->value.discrete = 1;
               new_member->type = BOOLEAN_ATTR;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }
         }
      }
      else
      {
         if (okay_to_add_discrete(to_add, used))
         {
            new_split = copy_split(attr_info, current);
            new_member = (Member *)check_malloc(sizeof(Member));
            new_member->attribute = Get_Boolean_Attr(to_add);
            new_member->value.discrete = Get_Boolean_Value(to_add);
            new_member->type = NOMINAL_ATTR;
            new_member->next = new_split->type_specific.mofn.members;
            new_split->type_specific.mofn.members = new_member;
            evaluate_candidate(attr_info, ex_info, ex_mask, options,
                               beam, used, new_split, current);
         }
      }

      to_add = to_add->next;
   }
}

void m_plus_1_of_n_plus_1(attr_info, ex_info, ex_mask, options,
                          beam, current, splits, used)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
Beam *beam;
Split *current;
Split *splits;
char **used;
{
   int attr_index;
   Split *new_split, *to_add;
   Member *new_member;
   Member *other;

   to_add = splits;
   while (to_add)
   {
      attr_index = Get_Boolean_Attr(to_add);
      if (to_add->type == REAL_SPLIT)
      {
         other = NULL;
         if (okay_to_add_real(current, to_add, used, &other))
         {
            if (!other || okay_together(to_add, FALSE, other))
            {
               new_split = copy_split(attr_info, current);
               new_split->type_specific.mofn.m += 1;
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Real_Attr(to_add);
               new_member->value.real = Get_Threshold(to_add);
               new_member->type = REAL_ATTR;
               new_member->negated = FALSE;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }

            if (!other || okay_together(to_add, TRUE, other))
            {
               new_split = copy_split(attr_info, current);
               new_split->type_specific.mofn.m += 1;
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Real_Attr(to_add);
               new_member->value.real = Get_Threshold(to_add);
               new_member->type = REAL_ATTR;
               new_member->negated = TRUE;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }
         }
      }
      else if (Is_Boolean_Attr(to_add))
      {
         if (okay_to_add_discrete(to_add, used))
         {
            /* make a new split where boolean is false */
            if (!used[attr_index][0])
            {
               new_split = copy_split(attr_info, current);
               new_split->type_specific.mofn.m += 1;
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Boolean_Attr(to_add);
               new_member->value.discrete = 0;
               new_member->type = BOOLEAN_ATTR;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }

            /* make a new split where boolean is true */
            if (!used[attr_index][1])
            {
               new_split = copy_split(attr_info, current);
               new_split->type_specific.mofn.m += 1;
               new_member = (Member *)check_malloc(sizeof(Member));
               new_member->attribute = Get_Boolean_Attr(to_add);
               new_member->value.discrete = 1;
               new_member->type = BOOLEAN_ATTR;
               new_member->next = new_split->type_specific.mofn.members;
               new_split->type_specific.mofn.members = new_member;
               evaluate_candidate(attr_info, ex_info, ex_mask, options,
                                  beam, used, new_split, current);
            }
         }
      }
      else
      {
         if (okay_to_add_discrete(to_add, used))
         {
            new_split = copy_split(attr_info, current);
            new_split->type_specific.mofn.m += 1;
            new_member = (Member *)check_malloc(sizeof(Member));
            new_member->attribute = Get_Boolean_Attr(to_add);
            new_member->value.discrete = Get_Boolean_Value(to_add);
            new_member->type = NOMINAL_ATTR;
            new_member->next = new_split->type_specific.mofn.members;
            new_split->type_specific.mofn.members = new_member;
            evaluate_candidate(attr_info, ex_info, ex_mask, options,
                               beam, used, new_split, current);
         }
      }

      to_add = to_add->next;
   }
}

static Split *real_to_mofn_split(attr_info, real_split, complement_split)
    AttributeInfo *attr_info;
Split *real_split;
int complement_split;
{
   Split *mofn_split;
   Member *member;
   int i;

   mofn_split = get_new_split(M_OF_N_SPLIT, 2, attr_info);
   mofn_split->gain = real_split->gain;
   mofn_split->type_specific.mofn.sample_key = UNINITIALIZED_KEY;
   mofn_split->type_specific.mofn.chi_square_prob = 0.0;

   member = (Member *)check_malloc(sizeof(Member));
   member->attribute = Get_Real_Attr(real_split);
   member->value.real = Get_Threshold(real_split);
   member->type = REAL_ATTR;
   member->negated = (char)complement_split;
   member->next = NULL;

   mofn_split->type_specific.mofn.members = member;
   mofn_split->type_specific.mofn.m = 1;

   for (i = 0; i < attr_info->num_classes; ++i)
      if (complement_split)
      {
         mofn_split->class_distr[0][i] = real_split->class_distr[1][i];
         mofn_split->class_distr[1][i] = real_split->class_distr[0][i];
      }
      else
      {
         mofn_split->class_distr[0][i] = real_split->class_distr[0][i];
         mofn_split->class_distr[1][i] = real_split->class_distr[1][i];
      }

   return (mofn_split);
}

static Split *boolean_to_mofn_split(attr_info, boolean_split, complement_split)
    AttributeInfo *attr_info;
Split *boolean_split;
int complement_split;
{
   Split *mofn_split;
   Member *member;
   Attribute *attribute;
   int i;

   mofn_split = get_new_split(M_OF_N_SPLIT, 2, attr_info);
   mofn_split->gain = boolean_split->gain;
   mofn_split->type_specific.mofn.sample_key = UNINITIALIZED_KEY;
   mofn_split->type_specific.mofn.chi_square_prob = 0.0;
   attribute = &attr_info->attributes[Get_Boolean_Attr(boolean_split)];

   if (attribute->type == BOOLEAN_ATTR)
   {
      member = (Member *)check_malloc(sizeof(Member));
      member->attribute = Get_Boolean_Attr(boolean_split);
      member->value.discrete = complement_split ? 1 - Get_Boolean_Value(boolean_split) : Get_Boolean_Value(boolean_split);
      member->type = attribute->type;
      member->next = NULL;
      mofn_split->type_specific.mofn.members = member;
   }
   else
   {
      if (complement_split)
      {
         mofn_split->type_specific.mofn.members = NULL;
         for (i = 0; i < attribute->num_values; ++i)
            if (i != Get_Boolean_Value(boolean_split))
            {
               member = (Member *)check_malloc(sizeof(Member));
               member->attribute = Get_Boolean_Attr(boolean_split);
               member->value.discrete = i;
               member->type = attribute->type;
               member->next = mofn_split->type_specific.mofn.members;
               mofn_split->type_specific.mofn.members = member;
            }
      }
      else
      {
         member = (Member *)check_malloc(sizeof(Member));
         member->attribute = Get_Boolean_Attr(boolean_split);
         member->value.discrete = Get_Boolean_Value(boolean_split);
         member->type = attribute->type;
         member->next = NULL;
         mofn_split->type_specific.mofn.members = member;
      }
   }

   mofn_split->type_specific.mofn.m = 1;

   for (i = 0; i < attr_info->num_classes; ++i)
      if (complement_split)
      {
         mofn_split->class_distr[0][i] = boolean_split->class_distr[1][i];
         mofn_split->class_distr[1][i] = boolean_split->class_distr[0][i];
      }
      else
      {
         mofn_split->class_distr[0][i] = boolean_split->class_distr[0][i];
         mofn_split->class_distr[1][i] = boolean_split->class_distr[1][i];
      }

   return (mofn_split);
}

static char **make_used_structure(attr_info, constraints, constrain_attributes)
    AttributeInfo *attr_info;
Constraint **constraints;
int constrain_attributes;
{
   char **used;
   Constraint *constraint;
   Split *split;
   int can_use;
   int i, j;
   Attribute *attribute;

   used = (char **)check_malloc(sizeof(char *) * attr_info->number);

   for (i = 0; i < attr_info->number; ++i)
   {
      can_use = TRUE;
      constraint = constraints[i];
      while (constraint)
      {
         split = constraint->split;
         if ((split->type == M_OF_N_SPLIT && constrain_attributes) ||
             (split->type == BOOLEAN_SPLIT && Is_Boolean_Attr(split)))
         {
            can_use = FALSE;
            break;
         }
         constraint = constraint->next;
      }

      if (can_use)
      {
         attribute = &attr_info->attributes[i];
         used[i] = check_malloc(sizeof(char) * attribute->num_values);

         if (attribute->type == REAL_ATTR)
         {
            used[i][0] = TRUE;
         }
         else
         {
            for (j = 0; j < attribute->num_values; ++j)
               used[i][j] = FALSE;

            /* determine which values can't be used */
            constraint = constraints[i];
            while (constraint)
            {
               split = constraint->split;
               if (split->type == BOOLEAN_SPLIT)
                  used[i][Get_Boolean_Value(split)] = TRUE;
               constraint = constraint->next;
            }
         }
      }
      else
         used[i] = NULL;
   }

   return (used);
}

static void print_beam(attr_info, beam)
    AttributeInfo *attr_info;
Beam *beam;
{
   Split *split;
   int i;

   printf("========== BEAM HAS %d SPLITS ==========\n\n", beam->n);

   split = beam->head;
   while (split)
   {
      print_split(split, attr_info, 0, stdout);
      printf(" gain=%f", split->gain);
      if (split->type == M_OF_N_SPLIT)
         printf("  chi=%f\n", split->type_specific.mofn.chi_square_prob);
      else
         printf("\n");

      printf("\tpos\tneg\n");
      for (i = 0; i < attr_info->num_classes; ++i)
         printf("\t%.0f\t%.0f\n", split->class_distr[0][i],
                split->class_distr[1][i]);

      split = split->next;
   }
}

static void merge_beam_levels(beam, next_beam)
    Beam *beam;
Beam *next_beam;
{
   Split *current, *next;

   current = next_beam->head;
   while (current)
   {
      next = current->next;
      insert_split_in_beam(current, beam);
      current = next;
   }

   next_beam->n = 0;
   next_beam->head = next_beam->tail = NULL;
}

static void mofn_beam_search(attr_info, ex_info, ex_mask, options,
                             splits, beam, base_used)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
Split *splits;
Beam *beam;
char **base_used;
{
   Split *current;
   char **used = NULL;
   int i;
   int all_expanded;
   Beam next_beam;

   next_beam.width = beam->width;
   next_beam.n = 0;
   next_beam.head = next_beam.tail = NULL;

   do
   {
      /*
print_beam(attr_info, beam);
*/
      all_expanded = TRUE;
      current = beam->head;
      while (current)
      {
         if (current->type == M_OF_N_SPLIT &&
             !current->type_specific.mofn.expanded)
         {
            all_expanded = FALSE;
            current->type_specific.mofn.expanded = TRUE;
            used = copy_and_update_used_structure(attr_info, base_used,
                                                  used, current);
            for (i = 0; i < options->num_mofn_ops; ++i)
               (options->mofn_ops[i])(attr_info, ex_info, ex_mask, options,
                                      &next_beam, current, splits, used);
         }
         current = current->next;
      }

      merge_beam_levels(beam, &next_beam);
   } while (!all_expanded);

   if (used)
      free_used_structure(attr_info, used);
}

static void initialize_beam(attr_info, ex_info, ex_mask, options, splits,
                            beam, used)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
Split *splits;
Beam *beam;
char **used;
{
   Split *current, *new_split;

   beam->head = beam->tail = NULL;
   beam->n = 0;

   evaluate_splits(attr_info, ex_info, ex_mask, options, splits);

   /*
print_splits(attr_info, splits, stdout);
*/

   current = splits;
   while (current)
   {
      if (current->can_use && !trivial_split(current, options->min_objects) &&
          (!options->do_sampling || !trivial_split_when_sampling(current, ex_info, ex_mask, options)))
      {
         if (current->type == BOOLEAN_SPLIT && used[Get_Boolean_Attr(current)])
         {
            new_split = boolean_to_mofn_split(attr_info, current, FALSE);
            insert_split_in_beam(new_split, beam);
            new_split = boolean_to_mofn_split(attr_info, current, TRUE);
            insert_split_in_beam(new_split, beam);
         }
         else if (current->type == REAL_SPLIT && used[Get_Real_Attr(current)])
         {
            new_split = real_to_mofn_split(attr_info, current, FALSE);
            insert_split_in_beam(new_split, beam);
            new_split = real_to_mofn_split(attr_info, current, TRUE);
            insert_split_in_beam(new_split, beam);
         }
         else
         {
            new_split = copy_split(attr_info, current);
            insert_split_in_beam(new_split, beam);
         }
      }
      current = current->next;
   }
}

static void nth_member(split, n, prev, nth)
    Split *split;
int n;
Member **prev;
Member **nth;
{
   int i;

   *prev = NULL;
   *nth = Get_Members(split);

   for (i = 0; i < n; ++i)
   {
      *prev = *nth;
      *nth = (*nth)->next;
   }
}

static void backfit_split(split, attr_info, ex_info, ex_mask, options)
    Split *split;
AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Options *options;
{
   int count;
   float best_gain = split->gain;
   Member *prev, *member;
   int *value_counts;
   int improved;
   int i;

   if (split->next)
      error("System error", "split is part of a list in backfit_split", TRUE);

   value_counts = (int *)check_malloc(sizeof(int) * attr_info->number);
   for (i = 0; i < attr_info->number; ++i)
      value_counts[i] = 0;

   for (count = 0, member = Get_Members(split); member != NULL;
        ++count, member = member->next)
   {
      ++value_counts[member->attribute];
   }

   for (i = count - 1; i >= 0; --i)
   {
      improved = FALSE;

      /* find the ith member */
      nth_member(split, i, &prev, &member);

      /* try deleting the member */
      if (prev)
         prev->next = member->next;
      else
         split->type_specific.mofn.members = member->next;

      /* try new antecedent set with m the same */
      evaluate_splits(attr_info, ex_info, ex_mask, options, split);

      if (!trivial_split(split, options->min_objects) &&
          (!options->do_sampling || !trivial_split_when_sampling(split, ex_info, ex_mask, options)) && split->gain >= best_gain)
      {
         best_gain = split->gain;
         improved = TRUE;
      }

      /* try new antecedent set with m decremented by 1 */
      --split->type_specific.mofn.m;
      evaluate_splits(attr_info, ex_info, ex_mask, options, split);

      if (!trivial_split(split, options->min_objects) &&
          (!options->do_sampling || !trivial_split_when_sampling(split, ex_info, ex_mask, options)) &&
          split->gain >= best_gain)
      {
         best_gain = split->gain;
         improved = TRUE;
      }
      else
      {
         ++split->type_specific.mofn.m;
      }

      if (!improved)
      {
         /* put member back on */
         if (prev)
            prev->next = member;
         else
            split->type_specific.mofn.members = member;
      }
      else
      {
         if (member->type == REAL_ATTR)
            printf("IMPROVED SPLIT IN BACKFIT by deleting attr=%d, val=%f\n",
                   member->attribute, member->value.real);
         else
            printf("IMPROVED SPLIT IN BACKFIT by deleting attr=%d, val=%d\n",
                   member->attribute, member->value.discrete);
      }
   }

   /* make sure statistics are up to date */
   evaluate_splits(attr_info, ex_info, ex_mask, options, split);

   check_free((void *)value_counts);
}

Split *ID2_of_3_beam(attr_info, ex_info, ex_mask, constraints, options, splits)
    AttributeInfo *attr_info;
ExampleInfo *ex_info;
float *ex_mask;
Constraint **constraints;
Options *options;
Split *splits;
{
   Beam beam;
   char **used;
   Split *best_split = NULL;

   beam.width = options->beam_width;

   used = make_used_structure(attr_info, constraints, options->do_sampling);

   initialize_beam(attr_info, ex_info, ex_mask, options, splits, &beam, used);
   mofn_beam_search(attr_info, ex_info, ex_mask, options, splits, &beam, used);

   free_used_structure(attr_info, used);

   if (!beam.head)
      return (NULL);

   if (beam.head->type != M_OF_N_SPLIT)
      best_split = split_already_in_list(beam.head, splits);

   if (best_split)
   {
      free_unused_splits(beam.head);
   }
   else
   {
      free_unused_splits(beam.head->next);
      best_split = beam.head;
      best_split->next = NULL;
   }

   if (best_split && best_split->type == M_OF_N_SPLIT)
      backfit_split(best_split, attr_info, ex_info, ex_mask, options);

   return (best_split);
}
