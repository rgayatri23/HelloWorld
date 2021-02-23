#!/usr/bin/env bash
set -e

#rgayatri@cgpu04:/global/cscratch1/sd/rgayatri/HelloWorld/build> srun -n1 nvidia-smi topo -m
#        GPU0    GPU1    GPU2    GPU3    GPU4    GPU5    GPU6    GPU7    mlx4_0  mlx5_0  mlx5_1  mlx5_2  mlx5_3  mlx5_4  mlx5_5  mlx5_6  mlx5_7  CPU Affinity    NUMA Affinity
#        GPU0     X      NV1     NV1     NV2     NV2     SYS     SYS     SYS     SYS     PIX     PIX     NODE    NODE    SYS     SYS     SYS     SYS     0-19,40-59      0
#        GPU1    NV1      X      NV2     NV1     SYS     NV2     SYS     SYS     SYS     PIX     PIX     NODE    NODE    SYS     SYS     SYS     SYS     0-19,40-59      0
#        GPU2    NV1     NV2      X      NV2     SYS     SYS     NV1     SYS     SYS     NODE    NODE    PIX     PIX     SYS     SYS     SYS     SYS     0-19,40-59      0
#        GPU3    NV2     NV1     NV2      X      SYS     SYS     SYS     NV1     SYS     NODE    NODE    PIX     PIX     SYS     SYS     SYS     SYS     0-19,40-59      0
#        GPU4    NV2     SYS     SYS     SYS      X      NV1     NV1     NV2     NODE    SYS     SYS     SYS     SYS     PIX     PIX     NODE    NODE    20-39,60-79     1
#        GPU5    SYS     NV2     SYS     SYS     NV1      X      NV2     NV1     NODE    SYS     SYS     SYS     SYS     PIX     PIX     NODE    NODE    20-39,60-79     1
#        GPU6    SYS     SYS     NV1     SYS     NV1     NV2      X      NV2     NODE    SYS     SYS     SYS     SYS     NODE    NODE    PIX     PIX     20-39,60-79     1
#        GPU7    SYS     SYS     SYS     NV1     NV2     NV1     NV2      X      NODE    SYS     SYS     SYS     SYS     NODE    NODE    PIX     PIX     20-39,60-79     1
#        mlx4_0  SYS     SYS     SYS     SYS     NODE    NODE    NODE    NODE     X      SYS     SYS     SYS     SYS     NODE    NODE    NODE    NODE
#        mlx5_0  PIX     PIX     NODE    NODE    SYS     SYS     SYS     SYS     SYS      X      PIX     NODE    NODE    SYS     SYS     SYS     SYS
#        mlx5_1  PIX     PIX     NODE    NODE    SYS     SYS     SYS     SYS     SYS     PIX      X      NODE    NODE    SYS     SYS     SYS     SYS
#        mlx5_2  NODE    NODE    PIX     PIX     SYS     SYS     SYS     SYS     SYS     NODE    NODE     X      PIX     SYS     SYS     SYS     SYS
#        mlx5_3  NODE    NODE    PIX     PIX     SYS     SYS     SYS     SYS     SYS     NODE    NODE    PIX      X      SYS     SYS     SYS     SYS
#        mlx5_4  SYS     SYS     SYS     SYS     PIX     PIX     NODE    NODE    NODE    SYS     SYS     SYS     SYS      X      PIX     NODE    NODE
#        mlx5_5  SYS     SYS     SYS     SYS     PIX     PIX     NODE    NODE    NODE    SYS     SYS     SYS     SYS     PIX      X      NODE    NODE
#        mlx5_6  SYS     SYS     SYS     SYS     NODE    NODE    PIX     PIX     NODE    SYS     SYS     SYS     SYS     NODE    NODE     X      PIX
#        mlx5_7  SYS     SYS     SYS     SYS     NODE    NODE    PIX     PIX     NODE    SYS     SYS     SYS     SYS     NODE    NODE    PIX      X


# this is the list of GPUs we have
GPUS=(0 1 2 3 4 5 6 7)

# This is the list of NICs we should use for each GPU
# This is based on matching GPUs to PIX, which is "more connected" than SYS
NICS=(mlx5_0:1 mlx5_1:1 mlx5_2:1 mlx5_3:1 mlx5_4:1 mlx5_5:1 mlx5_6:1 mlx5_7:1)

# This is the list of CPU numa regions we should use for each GPU
# The NUMA Affinity info seems a little weird, so I'm making some socket
# binding assumptions
CPUS=(0 0 0 0 1 1 1 1)

# this is the order we want the GPUs to be assigned in (e.g. for NVLink connectivity)
# this reordering is because GPU0 and GPU3 are bound by 2xNVLink, so we prioritize this
# for 2 GPU performance
REORDER=(0 3 1 2 4 7 5)

# now given the REORDER array, we set CUDA_VISIBLE_DEVICES, NIC_REORDER and CPU_REORDER to for this mapping
export CUDA_VISIBLE_DEVICES="${GPUS[${REORDER[0]}]},${GPUS[${REORDER[1]}]},${GPUS[${REORDER[2]}]},${GPUS[${REORDER[3]}]},${GPUS[${REORDER[4]}]},${GPUS[${REORDER[5]}]},${GPUS[${REORDER[6]}]},${GPUS[${REORDER[7]}]}"
NIC_REORDER=(${NICS[${REORDER[0]}]} ${NICS[${REORDER[1]}]} ${NICS[${REORDER[2]}]} ${NICS[${REORDER[3]}]} ${NICS[${REORDER[4]}]} ${NICS[${REORDER[5]}]} ${NICS[${REORDER[6]}]} ${NICS[${REORDER[7]}]})
CPU_REORDER=(${CPUS[${REORDER[0]}]} ${CPUS[${REORDER[1]}]} ${CPUS[${REORDER[2]}]} ${CPUS[${REORDER[3]}]} ${CPUS[${REORDER[4]}]} ${CPUS[${REORDER[5]}]} ${CPUS[${REORDER[6]}]} ${CPUS[${REORDER[7]}]})


APP="$EXE"

lrank=$SLURM_LOCALID


export UCX_NET_DEVICES=${NIC_REORDER[$lrank]}
numactl_cmd="numactl --cpunodebind=${CPU_REORDER[$lrank]} --membind=${CPU_REORDER[$lrank]}"
echo "Local rank $lrank using UCX device $UCX_NET_DEVICES running $APP"

echo "$numactl_cmd $APP"
$numactl_cmd $APP
#$APP
