# A simple Makefile to build both mpihello w/o cuda and cudahello with cuda calls.
CC=mpic++
CFLAGS= -O3 -fopenmp

# These flags are necessary for Perlmutter and are defined in the cudatoolkit module.
CFLAGS += ${CRAY_CUDATOOLKIT_INCLUDE_OPT}
LINKFLAGS += ${CRAY_CUDATOOLKIT_POST_LINK_OPTS}

mpihello.ex: mpihello.cpp
	$(CC) $(CFLAGS) -o $@ mpihello.cpp $(LINKFLAGS)

cudahello.ex: cudahello.cpp
	$(CC) $(CFLAGS) -o $@ cudahello.cpp $(LINKFLAGS)

all: mpihello.ex cudahello.ex

clean:
	rm -f *.exe *.ex *.o
