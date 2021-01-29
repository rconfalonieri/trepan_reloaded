#include "java-interface.h"

JNIEnv* create_vm(JavaVM **jvm)
{
    JNIEnv* env;
    
    JavaVMInitArgs args;
    JavaVMOption options;
    args.version = JNI_VERSION_1_8;
    
    args.nOptions = 1;
    options.optionString = "-Djava.class.path=./libs/ontology-wrapper.jar";
    // options.optionString = "-Djava.class.path=./helloWorld.jar";
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
    
    // main_method = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "main", "([Ljava/lang/String;)V");
    // square_method = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "square", "(I)I");
    // power_method = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "power", "(II)I");
    information_content = (*env)->GetStaticMethodID(env, ontology_wrapper_class, "computeInformationContent", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    (*env)->CallStaticVoidMethod(env, ontology_wrapper_class, information_content, ontology_trepan_file, ontology_file);
    
    // printf("%d squared is %d\n", number,
    //     (*env)->CallStaticIntMethod(env, hello_world_class, square_method, number));
    
    // printf("%d raised to the %d power is %d\n", number, exponent,
    //     (*env)->CallStaticIntMethod(env, hello_world_class, power_method, number, exponent));

    // printf("ontology %s has been opened %d\n", ontologyFile, 
    //     (*env)->CallStaticIntMethod(env, hello_world_class, open_onto_method, ontologyFile));

    // (*env)->CallStaticIntMethod(env, hello_world_class, open_onto_method, ontologyFile);
}
