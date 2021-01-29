#include <stdio.h>
#include <jni.h>

JNIEnv* create_vm(JavaVM **jvm);
void invoke_class(JNIEnv* env, char* fname, char* fname2);