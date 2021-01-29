
/* Information about weights in the neural network */
typedef struct 
{
   int fromunit;
   float weight;
} WeightRec;


/* Information about units in the neural network */
typedef struct
{
   float bias;
   float netinput;
   float activation;
   int numweights;
   WeightRec *weights;
   float (*act_function)(float);
} UnitRec;


// DF >> This is intended as a temporary fix 
// to use networks with hidden layers with this version of Trepan.
// The aim here is to introduce/change the minimum amout of code,
// this network implementation is old and not well designed, 
// anyway the new C++ version will have proper bindings.
typedef struct
{
    UnitRec *units;
    int numUnits;
} LayerRec;

/* Neural network parameters */
typedef struct
{
   LayerRec *layers;
   int numLayers;
   int weights_loaded;
   int numunits;
   int numHiddenLayers;  
   int *hiddenLayerSize;    // Each entry represents the size of a hidden layer
   int numoutputs;
   int numinputs;
   int (*classification_function)();
} NetworkRec;

typedef struct
{
   int number;
   NetworkRec *nets;
   float *predictions;	/* one value per network output */
   float *coeffs;	/* one value per ensemble member */
   float total;		/* sum of coefficients */
} Ensemble;


