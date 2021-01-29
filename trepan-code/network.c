#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils-exp.h"
#include "examples-exp.h"
#include "tree.h"
#include "network-int.h"


static NetworkRec active_net = { NULL, FALSE, 0, 0, 0, NULL };

static Ensemble active_ensemble = { 0, NULL, NULL, NULL, 0.0 };


/*
   The logistic activation function.
*/
static float logistic_act(float netinput)
{
    if (netinput > 16.0)
        return (0.99999989f); // Added f [Tina Eliassi-Rad 7/15/2000]
    if (netinput < -16.0)
        return (0.00000011f); // Added f [Tina Eliassi-Rad 7/15/2000]
    float ret = 1.0f / (1.0f + exp(-netinput)); // Added (float) [Tina Eliassi-Rad 7/15/2000]
    return ret;
}


static float linear_act(float netinput)
{
    return((float)netinput); // Added (float) [Tina Eliassi-Rad 7/15/2000]
}


static float tanh_act(float netinput)
{
    double e_x, e_minus_x;
    float act;

    e_x = exp((double)netinput);
    e_minus_x = exp((double)netinput * -1.0);

    act = (float)((e_x - e_minus_x) / (e_x + e_minus_x)); // Added (float) [Tina Eliassi-Rad 7/15/2000]

    return(act);
}

static int oracle_is_network()
{
    if (active_net.numunits)
        return(TRUE);
    else
        return(FALSE);
}

static int oracle_is_ensemble()
{
    if (active_ensemble.number)
        return(TRUE);
    else
        return(FALSE);
}

void set_hidden_layers_activation(float(*act_function)(float))
{
    for (int i = 1; i < active_net.numLayers - 1; i++)
    {
        for (int j = 0; j < active_net.layers[i].numUnits; j++)
        {
            active_net.layers[i].units[j].act_function = act_function;
        }
    }
}

void set_output_layer_activation(float(*act_function)(float))
{
    int outputLayer = active_net.numLayers - 1;
    for (int i = 0; i < active_net.layers[outputLayer].numUnits; i++)
    {
        active_net.layers[outputLayer].units[i].act_function = act_function;
    }
}

void set_activation_function(char *name, char *range)
{
    float(*act_function)(float);

    if (!oracle_is_network())
    {
        error(prog_name,
            "activation functions can be set only when oracle is a network",
            TRUE);
    }

    if (Startsame(name, "logistic"))
        act_function = logistic_act;
    else if (Startsame(name, "tanh"))
        act_function = tanh_act;
    else if (Startsame(name, "linear"))
        act_function = linear_act;
    else
    {
        sprintf(err_buffer, "%s is not a valid activation function", name);
        error(prog_name, err_buffer, TRUE);
    }

    if (range == NULL || Startsame(range, "all"))
    {
        set_hidden_layers_activation(act_function);
        set_output_layer_activation(act_function);
    }
    else if (Startsame(range, "hidden"))
    {
        set_hidden_layers_activation(act_function);
    }
    else if (Startsame(range, "output"))
    {
        set_output_layer_activation(act_function);
    }
    else
    {
        sprintf(err_buffer, "%s is not a valid range for activation_function",
            range);
        error(prog_name, err_buffer, TRUE);
    }
}

// gets the output neuron with highest activation
static int one_of_N(NetworkRec *network)
{
    int outputLayer = network->numLayers - 1;
    // max over the output neurons activations
    int highest = 0;
    for (int i = 1; i < network->numoutputs; i++)
    {
        if (network->layers[outputLayer].units[i].activation > network->layers[outputLayer].units[highest].activation)
        {
            highest = i;
        }
    }

    return highest;
}

static int threshold_half(NetworkRec *network)
{
    int outputLayer = network->numLayers - 1;
    if (network->layers[outputLayer].units[0].activation >= 0.5f)
        return 1;
    
    return 0;
}

static int threshold_zero(NetworkRec *network)
{
    int outputLayer = network->numLayers - 1;
    if (network->layers[outputLayer].units[0].activation >= 0.0f)
        return 1;

    return(0);
}

void set_classification_function(char *name)
{
    if (Startsame(name, "threshold_half"))
        active_net.classification_function = threshold_half;
    else if (Startsame(name, "threshold_zero"))
        active_net.classification_function = threshold_zero;
    else if (Startsame(name, "one_of_N"))
        active_net.classification_function = one_of_N;
    else
    {
        sprintf(err_buffer, "%s is not a valid classification function", name);
        error(prog_name, err_buffer, TRUE);
    }
}

static int determine_ensemble_class(Ensemble *ensemble)
{
    int i;
    int num_outputs = ensemble->nets[0].numoutputs;
    int highest;

    if (num_outputs == 1)
    {
        if (ensemble->predictions[0] >= 0.5f)
            return 1;
        else
            return 0;
    }
    else
    {
        highest = 0;
        for (i = 1; i < num_outputs; ++i)
        {
            if (ensemble->predictions[i] > ensemble->predictions[highest])
                highest = i;
        }

        return highest;
    }
}

static void free_network(NetworkRec *network)
{
    if (!network)
        return;

    // free up the output layer
    int outputLayer = network->numLayers - 1;
    for (int i = 0; i < network->layers[outputLayer].numUnits; i++)
    {
        check_free((void *)network->layers[outputLayer].units[i].weights);
    }
    check_free((void *)network->layers[outputLayer].units);

    // free up hidden layers
    for (int i = 1; i < network->numLayers - 1; i++)
    {
        for (int j = 0; j < network->layers[i].numUnits; j++)
        {
            check_free((void *)network->layers[i].units[j].weights);
        }
    }
    for (int i = 1; i < network->numLayers - 1; i++)
    {
        check_free((void *)network->layers[i].units);
    }

    // free up the input layer
    check_free((void *)network->layers[0].units);

    // free up the layers array
    check_free((void *)network->layers);

    // reset the network structure
    bzero((char *)network, (int) sizeof(NetworkRec));
}

static void free_ensemble(Ensemble *ensemble)
{
    int i;

    if (!ensemble)
        return;

    for (i = 0; i < ensemble->number; ++i)
        free_network(&ensemble->nets[i]);

    check_free((void *)ensemble->nets);
    check_free((void *)ensemble->coeffs);
    check_free((void *)ensemble->predictions);
    ensemble->number = 0;

    bzero((char *)ensemble, (int) sizeof(Ensemble));
}

static void free_oracle()
{
    if (oracle_is_network())
        free_network(&active_net);
    else if (oracle_is_ensemble())
        free_ensemble(&active_ensemble);
}

/*  Read an integer value from the network file.
*/
static void read_def(FILE *stream, int *definition)
{
    char string[BUFSIZ];

    if (fscanf(stream, "%s", string) != EOF)
    {
        if (!sscanf(string, "%d", definition))
            error(prog_name, "definition in network file is not an integer", TRUE);
    }
    else
        error(prog_name, "unexpected end of network file encountered", TRUE);
}


/*  Read the definitions part of a network file.
*/
static void read_definitions(FILE *stream, NetworkRec *network)
{
    char string[BUFSIZ];
    int dummy;
    int hiddenUnits = 0;

    while (fscanf(stream, "%s", string) != EOF)
    {
        if (!strcmp(string, "end"))
            return;

        if (!strcmp(string, "ninputs"))
            read_def(stream, &(network->numinputs));
        else if (!strcmp(string, "nhiddenlayers"))
        {
            // read the number of hidden layers
            read_def(stream, &network->numHiddenLayers);
            // if any, read the number of units for each of them
            if (network->numHiddenLayers > 0)
            {
                network->hiddenLayerSize = (int *)check_malloc(sizeof(int) * network->numHiddenLayers);
                for (int i = 0; i < network->numHiddenLayers; i++)
                {
                    char buf[BUFSIZ];
                    if (fscanf(stream, "%s", buf) != EOF)
                    {
                        if (!sscanf(buf, "%d", &network->hiddenLayerSize[i]))
                        {
                            error(prog_name, "definition for layer size in network file is not an integer or is missing", TRUE);
                        }
                        hiddenUnits += network->hiddenLayerSize[i];
                    }
                    else
                    {
                        error(prog_name, "unexpected end of network file encountered", TRUE);
                    }
                }
            }
        }
        else if (!strcmp(string, "noutputs"))
        {
            read_def(stream, &(network->numoutputs));
            network->numunits = network->numinputs + hiddenUnits + network->numoutputs;
        }
        else if (!strcmp(string, "ncopyunits"))
            read_def(stream, &dummy);
        else if (!strcmp(string, "noutputstates"))
            read_def(stream, &dummy);
        else
        {
            sprintf(err_buffer,
                "unknown definition - %s - in network file", string);
            error(prog_name, err_buffer, TRUE);
        }
    }
}

/*  Allocate and initialize data structures for network weights.
*/
static void make_weights(NetworkRec *network)
{
    UnitRec *unit;
    int numUnitsInLayer, numUnitsInPrevLayer;
    for (int i = 1; i < network->numLayers; i++)
    {
        numUnitsInLayer = network->layers[i].numUnits;
        numUnitsInPrevLayer = network->layers[i - 1].numUnits;
        for (int j = 0; j < numUnitsInLayer; j++)
        {
            unit = &network->layers[i].units[j];
           
            unit->weights = (WeightRec *)check_malloc(sizeof(WeightRec) * numUnitsInPrevLayer);
            unit->numweights = numUnitsInPrevLayer;

            for (int k = 0; k < unit->numweights; k++)
                unit->weights[k].fromunit = k;
        }
    }
}

/*  Allocate data structures for a network.
*/
static void make_network(NetworkRec *network)
{
    if (network->numinputs <= 0)
        error(prog_name, "Number of input units must be positive integer", TRUE);

    if (network->numHiddenLayers < 0)
        error(prog_name, "Number of hidden layers  must be >= 0", TRUE);
    
    if (network->numoutputs <= 0)
        error(prog_name, "Number of output units must be positive integer", TRUE);

    // allocate an array of layers
    network->numLayers = network->numHiddenLayers + 2;
    network->layers = (LayerRec*)check_malloc(sizeof(LayerRec) * network->numLayers);

    // allocate the input layer neurons
    network->layers[0].numUnits = network->numinputs;
    network->layers[0].units = (UnitRec *)check_malloc(sizeof(UnitRec) * network->numinputs);
    // set linear activation function 
    for (int i = 0; i < network->numinputs; i++)
        network->layers[0].units[i].act_function = linear_act;

    if (network->numHiddenLayers > 0)
    {
        // allocate the hidden layers neurons
        for (int i = 1, j = 0; i < network->numLayers - 1; i++, j++)
        {
            network->layers[i].numUnits = network->hiddenLayerSize[j];
            network->layers[i].units = (UnitRec *)check_malloc(sizeof(UnitRec) * network->hiddenLayerSize[j]);
            // set logistic activation function 
            for (int k = 0; k < network->layers[i].numUnits; k++)
                network->layers[i].units[k].act_function = logistic_act;
        }
    }

    // allocate the output layer neurons
    int outputLayer = network->numLayers - 1;
    network->layers[outputLayer].numUnits = network->numoutputs;
    network->layers[outputLayer].units = (UnitRec *)check_malloc(sizeof(UnitRec) * network->numoutputs);
    // set logistic activation function 
    for (int i = 0; i < network->numoutputs; i++)
        network->layers[outputLayer].units[i].act_function = linear_act;

    make_weights(network);
}

/*
   Read a PDP-format network file.
*/
static void read_network(char *fname, NetworkRec *network)
{
    FILE *stream;
    char string[BUFSIZ];

    stream = check_fopen(fname, "r");
    while (fscanf(stream, "%s", string) != EOF)
    {
        if (!strcmp(string, "definitions:"))
        {
            read_definitions(stream, network);
            make_network(network);
        }
        else
        {
            sprintf(err_buffer, "unknown network option %s", string);
            error(prog_name, err_buffer, TRUE);
        }
    }

    fclose(stream);
}

/*
   Read the network weights from a file.
*/
static void read_weights(FILE *stream, NetworkRec *network)
{
    if (network != NULL)
    {
        for (int i = 1; i < network->numLayers; i++)
        {
            for (int j = 0; j < network->layers[i].numUnits; j++)
            {
                for (int k = 0; k < network->layers[i].units[j].numweights; k++)
                {
                    if (fscanf(stream, "%f", &network->layers[i].units[j].weights[k].weight) != 1)
                        error(prog_name, "too few weights in weights file", TRUE);
                }
            }
        }

        // DF >> if there are no hidden layers, 
        // consider weights from input to output layer directly,
        // for retro-compatibility with the original implementation.
        int i = network->numHiddenLayers > 0 ? 1 : 0;
        for (; i < network->numLayers; i++)
        {
            for (int j = 0; j < network->layers[i].numUnits; j++)
            {
                if (fscanf(stream, "%f", &network->layers[i].units[j].bias) != 1)
                    error(prog_name, "too few biases in weights file", TRUE);
            }
        }

        if (fscanf(stream, "%*f") != EOF)
            error(prog_name, "too many weights or biases in weights file", TRUE);
    }

    network->weights_loaded = TRUE;
}

/*
   Propagate activations through network.
*/
static void compute_output(NetworkRec *network)
{
    UnitRec *unit;
    WeightRec *weight;
    for (int i = 1; i < network->numLayers; i++)
    {
        for (int j = 0; j < network->layers[i].numUnits; j++)
        {
            unit = &network->layers[i].units[j];
            unit->netinput = unit->bias;

            for (int k = 0; k < unit->numweights; k++)
            {
                weight = &unit->weights[k];
                unit->netinput += network->layers[i - 1].units[weight->fromunit].activation * weight->weight;
            }
            unit->activation = (*unit->act_function)(unit->netinput);
        }
    }
}

/*
   Set the activations of the input units of the network.
*/
static void set_input(NetworkRec *network, Example *example, AttributeInfo *attr_info)
{
    Attribute *attribute;
    Value *value;

    int start = 0;
    for (int i = 0; i < attr_info->number; ++i)
        if (i != attr_info->class_index)
        {
            attribute = &attr_info->attributes[i];
            value = &example->values[i];

            if (start >= network->numinputs)
                error(prog_name, "network has too few inputs", TRUE);

            switch (attribute->type)
            {
            case NOMINAL_ATTR:
                if (attribute->map)
                {
                    if (value->missing)
                    {
                        for (int j = 0, k = start; j < attribute->map->size; ++j, ++k)
                            network->layers[0].units[k].activation = (float)(1.0 / attribute->map->size); // Added (float) [Tina Eliassi-Rad 7/15/2000]
                    }
                    else
                    {
                        for (int j = 0, k = start; j < attribute->map->size; ++j, ++k)
                            network->layers[0].units[k].activation =
                            attribute->map->vectors[value->value.discrete][j];
                    }
                    start += attribute->map->size;
                }
                else
                {
                    if (value->missing)
                    {
                        for (int j = 0, k = start; j < attribute->num_values; ++j, ++k)
                            network->layers[0].units[k].activation = (float)(1.0 / attribute->num_values); // Added (float) [Tina Eliassi-Rad 7/15/2000]
                    }
                    else
                    {
                        for (int j = 0, k = start; j < attribute->num_values; ++j, ++k)
                            if (j == value->value.discrete)
                                network->layers[0].units[k].activation = 1.0;
                            else
                                network->layers[0].units[k].activation = 0.0;
                    }
                    start += attribute->num_values;
                }
                break;
            case REAL_ATTR:
                if (attribute->map)
                {
                    if (value->missing)
                        error(prog_name, "missing value for real attribute", TRUE);

                    /* COMPLETE HACK FOR THE ELEVATOR TASK */
                    if (value->value.real == 0.0)
                    {
                        network->layers[0].units[start].activation = 1.0;
                        network->layers[0].units[start + 1].activation = 0.0;
                    }
                    else
                    {
                        network->layers[0].units[start].activation = 0.0;
                        network->layers[0].units[start + 1].activation = value->value.real;
                    }
                    start += 2;
                }
                else
                {
                    if (value->missing)
                        error(prog_name, "missing value for real attribute", TRUE);

                    network->layers[0].units[start].activation = value->value.real;
                    ++start;
                }
                break;
            case BOOLEAN_ATTR:
                if (value->missing)
                    network->layers[0].units[start].activation = 0.5;
                else
                    network->layers[0].units[start].activation = (float)value->value.discrete; // Added (float) [Tina Eliassi-Rad 7/15/2000]
                
                ++start;
                break;
            }
        }

    if (start != network->numinputs)
    {
        error("system error", "failed to correctly set input vector", TRUE);
    }
}

static void read_coefficients(char *fname, Ensemble *ensemble)
{
    FILE *stream;
    stream = check_fopen(fname, "r");

    ensemble->total = 0.0;
    for (int i = 0; i < ensemble->number; ++i)
    {
        if (fscanf(stream, "%f", &ensemble->coeffs[i]) != 1)
            error(prog_name,
                "coefficients file for ensemble is not in correct format", TRUE);
        ensemble->total += ensemble->coeffs[i];
    }

    fclose(stream);
}

static void check_ensemble_networks(Ensemble *ensemble)
{
    for (int i = 1; i < ensemble->number; ++i)
    {
        if (ensemble->nets[i].numoutputs != ensemble->nets[0].numoutputs)
            error(prog_name, "all ensemble nets must have same number of outputs",
                TRUE);

        if (ensemble->nets[i].numinputs != ensemble->nets[0].numinputs)
            error(prog_name, "all ensemble nets must have same number of inputs",
                TRUE);
    }
}

static FILE *open_weight_file(char *stem)
{
    char fname[BUFSIZ];
    FILE *stream;

    sprintf(fname, "%s.wgt", stem);
    if ((stream = fopen(fname, "r")) != NULL)
        return(stream);

    sprintf(fname, "%s.wts", stem);
    if ((stream = fopen(fname, "r")) != NULL)
        return(stream);

    sprintf(err_buffer, "unable to open either %s.wgt or %s.wts", stem, stem);
    error(prog_name, err_buffer, TRUE);
    return NULL; // Added return statement. [Tina Eliassi-Rad 7/15/2000]
}

void get_ensemble(char *stem, int number)
{
    char fname[BUFSIZ];
    FILE *stream;

    free_oracle();

    active_ensemble.number = number;

    active_ensemble.nets = (NetworkRec *) check_malloc(sizeof(NetworkRec) * number);
    for (int i = 0; i < number; ++i)
    {
        sprintf(fname, "%s.%d.net", stem, i);
        read_network(fname, &active_ensemble.nets[i]);

        sprintf(fname, "%s.%d", stem, i);
        stream = open_weight_file(fname);
        read_weights(stream, &active_ensemble.nets[i]);
    }
    check_ensemble_networks(&active_ensemble);

    active_ensemble.coeffs = (float *)check_malloc(sizeof(float) * number);
    sprintf(fname, "%s.coeffs", stem);
    read_coefficients(fname, &active_ensemble);

    active_ensemble.predictions = (float *)check_malloc(sizeof(float) * active_ensemble.nets[0].numoutputs);
}

void get_network(char *stem)
{
    char fname[BUFSIZ];
    FILE *stream;

    free_oracle();

    sprintf(fname, "%s.net", stem);
    read_network(fname, &active_net);

    stream = open_weight_file(stem);
    read_weights(stream, &active_net);

    if (active_net.numoutputs == 1)
        set_classification_function("threshold_half");
    else
        set_classification_function("one_of_N");
}

static int query_network(Example *example, AttributeInfo *attr_info)
{
    int predicted;

    set_input(&active_net, example, attr_info);
    compute_output(&active_net);
    predicted = (*active_net.classification_function)(&active_net);

    return(predicted);
}

static int query_ensemble(Example *example, AttributeInfo *attr_info)
{
    //int i, j;
    //int predicted;
    //int num_outputs = active_ensemble.nets[0].numoutputs;
    //int first_output;

    //for (j = 0; j < num_outputs; ++j)
    //    active_ensemble.predictions[j] = 0.0;

    //for (i = 0; i < active_ensemble.number; ++i)
    //{
    //    set_input(&active_ensemble.nets[i], example, attr_info);
    //    compute_output(&active_ensemble.nets[i]);
    //    first_output = active_ensemble.nets[i].numunits - num_outputs;
    //    for (j = 0; j < num_outputs; ++j)
    //        active_ensemble.predictions[j] += active_ensemble.coeffs[i] *
    //        active_ensemble.nets[i].units[j + first_output].activation;
    //}

    //for (j = 0; j < num_outputs; ++j)
    //    active_ensemble.predictions[j] /= active_ensemble.total;

    //predicted = determine_ensemble_class(&active_ensemble);
    //return(predicted);
    return -1;
}

void register_network_oracle(int(**oracle)())
{
    if (oracle_is_network())
        *oracle = query_network;
    else if (oracle_is_ensemble())
        *oracle = query_ensemble;
    else
        error(prog_name, "tried to use an oracle when no network loaded", TRUE);
}

void classify_using_network(Options *options, ExampleInfo *ex_info, AttributeInfo *attr_info, int **matrix)
{
    int i;
    int predicted;
    int actual;
    Example *example;

    if (ClassIsVector(attr_info))
    {
        error("system error",
            "tried to use classify_using_network for class vectors", TRUE);
    }

    for (i = 0; i < ex_info->number; ++i)
    {
        example = &ex_info->examples[i];
        predicted = options->oracle(example, attr_info);
        actual = Get_Class(&ex_info->examples[i], attr_info);
        ++matrix[predicted][actual];
    }
}

void predict_using_network(ExampleInfo *ex_info, AttributeInfo *attr_info)
{
    int i, j;
    Example *example;

    if (!oracle_is_network())
        error(prog_name, "predict_using_network called when no network loaded",
            TRUE);

    int outputLayer = active_net.numLayers - 1;
    for (i = 0; i < ex_info->number; ++i)
    {
        example = &ex_info->examples[i];
        set_input(&active_net, example, attr_info);
        compute_output(&active_net);
 
        for (int j = 0; j < active_net.layers[outputLayer].numUnits; j++)
        {
            printf("%f ", active_net.layers[outputLayer].units[j].activation);
        }
        printf("\n");
    }
}

void vector_query_network(Example *example, AttributeInfo *attr_info, float *values)
{
    set_input(&active_net, example, attr_info);
    compute_output(&active_net);

    int outputLayer = active_net.numLayers - 1;
    for (int i = 0; i < active_net.layers[outputLayer].numUnits; i++)
    {
        values[i] = active_net.layers[outputLayer].units[i].activation;
    }
}


