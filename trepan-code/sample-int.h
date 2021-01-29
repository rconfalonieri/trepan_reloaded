#define UNINITIALIZED_KEY	1
#define SAMPLING_EPSILON	1.0e-6


typedef union
{
   struct
   {
      float *probs;
   } discrete;
   struct
   {
      float min;
      float max;
   } real;
} Posterior;


