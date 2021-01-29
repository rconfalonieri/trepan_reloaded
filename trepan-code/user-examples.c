#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "user-examples-int.h"

extern char *strdup();

static AttributeType match_attribute_type(type) char type;
{
   switch (type)
   {
   case 'n':
   case 'N':
      return (NOMINAL_ATTR);
   case 'r':
   case 'R':
      return (REAL_ATTR);
   case 'b':
   case 'B':
      return (BOOLEAN_ATTR);
   case 'v':
   case 'V':
      return (VECTOR_ATTR);
   default:
      sprintf(err_buffer, "`%c` is not a valid attribute type", type);
      error(prog_name, err_buffer, TRUE);
   }
}

static int lookup_attribute(name, attr_info, search_limit) char *name;
AttributeInfo *attr_info;
int search_limit;
{
   int i;

   for (i = 0; i < search_limit; ++i)
   {
      if (!strcasecmp(name, attr_info->attributes[i].name))
         break;
   }

   if (i == search_limit)
      return (NULL_ATTR);
   else
      return (i);
}

void read_attributes(fname, attr_info) char *fname;
AttributeInfo *attr_info;
{
   FILE *in_file;
   char buffer[BUFSIZ];
   char *token[100];
   char type;
   Attribute *attribute;
   int i, j;

   in_file = check_fopen(fname, "r");

   attr_info->number = 0;
   while (fgets(buffer, BUFSIZ, in_file))
      ++attr_info->number;
   rewind(in_file);

   if (attr_info->number < 2)
      error(prog_name, "attribute file must specify at least 2 attributes",
            TRUE);

   attr_info->attributes = (Attribute *)
       check_malloc(sizeof(Attribute) * attr_info->number);
   attr_info->class_index = attr_info->number - 1;

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      attribute->dependency = NULL_ATTR;

      if (fscanf(in_file, "%s %c", buffer, &type) != 2)
      {
         sprintf(err_buffer, "file %s is not in correct format", fname);
         error(prog_name, err_buffer, TRUE);
      }

      if (lookup_attribute(buffer, attr_info, i) != NULL_ATTR)
      {
         sprintf(err_buffer, "attribute name %s used more than once", buffer);
         error(prog_name, err_buffer, TRUE);
      }

      attribute->name = strdup(buffer);
      attribute->type = match_attribute_type(type);
      attribute->map = NULL;
      attribute->range = NULL;
      attribute->relevant = TRUE;

      if (attribute->type == VECTOR_ATTR && i != attr_info->class_index)
      {
         error(prog_name,
               "only the class attribute can have type = vector", TRUE);
      }

      if (attribute->type == NOMINAL_ATTR || attribute->type == VECTOR_ATTR)
      {
         fgets(buffer, BUFSIZ, in_file);
         attribute->num_values = 0;

         if (token[0] = strtok(buffer, " \t\n"))
         {
            ++attribute->num_values;
            while (token[attribute->num_values] = strtok((char *)NULL, " \t\n"))
               ++attribute->num_values;
         }

         if (attribute->num_values < 2)
         {
            sprintf(err_buffer,
                    "bad attribute %s (nominal attributes must have >= 2 values)",
                    attribute->name);
            error(prog_name, err_buffer, TRUE);
         }
         else if (attribute->num_values > MAX_ATTR_VALUES)
         {
            sprintf(err_buffer,
                    "attribute has too many values; the current limit is %d values",
                    MAX_ATTR_VALUES);
            error(prog_name, err_buffer, TRUE);
         }

         attribute->distribution = NULL;
         attribute->labels = (char **)
             check_malloc(sizeof(char *) * attribute->num_values);
         for (j = 0; j < attribute->num_values; ++j)
            attribute->labels[j] = strdup(token[j]);
      }
      else if (attribute->type == BOOLEAN_ATTR)
      {
         attribute->num_values = 2;
         attribute->distribution = NULL;
      }
      else if (attribute->type == REAL_ATTR)
      {
         attribute->num_values = 1;
         attribute->distribution = NULL;
         attribute->range = (Range *)check_malloc(sizeof(Range));
         attribute->range->min = DEFAULT_MIN;
         attribute->range->max = DEFAULT_MAX;
      }
   }

   attribute = &attr_info->attributes[attr_info->class_index];
   if (attribute->type == NOMINAL_ATTR || attribute->type == VECTOR_ATTR)
      attr_info->num_classes = attribute->num_values;
   else if (attribute->type == BOOLEAN_ATTR)
      attr_info->num_classes = 2;
   else
      error(prog_name,
            "the class attribute must be boolean, nominal or vector", TRUE);

   fclose(in_file);
}

static int match_boolean_value(label) char *label;
{
   if (!strcasecmp(label, "true") || !strcasecmp(label, "t"))
      return (1);
   else if (atoi(label) == 1)
      return (1);
   else if (!strcasecmp(label, "false") || !strcasecmp(label, "f"))
      return (0);
   else if (atoi(label) == 0)
      return (0);

   return (BAD_VALUE);
}

static int match_nominal_value(label, attribute) char *label;
Attribute *attribute;
{
   int i;

   for (i = 0; i < attribute->num_values; ++i)
   {
      if (!strcasecmp(label, attribute->labels[i]))
         return (i);
   }

   return (BAD_VALUE);
}

void read_examples(fnames, num_files, attr_info, ex_info) char **fnames;
int num_files;
AttributeInfo *attr_info;
ExampleInfo *ex_info;
{
   FILE *in_file;
   char buffer[BUFSIZ];
   Example *example;
   Attribute *attribute;
   int *last_in_file;
   int file_index;
   int i, j, k;
   int value;

   last_in_file = (int *)check_malloc(sizeof(int) * num_files);

   ex_info->number = 0;
   ex_info->test_fold = NONE;
   for (file_index = 0; file_index < num_files; ++file_index)
   {
      in_file = check_fopen(fnames[file_index], "r");
      while (fgets(buffer, BUFSIZ, in_file))
         ++ex_info->number;
      last_in_file[file_index] = ex_info->number;
      fclose(in_file);
   }
   ex_info->size = ex_info->number;

   for (file_index = 0; file_index < num_files; ++file_index)
      if ((file_index == 0 && last_in_file[0] == 0) || (file_index != 0 &&
                                                        last_in_file[file_index] == last_in_file[file_index - 1]))
      {
         sprintf(err_buffer, "examples file %s is empty", fnames[file_index]);
         error(prog_name, err_buffer, TRUE);
      }

   ex_info->examples = (Example *)check_malloc(sizeof(Example) * ex_info->size);

   file_index = 0;
   in_file = check_fopen(fnames[file_index], "r");
   for (i = 0; i < ex_info->number; ++i)
   {
      if (i == last_in_file[file_index])
      {
         ++file_index;
         fclose(in_file);
         in_file = check_fopen(fnames[file_index], "r");
      }

      example = &ex_info->examples[i];
      example->values = (Value *)
          check_malloc(sizeof(Value) * attr_info->number);

      if (fscanf(in_file, "%s", buffer) == EOF)
         error(prog_name, "examples file not in correct format", TRUE);
      example->name = strdup(buffer);
      example->fold = 0;
      example->oracle.missing = TRUE;

      for (j = 0; j < attr_info->number; ++j)
      {
         attribute = &attr_info->attributes[j];

         if (fscanf(in_file, "%s", buffer) == EOF)
            error(prog_name, "examples file not in correct format", TRUE);

         if (!strcmp(buffer, "?"))
         {
            if (j == attr_info->class_index)
            {
               error(prog_name,
                     "class attribute cannot have missing values", TRUE);
            }
            example->values[j].missing = TRUE;
         }
         else
         {
            example->values[j].missing = FALSE;

            if (attribute->type == REAL_ATTR)
            {
               if (sscanf(buffer, "%f", &example->values[j].value.real) != 1)
                  error(prog_name, "examples file not in correct format", TRUE);
            }
            else if (attribute->type == BOOLEAN_ATTR)
            {
               if ((value = match_boolean_value(buffer)) == BAD_VALUE)
               {
                  sprintf(err_buffer,
                          "bad examples file -- %s not a valid value for %s",
                          buffer, attribute->name);
                  error(prog_name, err_buffer, TRUE);
               }
               example->values[j].value.discrete = value;
            }
            else if (attribute->type == NOMINAL_ATTR)
            {
               if ((value = match_nominal_value(buffer, attribute)) == BAD_VALUE)
               {
                  sprintf(err_buffer,
                          "bad examples file -- %s not a valid value for %s",
                          buffer, attribute->name);
                  error(prog_name, err_buffer, TRUE);
               }
               example->values[j].value.discrete = value;
            }
            else if (attribute->type == VECTOR_ATTR)
            {
               example->values[j].value.vector =
                   check_malloc(sizeof(float) * attr_info->num_classes);

               example->values[j].value.vector[0] = (float)atof(buffer);
               for (k = 1; k < attr_info->num_classes; ++k)
               {
                  if (fscanf(in_file, "%s", buffer) == EOF)
                     error(prog_name, "examples file not in correct format",
                           TRUE);
                  example->values[j].value.vector[k] = (float)atof(buffer);
               }
            }
         }
      }
   }

   check_free((void *)last_in_file);

   fclose(in_file);
}

void read_attribute_mappings(fname, attr_info) char *fname;
AttributeInfo *attr_info;
{
   FILE *in_file;
   char buffer[BUFSIZ];
   Attribute *attr;
   Map *map;
   int index;
   int i, j;

   in_file = check_fopen(fname, "r");

   for (i = 0; i < attr_info->number; ++i)
      check_free((void *)attr_info->attributes[i].map);

   while (fscanf(in_file, "%s", buffer) == 1)
   {
      if ((index = lookup_attribute(buffer, attr_info,
                                    attr_info->number)) == NULL_ATTR)
      {
         sprintf(err_buffer, "unable to set map; unknown attribute %s", buffer);
         error(prog_name, err_buffer, TRUE);
      }

      attr = &attr_info->attributes[index];

      if (attr->type == NOMINAL_ATTR)
      {
         map = (Map *)check_malloc(sizeof(Map));
         if (fscanf(in_file, "%d", &map->size) != 1)
         {
            sprintf(err_buffer, "unable to read map size for %s", buffer);
            error(prog_name, err_buffer, TRUE);
         }

         if (map->size <= 0)
         {
            sprintf(err_buffer, "map size for %s must be greater than 0",
                    buffer);
            error(prog_name, err_buffer, TRUE);
         }

         map->vectors = (float **)check_malloc(sizeof(float *) *
                                               attr->num_values);
         for (i = 0; i < attr->num_values; ++i)
         {
            map->vectors[i] = (float *)check_malloc(sizeof(float) * map->size);
            for (j = 0; j < map->size; ++j)
               if (fscanf(in_file, "%f", &map->vectors[i][j]) != 1)
               {
                  sprintf(err_buffer, "failed to read map for value %s of %s",
                          attr->labels[i], buffer);
                  error(prog_name, err_buffer, TRUE);
               }
         }
      }
      else if (attr->type == REAL_ATTR)
      {
         map = (Map *)check_malloc(sizeof(Map));
         fgets(buffer, BUFSIZ, in_file);
      }
      else
      {
         sprintf(err_buffer,
                 "tried to set map for non real/nominal attribute (%s)", buffer);
         error(prog_name, err_buffer, TRUE);
      }

      attr->map = map;
   }

   fclose(in_file);
}

char is_attribute_in_ontology(type) char type;
{
   switch (type)
   {

   case '0':
      return (FALSE);
   case '1':
      return (TRUE);
   default:
      sprintf(err_buffer, "`%c` is not a valid attribute type", type);
      error(prog_name, err_buffer, TRUE);
   }
}

void read_attribute_values(fname, attr_info) char *fname;
AttributeInfo *attr_info;
{
   FILE *in_file;
   char buffer[BUFSIZ];
   char *p;
   char type;
   Attribute *attribute;
   int i, j;
   char full_name[50];

   in_file = check_fopen(fname, "r");

   for (i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      if (strcmp(attribute->name, "class") != 0)
      {

         if (fscanf(in_file, "%s %c %s", buffer, &type, full_name) != 3)
         {
            sprintf(err_buffer, "file %s is not in correct format", fname);
            error(prog_name, err_buffer, TRUE);
         }

         if (lookup_attribute(buffer, attr_info, i) != NULL_ATTR)
         {
            sprintf(err_buffer, "attribute name %s used more than once", buffer);
            error(prog_name, err_buffer, TRUE);
         }
         attribute->full_name = strdup(full_name);

         // printf("attribute->full_name %s\n", attribute->full_name);

         if (attribute->type == VECTOR_ATTR && i != attr_info->class_index)
         {
            error(prog_name,
                  "only the class attribute can have type = vector", TRUE);
         }
         //read the whole line
         fgets(buffer, BUFSIZ, in_file);
         // printf("buffer %s\n", buffer);
         // p = (char*)check_malloc(sizeof(char)*50);
         // p = strtok(buffer, " ");
         if (attribute->type == NOMINAL_ATTR)
         {

            // attribute->num_values = 0;
            int num_values = attribute->num_values;
            // printf("num_values %d\n", num_values);

            int k = 0;

            attribute->full_labels = (char **)check_malloc(sizeof(char *) * attribute->num_values);
            attribute->full_labels_for_draw = (char **)check_malloc(sizeof(char *) * attribute->num_values);
            // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
            p = strtok(buffer, " ");

            while (p != NULL)
            {
               char *tmp = extract_attribute_value_from_string(attribute->labels[k], p);
               // printf("tmp %s\n", tmp);
               attribute->full_labels[k] = (char *)check_malloc(sizeof(char) * (strlen(tmp) + 1));
               memset(attribute->full_labels[k], '\0', sizeof(char) * (strlen(tmp) + 1));
               memcpy(attribute->full_labels[k], tmp, sizeof(char) * strlen(tmp));

               // char *tmp_copy = (char *)check_malloc(sizeof(char) * strlen(tmp));
               // memcpy(tmp_copy, tmp, sizeof(char) * strlen(tmp));

               char *tmp_for_draw = extract_attribute_value_from_string_to_draw(attribute->full_name, tmp);
               // printf("tmp_for_draw %s\n", tmp_for_draw);
               attribute->full_labels_for_draw[k] = (char *)check_malloc(sizeof(char) * (strlen(tmp_for_draw) + 1));
               memset(attribute->full_labels_for_draw[k], '\0', sizeof(char) * (strlen(tmp_for_draw) + 1));
               memmove(attribute->full_labels_for_draw[k], tmp_for_draw, sizeof(char) * strlen(tmp_for_draw));

               free(tmp);
               // free(tmp_for_draw);
               ++k;
               // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
               p = strtok(NULL, " ");
            }
            // free(p);
         }

         else if (attribute->type == REAL_ATTR)
         {
            attribute->original_range = (Range *)check_malloc(sizeof(Range));
            int k = 0;
            // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
            p = strtok(buffer, " ");
            while (p != NULL)
            {
               // char *copy = strdup(p);
               // printf("copy %s\n", copy);
               if (k == 0)
               {
                  // char *tmp = extract_float_from_string2(p);
                  // attribute->original_range->min = atoi(tmp);
                  // free(tmp);
                  attribute->original_range->min = extract_float_from_string(p);
                  // printf("original_range->min %f\n", attribute->original_range->min);
               }
               else
               {
                  // char *tmp = extract_float_from_string2(p);
                  // attribute->original_range->max = atoi(tmp);
                  // free(tmp);
                  attribute->original_range->max = extract_float_from_string(p);
                  // printf("original_range->max %f\n", attribute->original_range->max);
               }
               ++k;
               // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
               p = strtok(NULL, " ");
            }
            // free(p);
         }
      }
      // class case
      else
      {
         if (fscanf(in_file, "%s %c %s", buffer, &type, full_name) != 3)
         {
            sprintf(err_buffer, "file %s is not in correct format", fname);
            error(prog_name, err_buffer, TRUE);
         }
         attribute->full_name = strdup(full_name);
         fgets(buffer, BUFSIZ, in_file);
         // if (attribute->type == NOMINAL_ATTR)
         // {
         int num_values = 2;
         // printf("num_values %d\n", num_values);

         int k = 0;
         attribute->full_labels = (char **)check_malloc(sizeof(char *) * attribute->num_values);
         attribute->full_labels_for_draw = (char **)check_malloc(sizeof(char *) * attribute->num_values);
         // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
         p = strtok(buffer, " ");

         while (p != NULL)
         {
            char *tmp = extract_attribute_value_from_string(attribute->labels[k], p);
            // printf("tmp %s\n", tmp);
            attribute->full_labels[k] = (char *)check_malloc(sizeof(char) * (strlen(tmp) + 1));
            memset(attribute->full_labels[k], '\0', sizeof(char) * (strlen(tmp) + 1));
            memcpy(attribute->full_labels[k], tmp, sizeof(char) * strlen(tmp));

            // char *tmp_copy = (char *)check_malloc(sizeof(char) * strlen(tmp));
            // memcpy(tmp_copy, tmp, sizeof(char) * strlen(tmp));

            char *tmp_for_draw = extract_attribute_value_from_string_to_draw(attribute->full_name, tmp);
            // printf("tmp_for_draw %s\n", tmp_for_draw);
            attribute->full_labels_for_draw[k] = (char *)check_malloc(sizeof(char) * (strlen(tmp_for_draw) + 1));
            memset(attribute->full_labels_for_draw[k], '\0', sizeof(char) * (strlen(tmp_for_draw) + 1));
            memmove(attribute->full_labels_for_draw[k], tmp_for_draw, sizeof(char) * strlen(tmp_for_draw));

            free(tmp);
            // free(tmp_for_draw);
            ++k;
            // p = (char *)check_malloc(sizeof(char) * ATTRIBUTEVALUESIZ);
            p = strtok(NULL, " ");
         }
         // }
      }
   }

   fclose(in_file);
}

void read_attributes_ontology(fname, attr_info) char *fname;
AttributeInfo *attr_info;
{
   FILE *in_file;
   FILE *out_file;

   char buffer[BUFSIZ];
   char type;
   float frequency;
   Attribute *attribute;
   int i;

   // out_file = fopen(fname, "w");

   // //this is needed to have a different random number generation at each run
   // srand(time(0));
   // for (int k = 0; k < attr_info->number; ++k)
   // {
   //    attribute = &attr_info->attributes[k];
   //    AttributeType type = attribute->type;

   //    if (strcmp(attribute->name, "class") != 0)
   //    {
   //       fprintf(out_file, "%s %d %f \n", attribute->full_name, rand() % 2, rand() / (float)RAND_MAX);
   //       // printf("read_attribute_values->full_name %s\n",attribute->full_name);
   //       if (attribute->type == NOMINAL_ATTR)
   //       {
   //          // int is_fake_boolean_attribute = 0;
   //          // printf("read_attribute_values %d\n",attribute->num_values);
   //          for (int x = 0; x < attribute->num_values; ++x)
   //          {
   //             // if (strcmp(attribute->full_labels[x], "yes") != 0 && strcmp(attribute->full_labels[x], "no") != 0 &&
   //             //     strcmp(attribute->full_labels[x], "true") != 0 && strcmp(attribute->full_labels[x], "false") != 0)
   //             // {
   //             fprintf(out_file, "%s %d %f \n", attribute->full_labels[x], rand() % 2, rand() / (float)RAND_MAX);
   //             // printf("read_attribute_values->full_labels_for_draw %s\n", attribute->full_labels_for_draw[x]);
   //             // printf("read_attribute_values->labels %s\n", attribute->labels[x]);
   //             // }
   //             // else
   //             // {
   //             //    is_fake_boolean_attribute = 1;
   //             // }
   //          }
   //          // if (is_fake_boolean_attribute == 1)
   //          //    fprintf(out_file, "%s %d \n", attribute->full_name, rand() % 2);
   //       }
   //       // else if (attribute->type == REAL_ATTR)
   //       // {

   //       //    // printf("read_attribute_values:full %s\n",attribute2->full_name);
   //       //    fprintf(out_file, "%s %d \n", attribute->full_name, rand() % 2);
   //       //    // printf("read_attribute_values:original_range->min %f\n", attribute->original_range->min);
   //       //    // printf("read_attribute_values:original_range->max %f\n", attribute->original_range->max);
   //       // }
   //    }
   // }

   // fclose(out_file);

   // JavaVM *jvm;
   // JNIEnv *env;
   // env = create_vm(&jvm);
   

   // invoke_class(env,fname,attr_info->ontology_filename);

   in_file = check_fopen(fname, "r");

   // while (fscanf(in_file, "%s %c", buffer, &type) != EOF)
   // {
   //    // printf("here: ");
   //    printf("%s: ", buffer);
   //    // printf("\n");
   //    printf("%c", type);
   //    printf("\n");

   //    attribute = &attr_info->attributes[i];
   //    attribute->is_in_ontology = is_attribute_in_ontology(type);
   //    i++;
   // }

   for (int i = 0; i < attr_info->number; ++i)
   {
      attribute = &attr_info->attributes[i];
      //we do not consider the class
      if (strcmp(attribute->name, "class") != 0)
      {
         fscanf(in_file, "%s %c %f", buffer, &type, &frequency);

         // printf("%s: ", buffer);
         // printf("%c\n", type);

         attribute->is_in_ontology = is_attribute_in_ontology(type);
         if (attribute->is_in_ontology == FALSE)
         {
            attribute->relevant = 0;
            // printf("attribute %s relevance is false", attribute->name);
         }

         attribute->frequency = frequency;
         int num_values = attribute->num_values;
         attribute->value_is_in_ontology = (char *)check_malloc(sizeof(char) * num_values);
         attribute->value_frequency_in_ontology = (float *)check_malloc(sizeof(float) * num_values);
         // printf("frequency attr: %f\n ", attribute->frequency);

         // printf("num_values: %d\n ", num_values);
         if (attribute->type != REAL_ATTR)
         {
            for (int j = 0; j < num_values; ++j)
            {
               fscanf(in_file, "%s %c %f", buffer, &type, &frequency);
               // printf("%s: ", buffer);
               // printf("%c\n", type);
               attribute->value_is_in_ontology[j] = (char)check_malloc(sizeof(char));
               // attribute->value_frequency_in_ontology[j] = (float)check_malloc(sizeof(float));
               attribute->value_is_in_ontology[j] = is_attribute_in_ontology(type);
               attribute->value_frequency_in_ontology[j] = frequency;
               // printf("frequency val: %f\n ", attribute->value_frequency_in_ontology[j]);
               // printf("frequency: %f\n ", frequency);
            }
         }
      }
   }

   fclose(in_file);

   
}
