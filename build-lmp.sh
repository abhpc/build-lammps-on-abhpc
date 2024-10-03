#! /bin/bash

export SOFT_SERV="http://118.123.172.217:40899"

# Choose LAMMPS version
echo "Choose LAMMPS version to compile ():"
echo "  1) 23Jun2022"
echo "  2) 8Aug2023"
read -t 15 -p "You have 15 seconds to decide: " choice
    case $choice in
        1)
            LMP_VERSION="23Jun2022"
            ;;
        2)
            LMP_VERSION="8Aug2023"
            ;;
        *)
            echo "Error: invalid Exiting..."
            exit 0
            ;;
    esac

# debug 1: check the lammps version
#echo "The LAMMPS version is: $LMP_VERSION"
#exit 0

# Ext packages path
VORONOI_PATH=$(cat path.conf|grep VORONOI_PATH|awk '{print $2}')
VORONOI_CFLAG=$(cat path.conf|grep VORONOI_CFLAG|awk -F '"' '{print $2}')
EIGEN_PATH=$(cat path.conf|grep EIGEN_PATH|awk '{print $2}')
LMP_PATH=$(cat path.conf|grep LMP_PATH|awk '{print $2}')

# debug 2: check install directories
echo "VORONOI_PATH=$VORONOI_PATH"
echo "EIGEN_PATH=$EIGEN_PATH"
echo "LMP_PATH=$LMP_PATH/$LMP_VERSION"
echo "VORONOI_CFLAG=$VORONOI_CFLAG"
LMP_PATH=$LMP_PATH/$LMP_VERSION
#exit 0

# Load environment modules
module purge
module load compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0 gcc/7.5.0

# Check if voro++-0.4.6 is already installed
if [ -d "$VORONOI_PATH" ]; then
        echo "voro++-0.4.6 is already installed in $VORONOI_PATH. Skipping installation."
        echo -e "----------------------------------------------------------------------------------------------------------\n"
else
        echo -e "------------------------------- Install VORONOI Package voro++-0.4.6 -------------------------------------"
        echo "Downloading voro++-0.4.6.tar.gz ..."
        wget --no-check-certificate http://mx.yinhe596.cn:40899/files/voro++-0.4.6.tar.gz 1>/dev/null
        echo -e "Done!\n"
        
        echo "Uncompress voro++-0.4.6.tar.gz ..."
        tar -xzf voro++-0.4.6.tar.gz 1>/dev/null
        cd voro++-0.4.6/
        sed -i "s@PREFIX=/usr/local@PREFIX=$VORONOI_PATH@g" config.mk
        sed -i "s@CXX=g++@CXX=icc@g" config.mk
        sed -i "s@O3@$VORONOI_CFLAG@g" config.mk

        echo "Make and make install ..."
        make 1>/dev/null && make install 1>/dev/null
        cd .. && rm -rf voro++-0.4.6/ voro++-0.4.6.tar.gz
        echo -e "------------------------- VORONOI Package voro++-0.4.6 installation done! --------------------------------\n"
fi

# Check if eigen-3.4.0 is already installed
if [ -d "$EIGEN_PATH" ]; then
        echo "eigen 3.4.0 is already installed in $EIGEN_PATH. Skipping installation."
        echo -e "----------------------------------------------------------------------------------------------------------\n"
else
        echo -e "--------------------------------- Install EIGEN Package eigen-3.4.0 --------------------------------------"
        echo "Download eigen-3.4.0.tar.bz2 ..."
        wget --no-check-certificate http://mx.yinhe596.cn:40899/files/eigen-3.4.0.tar.bz2 1>/dev/null
        echo -e "Done!\n"

        tar -xf eigen-3.4.0.tar.bz2 1>/dev/null
        rm -rf $EIGEN_PATH
        mv eigen-3.4.0 $EIGEN_PATH
        rm -rf eigen-3.4.0.tar.bz2
        echo -e "--------------------------- EIGEN Package eigen-3.4.0 installation done! ---------------------------------\n"
fi

# Build LAMMPS 23Jun2022
YES_INC=$(cat $LMP_VERSION/package.sta|grep -i yes|awk '{print $2}')
wget $SOFT_SERV/lammps-${LMP_VERSION}.tar.gz --no-check-certificate
SM_ARCH="sm_86"
ACC_TYPE="cpu"  # cpu, avx2 or gpu
CUDA_ROOT="/opt/cuda-12.0"
JN="20"

mkdir -p $LMP_PATH/bin
tar -xzf lammps-${LMP_VERSION}.tar.gz
cd lammps-$LMP_VERSION/src
CUDIR=`pwd`
M_TAR_FILE="$CUDIR/MAKE/OPTIONS/Makefile.intel_cpu_intelmpi"

#------------ Compiler Options ----------------------
sed -i "s@-xHost@-xCORE-AVX2@g" $M_TAR_FILE
sed -i "s@-std=c++11@-std=c++14 -no-ip @g" $M_TAR_FILE
sed -i "s@mpiicpc@mpiicc@g" $M_TAR_FILE
#sed -i "s@O2@O3@g" $M_TAR_FILE

#------------ Presion control ---------------------
#sed -i "s@-fp-model@-fp-model=precise@g" $M_TAR_FILE
#sed -i "s@fast=2@fast=1@g" $M_TAR_FILE
#sed -i "@-no-prec-div@ @g" $M_TAR_FILE

#------------ MPI options  -------------------------
#sed -i "s@-DMPICH_SKIP_MPICXX@-DMPICH_SKIP_MPICXX -I/opt/intel/oneapi/mpi/latest/include/ @g" $M_TAR_FILE
#sed -i "s@MPI_PATH =@MPI_PATH = -L/opt/intel/oneapi/mpi/latest/lib @g" $M_TAR_FILE

#----------- FFTW options  -------------------------
#sed -i "s@FFT_PATH =@FFT_PATH = -L/opt/intel/oneapi/mkl/latest/lib/intel64 @g" $M_TAR_FILE
#sed -i "s@FFT_INC =@FFT_INC = -I/opt/intel/oneapi/mkl/latest/include -I/opt/intel/oneapi/mkl/latest/include/fftw @g" $M_TAR_FILE
#sed -i "s@SINGLE@DOUBLE@g" $M_TAR_FILE
#sed -i "s@FFT_LIB =@FFT_LIB = -fPIC -lfftw2xf_double_intel -qmkl=cluster #@g" $M_TAR_FILE
#sed -i "s@FFT_LIB =@FFT_LIB = -fPIC -lfftw3x_cdft_lp64 -qmkl=cluster@g" $M_TAR_FILE

cp $M_TAR_FILE $CUDIR/MAKE/OPTIONS/Makefile.intel_cpu

# include
for i in $YES_INC
do
        make yes-$i
done


if [ "$ACC_TYPE" != "gpu" ]
then
        make no-gpu
fi

#------------ Set kokkos device=OpenMP---------------
sed -i '/SHLIBFLAGS =/ a\KOKKOS_DEVICES = OpenMP' $M_TAR_FILE


# Install ATC package
cd ../lib/atc/ && cp $I_MPI_ROOT/include/*.h ./  \
        && sed -i "s@icc@icc -diag-disable=10441 -diag-disable=2196@g" Makefile.icc \
        && make -j $JN -f Makefile.icc

# GPU package
if [ "$ACC_TYPE" = "gpu" ]
then
        cd ../gpu && sed -i "s@/usr/local/cuda@$CUDA_ROOT@g" Makefile.linux \
                                        && sed -i "s@sm_60@sm_86@g"   Makefile.linux \
                                        && sed -i "s@mpicxx@mpiicc@g" Makefile.linux \
                                        && sed -i "s@SINGLE_DOUBLE@SINGLE_SINGLE@g" Makefile.linux \
                                        && sed -i "s@mpiicc@mpiicc -std=c++11@g" Makefile.linux \
                                        && make -j $JN -f Makefile.linux \
                                        && sed -i "s@/usr/local/cuda@$CUDA_ROOT@g" Makefile.lammps
fi

# VORONOI package
cd ../voronoi && ln -s $VORONOI_PATH/include/voro++ ./includelink && ln -s $VORONOI_PATH/lib liblink

# machdyn package
cd ../machdyn && ln -s $EIGEN_PATH ./includelink


cd ../../src

# ML-PACE package
#make lib-pace args="-b"

make -j $JN intel_cpu

if [ "$ACC_TYPE" = "gpu" ]
then
        mv lmp_intel_cpu $LMP_PATH/bin/lammps-gpu
else
        mv lmp_intel_cpu $LMP_PATH/bin/lammps-cpu
fi
cd ..
mv examples $LMP_PATH
mv potentials $LMP_PATH
cd ..
rm -rf lammps-$LMP_VERSION

echo "#########################################"
echo " "
echo "The LAMMPS has been compiled successfully!"
echo " "
echo "#########################################"

# Generate modulefile
cat << EOF > $LMP_PATH/modulefile
#%Module 1.0
conflict lammps
prereq  mkl/2023.1.0
prereq  mpi/2021.9.0
prereq  gcc/7.5.0
prepend-path    PATH                    $LMP_PATH/bin
EOF