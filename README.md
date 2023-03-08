# HelloWorld

2 simple tests to check if MPI is working on the machine and is using CUDA correctly.

## Test codes

1. mpihello.cpp - Simple MPI code that just creates processes and prints out the ranks.
2. cudahello.cpp - Uses cuda calls from inside the MPI tasks to identify the GPUs visible to each MPI task.

## Build
To build the code use the `Makefile`. It's a simple Makefile that just builds both the tests using `mpicxx`.

`make` would build mpihello.cpp. `make all` would build both the tests.
