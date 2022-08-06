#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
#include <unistd.h>

#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#include "prometheus/client_metric.h"
#include "prometheus/counter.h"
#include "prometheus/exposer.h"
#include "prometheus/family.h"
#include "prometheus/info.h"
#include "prometheus/registry.h"

#include "prometheus/gauge.h"

#include <cstdio>
#include <cstring>
#include <algorithm>
#include <random>
#include <cstring>
#include <cmath>
#include <chrono>
#include <ctime>

using namespace std;

#define DATA_SIZE 200000
#define window 11
#define polyorder 3
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>
#define BLOCKSIZE 32

struct timeval t0, t1, t2, t3;
#define DEFAULT_NL (15) // half window
#define DEFAULT_NR (15) // half window
#define DEFAULT_M (4)   // polynomial order
#define DEFAULT_LD (0)  // derivative order
#define EPSILON ((double)(1.0e-20))

__global__ void warming_kernel()
{
    int i = 7;
}

__global__ void savgol_kernel(double *indata, double *c, double *outdata, int mm, int nl, int nr)
{
    unsigned int index = threadIdx.x + blockIdx.x * blockDim.x;
    int j;
    if ((index >= 1) && (index <= nl))
    {

        for (outdata[index - 1] = 0.0, j = -nl; j <= nr; j++)
        {
            if (index + j >= 1)
            {

                int dd = index + j - 1;
                outdata[index - 1] += c[(j >= 0 ? j + 1 : nr + nl + 2 + j)] * indata[dd];
            }
        }
    }

    if ((index >= nl + 1) && (index <= mm - nr))
    {
        for (outdata[index - 1] = 0.0, j = -nl; j <= nr; j++)
        {
            outdata[index - 1] += c[(j >= 0 ? j + 1 : nr + nl + 2 + j)] * indata[index + j - 1];
        }
    }

    if ((index >= mm - nr + 1) && (index <= mm))
    {
        for (outdata[index - 1] = 0.0, j = -nl; j <= nr; j++)
        {
            if (index + j <= mm)
            {
                outdata[index - 1] += c[(j >= 0 ? j + 1 : nr + nl + 2 + j)] * indata[index + j - 1];
            }
        }
    }
}

//////////////////////

///////////////////////////////////////////////////////////////////////////

void free_dmatrix(double **m, long nrl, long nrh, long ncl, long nch)
{
    free((char *)(m[nrl] + ncl - 1));
    free((char *)(m + nrl - 1));
}

int *ivector(long nl, long nh)
{
    int *v;
    v = (int *)malloc((size_t)((nh - nl + 2) * sizeof(int)));
    if (!v)
    {
        // log("Error: Allocation failure.");
        exit(1);
    }
    return v - nl + 1;
}

void free_ivector(int *v, long nl, long nh)
{
    free((char *)(v + nl - 1));
}
void free_dvector(double *v, long nl, long nh)
{
    free((char *)(v + nl - 1));
}

double *dvector(long nl, long nh)
{
    double *v;
    long k;
    v = (double *)malloc((size_t)((nh - nl + 2) * sizeof(double)));
    if (!v)
    {
        // log("Error: Allocation failure.");
        exit(1);
    }
    for (k = nl; k <= nh; k++)
        v[k] = 0.0;
    return v - nl + 1;
}

void lubksb(double **a, int n, int *indx, double b[])
{
    int i, ii = 0, ip, j;
    double sum;

    for (i = 1; i <= n; i++)
    {
        ip = indx[i];
        sum = b[ip];
        b[ip] = b[i];
        if (ii)
            for (j = ii; j <= i - 1; j++)
                sum -= a[i][j] * b[j];
        else if (sum)
            ii = i;
        b[i] = sum;
    }
    for (i = n; i >= 1; i--)
    {
        sum = b[i];
        for (j = i + 1; j <= n; j++)
            sum -= a[i][j] * b[j];
        b[i] = sum / a[i][i];
    }
}

double **dmatrix(long nrl, long nrh, long ncl, long nch)
{
    long i, nrow = nrh - nrl + 1, ncol = nch - ncl + 1;
    double **m;
    m = (double **)malloc((size_t)((nrow + 1) * sizeof(double *)));
    if (!m)
    {
        // log("Allocation failure 1 occurred.");
        exit(1);
    }
    m += 1;
    m -= nrl;
    m[nrl] = (double *)malloc((size_t)((nrow * ncol + 1) * sizeof(double)));
    if (!m[nrl])
    {
        // log("Allocation failure 2 occurred.");
        exit(1);
    }
    m[nrl] += 1;
    m[nrl] -= ncl;
    for (i = nrl + 1; i <= nrh; i++)
        m[i] = m[i - 1] + ncol;
    return m;
}

void ludcmp(double **a, int n, int *indx, double *d)
{
    int i, imax = 0, j, k;
    double big, dum, sum, temp;
    double *vv;

    vv = dvector(1, n);
    *d = 1.0;
    for (i = 1; i <= n; i++)
    {
        big = 0.0;
        for (j = 1; j <= n; j++)
            if ((temp = fabs(a[i][j])) > big)
                big = temp;
        if (big == 0.0)
        {
            // log("Error: Singular matrix found in routine ludcmp()");
            exit(1);
        }
        vv[i] = 1.0 / big;
    }
    for (j = 1; j <= n; j++)
    {
        for (i = 1; i < j; i++)
        {
            sum = a[i][j];
            for (k = 1; k < i; k++)
                sum -= a[i][k] * a[k][j];
            a[i][j] = sum;
        }
        big = 0.0;
        for (i = j; i <= n; i++)
        {
            sum = a[i][j];
            for (k = 1; k < j; k++)
                sum -= a[i][k] * a[k][j];
            a[i][j] = sum;
            if ((dum = vv[i] * fabs(sum)) >= big)
            {
                big = dum;
                imax = i;
            }
        }
        if (j != imax)
        {
            for (k = 1; k <= n; k++)
            {
                dum = a[imax][k];
                a[imax][k] = a[j][k];
                a[j][k] = dum;
            }
            *d = -(*d);
            vv[imax] = vv[j];
        }
        indx[j] = imax;
        if (a[j][j] == 0.0)
            a[j][j] = EPSILON;
        if (j != n)
        {
            dum = 1.0 / (a[j][j]);
            for (i = j + 1; i <= n; i++)
                a[i][j] *= dum;
        }
    }
    free_dvector(vv, 1, n);
}

char sgcoeff(double c[], int np, int nl, int nr, int ld, int m)
{
    void lubksb(double **a, int n, int *indx, double b[]);
    void ludcmp(double **a, int n, int *indx, double *d);
    int imj, ipj, j, k, kk, mm, *indx;
    double d, fac, sum, **a, *b;

    if (np < nl + nr + 1 || nl < 0 || nr < 0 || ld > m || nl + nr < m)
    {
        // log("Inconsistent arguments detected in routine sgcoeff.");
        return (1);
    }
    indx = ivector(1, m + 1);
    a = dmatrix(1, m + 1, 1, m + 1);
    b = dvector(1, m + 1);
    for (ipj = 0; ipj <= (m << 1); ipj++)
    {
        sum = (ipj ? 0.0 : 1.0);
        for (k = 1; k <= nr; k++)
            sum += pow((double)k, (double)ipj);
        for (k = 1; k <= nl; k++)
            sum += pow((double)-k, (double)ipj);
        mm = (ipj < 2 * m - ipj ? ipj : 2 * m - ipj);
        for (imj = -mm; imj <= mm; imj += 2)
            a[1 + (ipj + imj) / 2][1 + (ipj - imj) / 2] = sum;
    }
    ludcmp(a, m + 1, indx, &d);
    for (j = 1; j <= m + 1; j++)
        b[j] = 0.0;
    b[ld + 1] = 1.0;
    lubksb(a, m + 1, indx, b);
    for (kk = 1; kk <= np; kk++)
        c[kk] = 0.0;
    for (k = -nl; k <= nr; k++)
    {
        sum = b[1];
        fac = 1.0;
        for (mm = 1; mm <= m; mm++)
            sum += b[mm + 1] * (fac *= k);
        kk = ((np - k) % np) + 1;
        c[kk] = sum;
    }
    free_dvector(b, 1, m + 1);
    free_dmatrix(a, 1, m + 1, 1, m + 1);
    free_ivector(indx, 1, m + 1);
    return (0);
}
/////////////////////////


struct vaccel_arg {
        uint32_t len;
        uint8_t *buf;
};
extern "C" 

int savgol_GPU(int argc, char **argv, double *time1, double *time2)
{

    //---- prometheus stuff ----
    using namespace prometheus;
    // create a http server running on port 8080
    Exposer exposer{"127.0.0.1:8082"};
    // create a metrics registry
    // @note it's the users responsibility to keep the object alive
    auto registry = std::make_shared<Registry>();

    auto &latencys_gauge = BuildGauge()
                               .Name("latencys_gauge")
                               .Help("latency in sec")
                               .Register(*registry);

    auto &latencyms_gauge = BuildGauge()
                                .Name("latencyms_gauge")
                                .Help("latency in ms")
                                .Register(*registry);

    auto &result_gauge = BuildGauge()
                             .Name("result_gauge")
                             .Help("result")
                             .Register(*registry);

    auto &Throughput_gauge = BuildGauge()
                                 .Name("Throughput_gauge")
                                 .Help("Throughput")
                                 .Register(*registry);

    auto &version_info = BuildInfo()
                             .Name("versions")
                             .Help("Static info about the library")
                             .Register(*registry);

    version_info.Add({{"prometheus", "1.0"}});

    std::string FILE_PATH = argv[1];
    string data_file_path = FILE_PATH;
    // string golden_file_path = "dataset.txt";
    string line;

    cout << "* Savgol Filter *" << endl;
    //cout << " # input file:               " << data_file_path << endl;
    // cout << " # golden file:                " << golden_file_path << endl;

    double *indata, *outdata;
    indata = (double *)malloc(DATA_SIZE * sizeof(double));
    outdata = (double *)malloc(DATA_SIZE * sizeof(double));
    int rowcount = DATA_SIZE;

    if (strcmp(argv[0],"vaccel") == 0 ) {
          std::istringstream file(FILE_PATH);
    int index = 0;
    while (getline(file, line)) {
        indata[index] = (float)atof(line.c_str());
        index++;
        //  cout << to_string(data[index-1]) << endl;
    }


    } else {
    cout << " # input file:               " << data_file_path << endl;
    // read input data
    ifstream data_file;
    data_file.open(FILE_PATH);
    int index = 0;
    while (getline(data_file, line))
    {
        indata[index] = (float)atof(line.c_str());
        index++;
        //  cout << to_string(data[index-1]) << endl;
    }
    data_file.close();


  }


    int nl; //= DEFAULT_NL;
    int nr; //= DEFAULT_NR;
    int ld = DEFAULT_LD;
    int m; //= DEFAULT_M;
    int mm = rowcount;

    printf("Parameters=%d %d\n\n", window, polyorder);
    nl = window / 2;
    nr = nl;
    m = polyorder;

    int np = nl + 1 + nr;
    double *c;
    char retval;

    int j;
    long int k;
    c = dvector(1, nl + nr + 1);

    retval = sgcoeff(c, np, nl, nr, ld, m);

    warming_kernel<<<1, 1>>>();
    cudaDeviceSynchronize();
    gettimeofday(&t0, NULL);
    if (retval == 0)
    {
        double *indata_gpu;
        double *outdata_gpu;
        double *c_gpu;
        double *x;
        int c_size = nl + nr + 2;
        cudaMalloc((void **)&indata_gpu, sizeof(double) * rowcount);
        cudaMalloc((void **)&outdata_gpu, sizeof(double) * rowcount);
        cudaMalloc((void **)&c_gpu, sizeof(double) * c_size);
        cudaMemcpy(indata_gpu, indata, sizeof(double) * rowcount, cudaMemcpyHostToDevice);
        cudaMemcpy(c_gpu, c, sizeof(double) * c_size, cudaMemcpyHostToDevice);
        dim3 block(BLOCKSIZE, 1);
        dim3 grid((size_t)(ceil(((float)rowcount + 1) / ((float)block.x))), 1);
        chrono::high_resolution_clock::time_point tt1, tt2;
        tt1 = chrono::high_resolution_clock::now();
        gettimeofday(&t2, NULL);
        savgol_kernel<<<grid, block>>>(indata_gpu, c_gpu, outdata_gpu, rowcount, nl, nr);
        cudaDeviceSynchronize();
        gettimeofday(&t3, NULL);
        tt2 = chrono::high_resolution_clock::now();
        chrono::duration<double> Latency = tt2 - tt1;
        int input_size_in_kbytes = 2 * (rowcount * sizeof(double)) / 1024;

        float Throughput = (float)input_size_in_kbytes / Latency.count();
        // ask the exposer to scrape the registry on incoming HTTP requests
        exposer.RegisterCollectable(registry);
        latencys_gauge.Add({{"gauge", "latency in sec"}}).Set(Latency.count());
        latencyms_gauge.Add({{"gauge", "latency in msec"}}).Set(Latency.count() * 1000);
        Throughput_gauge.Add({{"gauge", "result"}}).Set(Throughput);
#if 0
        for (;;)
        {
            std::cout << "Latency in sec " << Latency.count() << std::endl;
            std::cout << "Latency in msec " << Latency.count() * 1000 << std::endl;
            std::cout << "Throughput (KB/sec): " << Throughput << std::endl;
        }
#endif
        cudaMemcpy(outdata, outdata_gpu, sizeof(double) * rowcount, cudaMemcpyDeviceToHost);
    }
    gettimeofday(&t1, NULL);
    double t10 = (t1.tv_sec * 1000000.0 + t1.tv_usec) - (t0.tv_sec * 1000000.0 + t0.tv_usec);
    fprintf(stderr, "total GPU process time: %lf msecs\n", (t10) / 1000.0F);
    double t32 = (t3.tv_sec * 1000000.0 + t3.tv_usec) - (t2.tv_sec * 1000000.0 + t2.tv_usec);
    fprintf(stderr, "only savgol GPU kernel time: %lf msecs\n", (t32) / 1000.0F);
    *time1 = t10;
    *time2 = t32;

    free_dvector(c, 1, nr + nl + 1);

    for (int i = 0; i < 10; i++)
    {

        printf("%lf ", indata[i]);
        printf("%lf\n ", outdata[i]);
    }

    ///////////////////////////////////////////////

    return 0;
}

extern "C" 

int savgol_GPU_unpack(void *out_args, size_t out_nargs, void* in_args, size_t in_nargs)
{

	struct vaccel_arg *in_arg = (struct vaccel_arg*)in_args;
        struct vaccel_arg *out_arg = (struct vaccel_arg*)out_args;

        int argc = 2;
	double time1, time2;
        char *argv[2] = {
                "vaccel",
                (char *)out_arg[0].buf
        };

        //printf("argv0=%s, %s\n", argv[0], argv[1]);
        //printf("out_arg[0]=%lf\n", *(float *)out_arg[0].buf);
        int ret = savgol_GPU(argc, argv, &time1, &time2);
        printf("ret=%d time1 %lf, time2 %lf\n", ret, time1, time2);

#if 1
        *(double*)in_arg[0].buf = time1;
        in_arg[0].len = sizeof(double);
        *(double*)in_arg[1].buf = time2;
        in_arg[1].len = sizeof(double);
#endif

//      fflush(stdout);
    	cudaDeviceReset();
        return 0;
}


