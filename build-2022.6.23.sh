#! /bin/sh

# Applied for May 14, 2016

module load icc/2023.1.0 mkl/2023.1.0 mpi/2021.9.0 gcc/7.5.0

LMP_VERSION="23Jun2022"
# sm_86
SM_ARCH="sm_86"
ACC_TYPE="cpu"  # cpu, avx2 or gpu
CUDA_ROOT="/opt/cuda-12.1"
JN="20"

# Ext packages path
VORONOI_PATH="/opt/mechanics/voro++-0.4.6icc"
EIGEN_PATH="/opt/devt/eigen-3.4.0"

set -e
INSTALL_DIR=$HOME
tar -xzf lammps-stable.tar.gz
cd lammps-$LMP_VERSION/src
CUDIR=`pwd`
M_TAR_FILE="$CUDIR/MAKE/OPTIONS/Makefile.intel_cpu_intelmpi"

#------------ Set kokkos device=OpenMP---------------
sed -i '/SHLIBFLAGS =/ a\KOKKOS_DEVICES = OpenMP' $M_TAR_FILE

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
YES_INC="ASPHERE MANYBODY ATC BOCS BODY BPM BROWNIAN MOLECULE CG-DNA CG-SDK CLASS2 COLLOID CORESHELL EXTRA-PAIR KSPACE DIELECTRIC DIFFRACTION DIPOLE DPD-BASIC DPD-MESO DPD-REACT DPD-SMOOTH DRUDE EFF EXTRA-COMPUTE EXTRA-DUMP EXTRA-FIX EXTRA-MOLECULE FEP GPU GRANULAR INTERLAYER KOKKOS LATBOLTZ MACHDYN MANIFOLD MC MEAM MGPT MISC ML-SNAP ML-IAP ML-RANN MOFFF MPIIO OPENMP OPT ORIENT PERI PHONON PLUGIN PTM QEQ QTB REACTION REAXFF REPLICA RIGID SHOCK SMTBQ SPH SPIN SRD TALLY UEF VORONOI YAFF"
#ALL="ADIOS ASPHERE ATC AWPMD BOCS BODY BPM BROWNIAN CG-DNA CG-SDK CLASS2 COLLOID COLVARS COMPRESS CORESHELL DIELECTRIC DIFFRACTION DIPOLE DPD-BASIC DPD-MESO DPD-REACT DPD-SMOOTH DRUDE EFF ELECTRODE EXTRA-COMPUTE EXTRA-DUMP EXTRA-FIX EXTRA-MOLECULE EXTRA-PAIR FEP GPU GRANULAR H5MD INTEL INTERLAYER KIM KOKKOS KSPACE LATBOLTZ LATTE MACHDYN MANIFOLD MANYBODY MC MDI MEAM MESONT MGPT MISC ML-HDNNP ML-IAP ML-PACE ML-QUIP ML-RANN ML-SNAP MOFFF MOLECULE MOLFILE MPIIO MSCG NETCDF OPENMP OPT ORIENT PERI PHONON PLUGIN PLUMED POEMS PTM PYTHON QEQ QMMM QTB REACTION REAXFF REPLICA RIGID SCAFACOS SHOCK SMTBQ SPH SPIN SRD TALLY UEF VORONOI VTK YAFF"

for i in $YES_INC
do
        make yes-$i
done


if [ "$ACC_TYPE" != "gpu" ]
then
        make no-gpu
fi

#cd ../poems/ && make -j $JN -f Makefile.icc

cd ../lib/atc/ && cp /opt/intel/oneapi/mpi/latest/include/*.h ./  \
        && sed -i "s@icc@icc -diag-disable=10441 -diag-disable=2196@g" Makefile.icc \
        && make -j $JN -f Makefile.icc \
        && sed -i "s@-lblas@ @g" Makefile.lammps \
        && sed -i "s@-llapack@ @g" Makefile.lammps

#cd ../awpmd/ && sed -i "s/mpic++/mpiicc/g" Makefile.mpicc && make -f Makefile.mpicc
#cd ../colvars/ && cp Makefile.g++ Makefile.icc && sed -i 's/g++/icc/g' Makefile.icc && make -f Makefile.icc

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

cd ../voronoi && ln -s $VORONOI_PATH/include/voro++ ./includelink && ln -s $VORONOI_PATH/lib liblink
cd ../machdyn && ln -s $EIGEN_PATH ./includelink


cd ../../src

make -j $JN intel_cpu

if [ "$ACC_TYPE" = "gpu" ]
then
        mv lmp_intel_cpu $INSTALL_DIR/lammps-gpu-$LMP_VERSION-$SM_ARCH
else
        mv lmp_intel_cpu $INSTALL_DIR/lammps-$ACC_TYPE-$LMP_VERSION
fi

cd ../..
rm -rf lammps-$LMP_VERSION

echo "#########################################"
echo " "
echo "The LAMMPS has been compiled successfully!"
echo " "
echo "#########################################"
