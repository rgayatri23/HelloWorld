/*
 * A simple Hello World program for MPI by Rahulkumar Gayatri.
 */
#include <mpi.h>
#include <sched.h>
#include <iostream>

int main(int argc, char* argv[]) {
    int myid, namelen, world_size;
    char myname[MPI_MAX_PROCESSOR_NAME];

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myid);
    MPI_Get_processor_name(myname, &namelen);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    char* lrank = getenv("SLURM_PROCID");

    printf("Lrank from MPI = %s", lrank);

    char my_gpu[15];

    fprintf(stdout,
            "Hello Rahul from processor %s, rank = %d out of %d processors"
            "\n",
            myname, myid, world_size);

    // synchronize so the loop guarantees to prints all the information of one
    // rank before progressing.
    MPI_Barrier(MPI_COMM_WORLD);

    fprintf(stdout,
            "\n****************************************************************"
            "******************** \n");
    MPI_Finalize();

    return 0;
}
