# Makefile for vaccel python helper lib
#
CC=gcc
LD=g++ 
NVCC=nvcc
CFLAGS=-Wall
LDFLAGS=
LDFLAGS_PROM=-lprometheus-cpp-pull  -lprometheus-cpp-core -lcurl -lz -shared
LDFLAGS_WRAPPER=-lsavgol_cuda_prometheus -L.
CFLAGS_VACCEL=-I/opt/vaccel-v0.4.0/include
LDFLAGS_VACCEL=-lvaccel -L/opt/vaccel-v0.4.0/lib -ldl

all: libsavgol_cuda.so libsavgol_cuda_prometheus.so wrapper_host libsavgol_vaccel.so wrapper_vaccel

libsavgol_cuda.so: savgol_cuda.cu
	#$(CC) $< -o $@ ${CFLAGS} -fPIC -shared ${LDFLAGS}
	$(NVCC) --compiler-options '-fPIC' $< -o $@ ${LDFLAGS}

libsavgol_cuda_prometheus.so: savgol_cuda_prometheus.cu
	$(NVCC) --compiler-options '-fPIC' $< -o $@ ${LDFLAGS_PROM}

wrapper_host.o: wrapper_host.c
	$(CC) -c $< -o $@ ${CFLAGS} ${LDFLAGS_WRAPPER}

wrapper_host: wrapper_host.o
	$(LD) $< -o $@ ${LDFLAGS_WRAPPER}

wrapper_vaccel.o: wrapper_vaccel.c
	$(CC) -c -fPIC $< -o $@ ${CFLAGS_VACCEL} ${LDFLAGS_VACCEL}

libsavgol_vaccel.so: wrapper_vaccel.o
	gcc $< -o $@ ${LDFLAGS_VACCEL} -shared

wrapper_vaccel: wrapper_host.o
	$(LD) $< -o $@  -lsavgol_vaccel -L. ${LDFLAGS_VACCEL}



clean:
	-rm -f  wrapper_host wrapper_vaccel *.so *.o
