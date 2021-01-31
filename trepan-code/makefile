all: run


CC =			gcc
# CFLAGS =		-g -O -Wall -I/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/include -I/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/include/darwin 
CFLAGS =		-g -O -Wall -I/Library/Java/JavaVirtualMachines/jdk-13.0.2.jdk/Contents/Home/include/ -I/Library/Java/JavaVirtualMachines/jdk-13.0.2.jdk/Contents/Home/include/darwin
# CFLAGS =		-g -O -Wall
LIBS =			-lm

SOURCES =		command.c examples.c main.c mofn.c network.c \
			sample.c stats.c tree.c utils.c java-interface.c \
			user-command.c user-examples.c
OBJECTS =		command.o examples.o main.o mofn.o network.o \
			sample.o stats.o tree.o utils.o java-interface.o \
			user-command.o user-examples.o


# SOURCES =		command.c examples.c main.c mofn.c network.c \
# 			sample.c stats.c tree.c utils.c \
# 			user-command.c user-examples.c
# OBJECTS =		command.o examples.o main.o mofn.o network.o \
# 			sample.o stats.o tree.o utils.o \
# 			user-command.o user-examples.o


# helloWorld.class: helloWorld.java
# 	/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/bin/javac helloWorld.java
# 	/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/bin/jar cf helloWorld.jar helloWorld.class
# 	rm helloWorld.class

# trepan: $(OBJECTS)
# 	$(CC) -o trepan $(CFLAGS) $(OBJECTS) \
# 	-L/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/jre/lib/server/ \
# 	-ljvm \
# 	-rpath /Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/jre/lib/server/

trepan: $(OBJECTS)
	$(CC) -o trepan_reloaded $(CFLAGS) $(OBJECTS) \
	-L/Library/Java/JavaVirtualMachines/jdk-13.0.2.jdk/Contents/Home/lib/server/ \
	-ljvm \
	-rpath /Library/Java/JavaVirtualMachines/jdk-13.0.2.jdk/Contents/Home/lib/server/

# trepan: $(OBJECTS)
# 	$(CC) -o trepan $(CFLAGS) $(OBJECTS) 	 

# run: trepan
# 	export LD_LIBRARY_PATH="/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home/jre/lib/server/"
# 	# ./trepan loan.cmd

clean: 
	rm -rf *.o trepan_reloaded 
