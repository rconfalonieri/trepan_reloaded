#include <stdlib.h>
#include <stdio.h>
#include "utils-exp.h"

char err_buffer[BUFSIZ];
char *prog_name = "";

/*  
   Handle an error.
*/
void error(bullet, msg, do_exit) char *bullet;
char *msg;
int do_exit;
{
   fprintf(stderr, "%s: %s\n", bullet, msg);
   if (do_exit)
      exit(1);
}

/*  
   Do a malloc and check to see if it was successful.
*/
void *check_malloc(size) unsigned int size;
{
   void *p;

   p = (void *)malloc(size);
   if (p)
      return (p);
   else
      error(prog_name, "malloc failed", TRUE);
}

/*
   Do a free.  First check to make sure that the pointer is non-NULL.
*/
void check_free(p) void *p;
{
   if (p)
      free((char *)p);
}

/*  Given string containing a UNIX command, call a shell to execute this
    command.  Return TRUE if the command executes successfully.
*/
void check_system(command) char *command;
{
   if (system(command) == 127)
   {
      sprintf(err_buffer, "unable to execute: %s", command);
      error("system call failure", err_buffer, TRUE);
   }
}

FILE *check_fopen(fname, type) char *fname;
char *type;
{
   FILE *f;

   if ((f = fopen(fname, type)) == NULL)
   {
      sprintf(err_buffer, "unable to open file %s", fname);
      error(prog_name, err_buffer, TRUE);
   }

   return (f);
}

int **get_confusion_matrix(dimension) int dimension;
{
   int i, j;
   int **matrix;

   matrix = (int **)check_malloc(sizeof(int *) * dimension);
   for (i = 0; i < dimension; ++i)
   {
      matrix[i] = (int *)check_malloc(sizeof(int) * dimension);
      for (j = 0; j < dimension; ++j)
         matrix[i][j] = 0;
   }

   return (matrix);
}

void reset_confusion_matrix(matrix, dimension) int **matrix;
int dimension;
{
   int i, j;

   for (i = 0; i < dimension; ++i)
      for (j = 0; j < dimension; ++j)
         matrix[i][j] = 0;
}

void free_confusion_matrix(matrix, dimension) int **matrix;
int dimension;
{
   int i;

   for (i = 0; i < dimension; ++i)
      check_free((void *)matrix[i]);

   check_free((void *)matrix);
}

void print_measure(matrix, dimension, set, measure) int **matrix;
int dimension;
char *set;
char *measure;
{
   int i, j;
   int correct = 0;
   int total = 0;

   for (i = 0; i < dimension; ++i)
      for (j = 0; j < dimension; ++j)
      {
         total += matrix[i][j];
         if (i == j)
            correct += matrix[i][j];
      }

   printf("%s Set %s: %d/%d = %.3f\n", set, measure, correct, total,
          correct / (float)total);
}

void print_confusion_matrix(matrix, dimension, col_label, row_label) int **matrix;
int dimension;
char *col_label;
char *row_label;
{
   int i, j;
   int *col_totals;
   int row_total;
   int total = 0;

   col_totals = (int *)check_malloc(sizeof(int) * dimension);
   for (i = 0; i < dimension; ++i)
      col_totals[i] = 0;

   printf("\n\t\t%s\n\t\t", col_label);
   for (i = 0; i < dimension; ++i)
      printf("%6d", i + 1);
   printf("\n\t\t|");
   for (i = 0; i < dimension; ++i)
      printf("------");
   printf("-|------\n");
   for (i = 0; i < dimension; ++i)
   {
      row_total = 0;

      if (!i)
         printf("%-9s %2d\t|", row_label, i + 1);
      else if (i < dimension)
         printf("          %2d\t|", i + 1);
      else
         printf("           X \t|");
      for (j = 0; j < dimension; ++j)
      {
         printf("%5d ", matrix[i][j]);
         col_totals[j] += matrix[i][j];
         row_total += matrix[i][j];
         total += matrix[i][j];
      }
      printf(" | %5d\n", row_total);
   }
   printf("\t\t|");
   for (i = 0; i < dimension; ++i)
      printf("------");
   printf("-|------\n");

   printf("\t\t|");
   for (i = 0; i < dimension; ++i)
      printf("%5d ", col_totals[i]);
   printf(" | %5d\n\n", total);

   check_free((void *)col_totals);
}

int float_compare(a, b) float *a;
float *b;
{
   if (*a > *b)
      return (1);
   else if (*a == *b)
      return (0);
   else
      return (-1);
}

int order_compare(a, b)
    Order *a;
Order *b;
{
   if (a->value > b->value)
      return (1);
   else if (a->value == b->value)
      return (0);
   else
      return (-1);
}

void my_srandom(seed) long int seed;
{
   srand48(seed);
}

double my_random()
{
   extern double drand48();

   return (drand48());
}

void bzero(array, length) char *array;
int length;
{
   int i;

   for (i = 0; i < length; ++i)
      array[i] = '\0';
}

char *my_strcopy(char *str1) {
  int x = 0;

  /* change the size of string2 to the size of string1 */
  char *str2 = (char *)check_malloc(sizeof(char) * (strlen(str1)));

  do {
    str2[x] = str1[x];
  } while (str1[x++] != '\0');

   return str2;
}

// char *extract_char_from_string(value) char *value;
// {
//    int string_len = strlen(value);
//    char dest[string_len + 1]; // string_len-6 chars + terminator */
//    memset(dest, '\0', sizeof(dest));
//    strcpy(dest, value);
//    return dest;
// }

float extract_float_from_string(min_max_str) 
char *min_max_str;
{
   //(min,2) or (max,0.2)
   char *min_max_str_copy = strdup(min_max_str);
   int string_len = strlen(min_max_str_copy);
   // printf("min_max_str %s\n " ,min_max_str);

   if (min_max_str_copy[string_len - 1] == '\n')
   {
      // char dest[string_len - 6]; // string_len-6 chars + terminator */
      char *dest = (char *)check_malloc(sizeof(char) * (string_len - 6));
      memset(dest, '\0', sizeof(char) * (string_len - 6));
      strncpy(dest, min_max_str_copy + 5, string_len - 7);
      // dest[string_len-5] = '\0';
      // printf("dest %s\n " ,dest);
      float result = atof(dest);
      free(dest);
      free(min_max_str_copy);
      
      // printf("result %f\n " ,result);
      return result;
   }
   else
   {
      // printf("length %d\n " ,string_len);
      // char dest[string_len - 5]; // string_len-6 chars + terminator */
      char *dest = (char *)check_malloc(sizeof(char) * (string_len - 5));
      memset(dest, '\0', sizeof(char) * (string_len - 5));
      strncpy(dest, min_max_str_copy + 5, string_len - 6);
      // dest[string_len-5] = '\0';
      // printf("dest %s\n " ,dest);
      float result = atof(dest);
      free(dest);
      free(min_max_str_copy);
      // printf("result %f\n " ,result);
      return result;
   }
}


char *extract_attribute_value_from_string(label, full_label) 
char *label;
char *full_label;
{
   //(label,full_label)
   //(1,slope_peak_exercise_ST_segment_is_upsloping)

   // int is_last_chat_new_line = 0;
   // printf("extract_attribute_value_from_string->full_label %s\n ", full_label);
   char *full_label_copy = strdup(full_label);
   int label_len = strlen(label);
   // printf("extract_attribute_value_from_string->label_len %d\n ", label_len);
   int string_len = strlen(full_label_copy);
   // printf("extract_attribute_value_from_string->string_len %d\n ", string_len);

   if (full_label_copy[string_len - 1] == '\n')
   {
      // printf("full_label[string_len-1] == 'n'");
      // is_last_chat_new_line = 1;
      char *dest = (char *)check_malloc(sizeof(char) * (string_len - (label_len + 3))); // chars + terminator */
      // printf("extract_attribute_value_from_string->dest length %d\n ", string_len - (label_len + 3));
      memset(dest, '\0', sizeof(char) * (string_len - (label_len + 3)));
      // printf("extract_attribute_value_from_string->starting  %d\n ", (label_len + 2));
      strncpy(dest, full_label_copy + (label_len + 2), string_len - (label_len + 4));
      // printf("extract_attribute_value_from_string->dest %s\n ", dest);
      return dest;
   }
   else
   {
      char *dest = (char *)check_malloc(sizeof(char) * (string_len - (label_len + 2))); // chars + terminator */
      // printf("extract_attribute_value_from_string->dest length %d\n ", strlen(dest));
      memset(dest, '\0', sizeof(char) * (string_len - (label_len + 2)));
      // printf("extract_attribute_value_from_string->starting  %d, arriving %d\n ", (label_len + 2),(string_len - (label_len + 3)));
      strncpy(dest, full_label_copy + (label_len + 2), string_len - (label_len + 3));
      // printf("extract_attribute_value_from_string->dest %s\n ", dest);
      return dest;
   }
}

char *extract_attribute_value_from_string_to_draw(full_name, full_label) 
char *full_name;
char *full_label;
{

   // printf("extract_attribute_value_from_string_to_draw->full_name, full_label %s %s\n ",full_name,full_label);
   char *full_label_copy = strdup(full_label);
   int full_name_len = strlen(full_name);
   // printf("extract_attribute_value_from_string_to_draw->full_name_len %d\n ",full_name_len);
   int full_label_len = strlen(full_label_copy);
   // printf("extract_attribute_value_from_string_to_draw->full_label_len %d\n ",full_label_len);

   char *dest = (char *)check_malloc(sizeof(char) * (full_label_len - (full_name_len + 3))); // chars + terminator */
   // printf("extract_attribute_value_from_string_to_draw->dest length %d\n ",(full_label_len - (full_name_len+3)));
   memset(dest, '\0', sizeof(char) * (full_label_len - (full_name_len + 3)));
   // printf("extract_attribute_value_from_string_to_draw->starting  %d\n ",(full_name_len+4));
   // printf("extract_attribute_value_from_string_to_draw->nr chars  %d\n ",full_label_len - (full_name_len+4));
   strncpy(dest, (full_label_copy + full_name_len + 4), full_label_len - (full_name_len + 4));
   // printf("extract_attribute_value_from_string_to_draw->dest %s\n ",dest);
   return dest;
}

float calculate_unnormalized_value(min,max,split_value)
float min;
float max;
float split_value;
{
   float result;

   //feature scaling was computed as: x' = (x - x_min) / (x_max - x_min)
   //thus to reconstruct the original value we apply the following equation
   //x = x' * (x_max - x_min) + x_min

   result = split_value*(max-min) + min;
   return result;

}