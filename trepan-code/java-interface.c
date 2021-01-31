#include "java-interface.h"
#include "utils-exp.h"
#include "examples-exp.h"


JNIEnv* create_vm(JavaVM **jvm)
{
    JNIEnv* env;
    
    JavaVMInitArgs args;
    JavaVMOption options;
    args.version = JNI_VERSION_10;
    
    args.nOptions = 1;
    // options.optionString = "-Djava.class.path=./libs/ontology-wrapper.jar";
    options.optionString = "-Djava.class.path=./libs/predictClass.jar";
    args.options = &options;
    args.ignoreUnrecognized = 0;
    
    int rv;
    rv = JNI_CreateJavaVM(jvm, (void**)&env, &args);
    if (rv < 0 || !env)
        printf("Unable to Launch JVM %d\n",rv);
    else
        printf("Launched JVM! :)\n");
    return env;
}

void invoke_class(JNIEnv* env, char* ontology_trepan, char* ontology_filename)
{
    jclass ontology_wrapper_class;
    jclass hello_world_class;
    jmethodID main_method;
    jmethodID square_method;
    jmethodID power_method;
    jmethodID information_content;
    jint number=20;
    jint exponent=3;
    // jstring ontology_file = (*env)->NewStringUTF(env,"libs/loan_dataset_ontology.owl");
    // jstring ontology_file = (*env)->NewStringUTF(env,"libs/heart_ontology.owl");
    jstring ontology_file = (*env)->NewStringUTF(env,ontology_filename);
    jstring ontology_trepan_file = (*env)->NewStringUTF(env,ontology_trepan);
    ontology_wrapper_class = (*env)->FindClass(env, "OntologyWrapper");
    hello_world_class = (*env)->FindClass(env, "helloWorld");
    
    // main_method = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "main", "([Ljava/lang/String;)V");
    square_method = (*env)->GetStaticMethodID(env, hello_world_class, "square", "(I)I");
    // power_method = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "power", "(II)I");
    information_content = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "computeInformationContent", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    printf("Launched JVM2! :)\n");
    
    // (*env)->CallStaticVoidMethod(env, ontology_wrapper_class, information_content, ontology_trepan_file, ontology_file);
    
    printf("%d squared is %d\n", number,
        (*env)->CallStaticIntMethod(env, hello_world_class, square_method, number));
    
    // printf("%d raised to the %d power is %d\n", number, exponent,
    //     (*env)->CallStaticIntMethod(env, hello_world_class, power_method, number, exponent));

    // printf("ontology %s has been opened %d\n", ontologyFile, 
    //     (*env)->CallStaticIntMethod(env, hello_world_class, open_onto_method, ontologyFile));

    // (*env)->CallStaticIntMethod(env, hello_world_class, open_onto_method, ontologyFile);
}

int predict_class(Example *example, AttributeInfo *attr_info)
{
    jclass predictor_class;
    jmethodID predict_method;
    // char src[] = "Look Here";
	char attributes_string[200] = "";
    char values_string[200] = "";
    char sep[] = ":";
    
    JNIEnv* env =  attr_info->env;
    Attribute *attribute;
    Value *value;

    for (int i = 0; i < attr_info->number; ++i) {
        if (i != attr_info->class_index) {
            attribute = &attr_info->attributes[i];
            value = &example->values[i];
            
            strcat(attributes_string, attribute->full_name);
            strcat(attributes_string, sep);
            switch (attribute->type) {
                case NOMINAL_ATTR:
                case BOOLEAN_ATTR:
                    printf("attribute %s value is %d\n",attribute->full_name,value->value.discrete);
                    char decimal_array[2];
                    sprintf(decimal_array, "%d", value->value.discrete);
                    strcat(values_string, decimal_array);
                    strcat(values_string, sep);
                break;

                case REAL_ATTR:
                    printf("attribute %s value is %f\n",attribute->full_name,value->value.real);
                    char float_array[32];
                    sprintf(float_array, "%f", value->value.real);
                    strcat(values_string, float_array);
                    strcat(values_string, sep);
                break;
            }
            
        }
    }
    printf("%s\n",attributes_string);
    printf("%s\n",values_string);

    jstring attributes = (*env)->NewStringUTF(env,attributes_string);
    jstring instance = (*env)->NewStringUTF(env,values_string);
    
    predictor_class = (*env)->FindClass(env, "predictClass");
    predict_method = (*env)->GetStaticMethodID(env, predictor_class, "predict", "(Ljava/lang/String;Ljava/lang/String;)I");
    // printf("%s predict class is %d\n", values_string, (*env)->CallStaticIntMethod(env, predictor_class, predict_method, attributes, instance));
    // return(1);
    return((*env)->CallStaticIntMethod(env, predictor_class, predict_method, attributes, instance));
}