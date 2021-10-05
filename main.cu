%%cu
#include <fstream>
#include <iostream>
#include <cmath>
#include <vector>
using namespace std;

#define sqr(x) ((x) * (x))

static constexpr double EPS = 0.01;
static constexpr double F_EPS = 1e-6;
static const int INF = 1e9 + 7;


namespace Hartman3 {
    double a[4][3];
    double p[4][3];

    double c[4];

    int GetDimensions() {
        return 3;
    }

    void InitializeBorders(int** borders) {
        for (int i = 0; i < 3; ++i) {
            borders[i][0] = 0;
            borders[i][1] = 1;
        }
    }

    void AdditionalInitialize() {
        double A[4][3] = {
          { 3, 10, 30},
          { 0.1, 10, 35},
          { 3, 10, 30},
          { 0.1, 10, 35}
        };
        for (int i = 0; i < 4; ++i) {
          cudaMemcpyToSymbol(a[i], A[i], sizeof(double) * 3);
        }
        double P[4][3] = {
          { 0.3689, 0.1170, 0.2673},
          { 0.4699, 0.4387, 0.7470},
          { 0.1091, 0.8732, 0.5547},
          { 0.03815, 0.5743, 0.8828}
        };
        for (int i = 0; i < 4; ++i) {
          cudaMemcpyToSymbol(p[i], P[i], sizeof(double) * 3);
        }
        const double C[4] = {1.0, 1.2, 3.0, 3.2};
        cudaMemcpyToSymbol(c, C, sizeof(double) * 4);
    }

    __device__
    double func(double* x) {
        double y = 0.0;
        for (int i = 0; i < 4; i++) {
            double e = 0.0;
            for (int j = 0; j < 3; j++)
                e += a[i][j] * sqr(x[j] - p[i][j]);
            printf("c[i] = %lf\n", c[i]);
            y += c[i] * exp(-e);
        }
        return -y;
    }
} 

namespace Ackley3 {
    // bounds = [-32, 32], [-32, 32], min = 82.4617 at (-32, -32)

    int GetDimensions() {
        return 2;
    }

    void InitializeBorders(int** borders) {
        int bordersHost[2][2] = {{-32000, 32000}, {-32000, 32000}};

        for (int i = 0; i < 2; ++i) {
            cudaMemcpy(borders[i], bordersHost[i], sizeof(int) * 2, cudaMemcpyHostToDevice);
        }
    }

    __device__
    double func(double* x) {
        return 200 * exp(-0.02 * sqrt(sqr(x[0]) + sqr(x[1]))) + 5 * exp(cos(3 * x[0]) + sin(3 * x[1]));
    }
}

namespace StyblinskiTang {
    int GetDimensions() {
        return 2;
    }

    void InitializeBorders(int** borders) {
        int bordersHost[2][2] = {{-5, 5}, {-5, 5}};

        for (int i = 0; i < 2; ++i) {
            cudaMemcpy(borders[i], bordersHost[i], sizeof(int) * 2, cudaMemcpyHostToDevice);
        }
    }

    __device__
    double func(double* x) {
        return 0.5 * (pow(x[0], 4) - 16 * sqr(x[0]) + 5 * x[0] + pow(x[1], 4) - 16 * sqr(x[1]) + 5 * x[1]);
    }
}

namespace Beale {
    int GetDimensions() {
        return 2;
    }

    void InitializeBorders(int** borders) {
        int bordersHost[2][2] = {{-5, 5}, {-5, 5}};

        for (int i = 0; i < 2; ++i) {
            cudaMemcpy(borders[i], bordersHost[i], sizeof(int) * 2, cudaMemcpyHostToDevice);
        }
    }

    __device__
    double func(double* x) {
        return sqr(1.5 - x[0] + x[0] * x[1]) + sqr(2.25 - x[0] + x[0] * sqr(x[1])) + sqr(2.625 - x[0] + x[0] * (x[1] * x[1] * x[1]));
    }
}

namespace EggHolder {
    int GetDimensions() {
        return 2;
    }

    void InitializeBorders(int** borders) {
        int bordersHost[2][2] = {{-512, 512}, {-512, 512}};

        for (int i = 0; i < 2; ++i) {
            cudaMemcpy(borders[i], bordersHost[i], sizeof(int) * 2, cudaMemcpyHostToDevice);
        }
    }

    __device__
    double func(double* x) {
        return -(x[1] + 47) * sin(sqrt(abs(x[1] + x[0] / 2.0 + 47))) - x[0] * sin(sqrt(abs(x[0] - x[1] - 47)));
    }
}

namespace Rosenbrock {
    int GetDimensions() {
        return 3;
    }

    void InitializeBorders(int** borders) {
        int bordersHost[3][2] = {{-30, 30}, {-30, 30}, {-30, 30}};

        for (int i = 0; i < 3; ++i) {
            cudaMemcpy(borders[i], bordersHost[i], sizeof(int) * 3, cudaMemcpyHostToDevice);
        }
    }

    __device__
    double func(double* x) {
        return sqr(1 - x[0]) + 100 * sqr(x[1] - sqr(x[0])) + sqr(1 - x[1]) + 100 * sqr(x[2] - sqr(x[1]));
    }
}

__device__
double atomicMin(double* address, double val) {
    unsigned long long int* address_as_ull = (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(min(val,
                               __longlong_as_double(assumed))));
    } while (assumed != old);

    return __longlong_as_double(old);
}

__device__
double f(double* x) {
    return Beale::func(x);
}

__device__
double calcL(double* x, double* y, double step) {
    return fabs(f(x) - f(y)) / step;
}

__device__
double calcK(double diameter) {
    return exp(diameter);
}

__device__
bool checkStop(int k, int lastModified, double f_rec, double f_pred, double L_rec, double* threadWidth, double dimensions, double error, double diameter, double* globalResult) {
    if (k == 2) {
        if (diameter * L_rec < 2 * (error + f_rec - *globalResult)) {
            return true;
        }
        return false;
    }
    if (k - lastModified > 3) {
        return true;
    }

    return diameter * L_rec < 2 * (error + f_rec - *globalResult) || fabs(f_pred - f_rec) < error || fabs(f_pred - f_rec) / f_pred < EPS;
}

__device__ double calcLStart(int dimensions, double* x_center, double* x_next, double* x_0, double* threadWidth, double step) {
    if (dimensions == 2) {
        double L_rec = 0;
        for (int i = 0; i < dimensions; ++i) {
            x_next[i] = x_0[i];
        }
        L_rec = calcL(x_center, x_next, step / 2);
        x_next[0] += threadWidth[0];
        L_rec = max(L_rec, calcL(x_center, x_next, step / 2));
        x_next[1] += threadWidth[1];
        L_rec = max(L_rec, calcL(x_center, x_next, step / 2));
        x_next[0] = x_0[0];
        L_rec = max(L_rec, calcL(x_center, x_next, step / 2));
        return L_rec;
    }
    double L_rec = 0;
    int diff[8][3] = {{0, 0, 1}, {0, 1, 0}, {0, 1, 1}, {1, 0, 0}, {1, 0, 1}, {1, 1, 0}, {1, 1, 1}};
    for (int i = 0; i < 8; ++i) {
        int mult = 1;
        for (int j = 0; j < 2; ++j) {
            mult *= -1;
            for (int k = 0; k < dimensions; ++k) {
                x_next[k] = x_0[k] + mult * diff[i][k];
            }
            L_rec = max(L_rec, calcL(x_center, x_next, step / 2));
        }
    }
    return L_rec;
}

__global__
void apply(int** borders, int* blockCount, int blockWidth, int blockSize, int dimensions, double* threadWidth,
           double error, double* globalResult, unsigned int* steps, double diameter, double* results) {
    int idxBlock = blockIdx.x;
    int idxThread = threadIdx.x;
    int index;
    double x_center[3];
    double x_0[3];
    double x_cur[3];
    double x_next[3];
    for (int i = 0; i < dimensions; ++i) {
        index = (idxBlock % blockCount[i]) * blockWidth + idxThread % blockWidth;
        x_0[i] = index * threadWidth[i] + borders[i][0];
        x_center[i] = x_0[i] + (threadWidth[i] / 2.0);
        idxThread /= blockWidth;
        idxBlock /= blockCount[i];
    }
    // calculate f() in the center
    double f_rec = f(x_center);
    atomicMin(globalResult, f_rec);
    double L_rec = calcLStart(dimensions, x_center, x_next, x_0, threadWidth, diameter);
    int k = 2;
    double L_cur;
    double f_cur;
    double f_pred = INF;
    int lastModified = 2;
    int stepsCur = 0;
    while (!checkStop(k, lastModified, f_rec, f_pred, L_rec, threadWidth, dimensions, error, diameter, globalResult)) {
        for (int j = 0; j < k; ++j) {
            for (int i = 0; i < dimensions; ++i) {
                x_cur[i] = x_0[i] + (threadWidth[i] / k) * j;
                x_next[i] = x_cur[i];
            }
            f_cur = f(x_cur);
            if (f_cur < f_rec - F_EPS) {
                lastModified = k;
                f_pred = f_rec;
                f_rec = f_cur;
            }
            for (int i = 0; i < dimensions; ++i) {
                x_next[i] += threadWidth[i] / k;
                L_cur = calcL(x_cur, x_next, threadWidth[i] / k);
                if (L_cur > L_rec) {
                    L_rec = L_cur;
                }
            }
        }
        stepsCur += k;
        k++;
    }
    results[blockIdx.x * blockSize + threadIdx.x] = f_rec;
    steps[blockIdx.x * blockSize + threadIdx.x] = k - 1;
    atomicMin(globalResult, f_rec);
}


int runTest(int* blockCountH, double error, int blockSize, double* time, double* averageSteps) {
    int dimensions = Beale::GetDimensions();
    int** borders;
    cudaMallocManaged(&borders, dimensions * sizeof(int*));
    for (int i = 0; i < dimensions; ++i) {
        cudaMallocManaged(&borders[i], sizeof(int) * 2);
    }

    Beale::InitializeBorders(borders);

    int* blockCount;
    cudaMallocManaged(&blockCount, sizeof(int) * dimensions);
    int blocksNumAll = 1;
    for (int i = 0; i < dimensions; ++i) {
         blocksNumAll *= blockCountH[i];
    }
    cudaMemcpy(blockCount, blockCountH, sizeof(int) * dimensions, cudaMemcpyHostToDevice);

    int blockWidth = sqrt(blockSize);
    if (dimensions == 3) {
        blockSize = 64;
        blockWidth = 4;
    }
    double* threadWidth;
    double* globalResult;
    double* results;
    unsigned int* steps;

    cudaMallocManaged(&threadWidth, sizeof(double) * dimensions);
    cudaMallocManaged(&globalResult, sizeof(double));
    cudaMallocManaged(&steps, sizeof(unsigned int) * blockSize * blocksNumAll);
    cudaMallocManaged(&results, sizeof(double) * blockSize * blocksNumAll);
    double* threadWidthHost = (double*)malloc(sizeof(double) * dimensions);
    double diameter = 0;
    for (int i = 0; i < dimensions; ++i) {
        threadWidthHost[i] = (borders[i][1] - borders[i][0]) / (double)(blockCount[i] * blockWidth);
        diameter += sqr(threadWidthHost[i]);
    }
    diameter = sqrt(diameter);

    cudaMemcpy(threadWidth, threadWidthHost, sizeof(double) * dimensions, cudaMemcpyHostToDevice);

    double globalResultHost[1];
    globalResultHost[0] = INF;
    cudaMemcpy(globalResult, globalResultHost, sizeof(double), cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    apply<<<blocksNumAll, blockSize>>>(borders, blockCount, blockWidth, blockSize, dimensions, threadWidth, error, globalResult, steps, diameter, results);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    double ans[2];
    cudaMemcpy(ans, globalResult, sizeof(double), cudaMemcpyDeviceToHost);
    unsigned int stepCount[blocksNumAll * blockSize];
    cudaMemcpy(stepCount, steps, sizeof(unsigned int) * blocksNumAll * blockSize, cudaMemcpyDeviceToHost);
    double resultsGlobal[blocksNumAll * blockSize];
    cudaMemcpy(resultsGlobal, results, sizeof(double) * blocksNumAll * blockSize, cudaMemcpyDeviceToHost);
    double record = INF;
    for (int i = 0; i < blocksNumAll * blockSize; ++i) {
        record = min(record, resultsGlobal[i]);
    }
    int allSteps = 0;
    for (int i = 0; i < blocksNumAll * blockSize; ++i) {
        allSteps += stepCount[i];
    }
    cout << "Global min value is " << record << ", steps = " << allSteps 
         << ", avgSteps = " << (double)allSteps / (blocksNumAll * blockSize) << ", threadsCount = " << (blocksNumAll * blockSize) << endl;
    float timeSpent;
    cudaEventElapsedTime(&timeSpent, start, stop);
    cout << timeSpent << " " << allSteps << endl;
    *time = timeSpent;
    *averageSteps = (double)allSteps / (blocksNumAll * blockSize);

    for (int i = 0; i < dimensions; ++i) {
        cudaFree(borders[i]);
    }
    free(threadWidthHost);
    cudaFree(borders);
    cudaFree(blockCount);
    cudaFree(threadWidth);

    return allSteps;
}


int main() {
    double error = 0.001;
    int blockCount[3];
    int BLOCKS = 5;
    int blockSize = 64;
    double timeSpent;
    double avgSteps;
    ofstream fout("beale_threads_16_new");
    for (int i = 2; i < 3; ++i) {
        blockCount[0] = blockCount[1] = blockCount[2] = i;
        int threadsNumAll = i * i * blockSize;
        int iterCount = runTest(blockCount, error, blockSize, &timeSpent, &avgSteps);
        fout << i << " " << iterCount << " " << timeSpent << " " << avgSteps << " " << threadsNumAll << endl;
    }
    fout.close();
    return 0;
}
