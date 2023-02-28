# Makefile for vaccel python helper lib
#
CC=gcc
LD=g++ 
NVCC=nvcc
CFLAGS=-Wall
LDFLAGS=-shared
LDFLAGS_PROM=-lprometheus-cpp-pull  -lprometheus-cpp-core -lcurl -lz -shared
LDFLAGS_WRAPPER=-lsavgol_cuda -L.
CFLAGS_VACCEL=-I/opt/vaccel/include
LDFLAGS_VACCEL=-lvaccel -L/opt/vaccel/lib -ldl

#all: libsavgol_cuda.so libsavgol_cuda_prometheus.so wrapper_host libsavgol_vaccel.so wrapper_vaccel
all: libsavgol_cuda.so libsavgol_vaccel.so wrapper_vaccel

libsavgol_cuda.so: savgol_cuda.cu
	#$(CC) $< -o $@ ${CFLAGS} -fPIC -shared ${LDFLAGS}
	$(NVCC) -g --compiler-options '-fPIC' $< -o $@ ${LDFLAGS}

libsavgol_cuda_prometheus.so: savgol_cuda_prometheus.cu
	$(NVCC) --compiler-options '-fPIC' $< -o $@ ${LDFLAGS_PROM}

wrapper_host.o: wrapper_host.c
	$(CC) -g -c $< -o $@ ${CFLAGS} ${LDFLAGS_WRAPPER}

wrapper_host: wrapper_host.o
	$(LD) -g $< -o $@ ${LDFLAGS_WRAPPER}

wrapper_vaccel.o: wrapper_vaccel.c
	$(CC) -g -c -fPIC $< -o $@ ${CFLAGS_VACCEL} ${LDFLAGS_VACCEL}

libsavgol_vaccel.so: wrapper_vaccel.o
	gcc $< -g -o $@ ${LDFLAGS_VACCEL} -shared

wrapper_host_vaccel.o: wrapper_host_vaccel.c
	$(CC) -c-g  $< -o $@ ${CFLAGS} ${LDFLAGS_WRAPPER} ${LDFLAGS_VACCEL}

wrapper_vaccel: wrapper_host_vaccel.o
	$(LD) $< -g -o $@  -lsavgol_vaccel -L. ${LDFLAGS_VACCEL}



clean:
	-rm -f  wrapper_host wrapper_vaccel *.so *.o 
