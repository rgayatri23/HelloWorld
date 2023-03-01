#include <cuda.h>
#include <cuda_runtime.h>
#include <mpi.h>
#include <omp.h>
#include <sched.h>
#include <iostream>

int find_gpus(void) {
    int ngpu;
    cudaGetDeviceCount(&ngpu);
    return ngpu;
}
void gpu_pci_id(char* device_id, int device_num) {
    int len = 32;
    int ret = cudaDeviceGetPCIBusId(device_id, len, device_num) ;
    if (!ret)
        return;
    else
    {
        printf("Could not get the gpu-id. Error code = %d\n",ret);
        exit(1);
    }
}

extern int sched_getcpu(void);

int main(int argc, char* argv[]) {
    int myid, namelen, world_size;
    char myname[MPI_MAX_PROCESSOR_NAME];

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myid);
    MPI_Get_processor_name(myname, &namelen);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    char* lrank = getenv("SLURM_PROCID");

    // Set nthreads to 2 unless OMP_NUM_THREADS is defined.
    int nthreads = getenv("OMP_NUM_THREADS") ? atoi(getenv("OMP_NUM_THREADS")) : 2;

    int max_threads = omp_get_max_threads();
    

    printf("Lrank from MPI = %s, num_threads = %d, max_threads = %d\n", lrank, nthreads, max_threads);

    int ngpu = find_gpus();
    char my_gpu[15];

    fprintf(stdout,
            "Hello Rahul from processor %s, rank = %d out of %d processors"
            "\n",
            myname, myid, world_size);
    char my_gpu_id[15];
    gpu_pci_id(my_gpu_id, myid);
    fprintf(stdout, "My GPU = %s\n", my_gpu_id);

    fprintf(stdout, "I see a total of %d GPUs and the other PCI IDs are: \n",
            ngpu);

    for (int j = 0; j < ngpu; j++) {
        if (j != myid) {
            char gpu_id[15];
            gpu_pci_id(gpu_id, j);
            fprintf(stdout, "rank = %d: %s\n", j, gpu_id);
        }
    }

    // synchronize so the loop guarantees to prints all the information of one
    // rank before progressing.
    MPI_Barrier(MPI_COMM_WORLD);

    fprintf(stdout, "CPUs and Threads assigned to me are \n");

#pragma omp parallel for ordered num_threads(nthreads)
    for (int i = 0; i < nthreads; ++i) {
#pragma omp ordered
        fprintf(stdout, "rank = %04d, thread = %03d, cpu = %03d\n", myid,
                omp_get_thread_num(), sched_getcpu());
    }

    fprintf(stdout,
            "\n****************************************************************"
            "******************** \n");

    MPI_Finalize();
}
