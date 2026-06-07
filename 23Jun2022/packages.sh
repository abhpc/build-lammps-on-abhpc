#!/usr/bin/env bash

# Version-specific package hooks for LAMMPS 23Jun2022.

version_package_description() {
    if is_zh; then
        case "$1" in
            ADIOS) printf "通过 ADIOS 进行高性能 dump/read_dump I/O\n" ;;
            ASPHERE) printf "非球形有限尺寸粒子模型\n" ;;
            ATC) printf "原子-连续介质耦合方法\n" ;;
            AWPMD) printf "反对称波包分子动力学\n" ;;
            BOCS) printf "自底向上粗粒化压力修正\n" ;;
            BODY) printf "带内部结构的 body 粒子模型\n" ;;
            BPM) printf "用于断裂和固体的键合粒子模型\n" ;;
            BROWNIAN) printf "布朗动力学和自推进粒子\n" ;;
            CG-DNA) printf "粗粒化 DNA 力场\n" ;;
            CG-SDK) printf "SPICA 粗粒化力场样式\n" ;;
            CLASS2) printf "Class II 分子力场\n" ;;
            COLLOID) printf "胶体粒子模型\n" ;;
            COLVARS) printf "Collective variables 库接口\n" ;;
            COMPRESS) printf "dump 等文件的压缩 I/O 支持\n" ;;
            CORESHELL) printf "绝热 core/shell 模型\n" ;;
            DIELECTRIC) printf "介电边界求解器和力场样式\n" ;;
            DIFFRACTION) printf "虚拟 X 射线和电子衍射计算\n" ;;
            DIPOLE) printf "点偶极粒子模型\n" ;;
            DPD-BASIC) printf "基础耗散粒子动力学模型\n" ;;
            DPD-MESO) printf "介观耗散粒子动力学模型\n" ;;
            DPD-REACT) printf "反应型耗散粒子动力学模型\n" ;;
            DPD-SMOOTH) printf "平滑耗散粒子动力学模型\n" ;;
            DRUDE) printf "Drude 振子极化力场\n" ;;
            EFF) printf "电子力场模型\n" ;;
            ELECTRODE) printf "目标电势电极电荷平衡\n" ;;
            EXTRA-COMPUTE) printf "额外 compute 样式\n" ;;
            EXTRA-DUMP) printf "额外 dump 样式\n" ;;
            EXTRA-FIX) printf "额外 fix 样式\n" ;;
            EXTRA-MOLECULE) printf "额外分子样式\n" ;;
            EXTRA-PAIR) printf "额外 pair 样式\n" ;;
            FEP) printf "自由能微扰工具\n" ;;
            GPU) printf "CUDA/OpenCL GPU 加速样式\n" ;;
            GRANULAR) printf "颗粒材料模型\n" ;;
            H5MD) printf "HDF5/H5MD dump 输出支持\n" ;;
            INTEL) printf "Intel CPU 和 KNL 优化样式\n" ;;
            INTERLAYER) printf "层间相互作用势\n" ;;
            KIM) printf "OpenKIM 模型驱动接口\n" ;;
            KOKKOS) printf "Kokkos 可移植 CPU/GPU 加速样式\n" ;;
            KSPACE) printf "长程库仑求解器\n" ;;
            LATBOLTZ) printf "格子 Boltzmann 流体耦合\n" ;;
            LATTE) printf "LATTE 紧束缚接口\n" ;;
            MACHDYN) printf "平滑 Mach 动力学模型\n" ;;
            MANIFOLD) printf "约束到二维流形的运动\n" ;;
            MANYBODY) printf "多体原子间势\n" ;;
            MC) printf "Monte Carlo 移动和采样 fix\n" ;;
            MDI) printf "MolSSI Driver Interface 客户端/服务器耦合\n" ;;
            MEAM) printf "改进嵌入原子法势\n" ;;
            MESONT) printf "介观管状势模型\n" ;;
            MGPT) printf "快速 MGPT 多离子势\n" ;;
            MISC) printf "杂项单文件命令\n" ;;
            ML-HDNNP) printf "高维神经网络势\n" ;;
            ML-IAP) printf "机器学习原子间势\n" ;;
            ML-PACE) printf "原子簇展开势\n" ;;
            ML-QUIP) printf "QUIP/libatoms 势接口\n" ;;
            ML-RANN) printf "随机激活神经网络势\n" ;;
            ML-SNAP) printf "谱邻域分析势\n" ;;
            MOFFF) printf "MOF-FF 力场样式\n" ;;
            MOLECULE) printf "分子体系力场\n" ;;
            MOLFILE) printf "VMD molfile 插件 dump 支持\n" ;;
            MPIIO) printf "基于 MPI-IO 的 dump/restart 支持\n" ;;
            MSCG) printf "多尺度粗粒化接口\n" ;;
            NETCDF) printf "NetCDF dump 输出支持\n" ;;
            OPENMP) printf "OpenMP 多线程样式\n" ;;
            OPT) printf "CPU 优化 pair 样式\n" ;;
            ORIENT) printf "取向相关力学 fix\n" ;;
            PERI) printf "近场动力学模型\n" ;;
            PHONON) printf "声子动力学矩阵工具\n" ;;
            PLUGIN) printf "运行时插件加载命令\n" ;;
            PLUMED) printf "PLUMED 自由能库接口\n" ;;
            POEMS) printf "通过 POEMS 处理刚体动力学\n" ;;
            PTM) printf "多面体模板匹配\n" ;;
            PYTHON) printf "在输入脚本中嵌入 Python 代码\n" ;;
            QEQ) printf "电荷平衡 fix\n" ;;
            QMMM) printf "量子/经典 QM/MM 耦合\n" ;;
            QTB) printf "量子热浴方法\n" ;;
            REACTION) printf "经典 MD 中的化学反应\n" ;;
            REAXFF) printf "ReaxFF 反应力场\n" ;;
            REPLICA) printf "多副本模拟方法\n" ;;
            RIGID) printf "刚体和约束 fix\n" ;;
            SCAFACOS) printf "ScaFaCoS 长程求解器封装\n" ;;
            SHOCK) printf "冲击加载方法\n" ;;
            SMTBQ) printf "二阶矩紧束缚势\n" ;;
            SPH) printf "光滑粒子流体动力学\n" ;;
            SPIN) printf "磁性原子自旋动力学\n" ;;
            SRD) printf "随机旋转动力学\n" ;;
            TALLY) printf "成对 tally 计算\n" ;;
            UEF) printf "均匀拉伸流 fix\n" ;;
            VORONOI) printf "Voronoi 镶嵌计算\n" ;;
            VTK) printf "VTK dump 输出支持\n" ;;
            YAFF) printf "来自 YAFF 力场的额外样式\n" ;;
            *) printf "详见 LAMMPS package 文档\n" ;;
        esac
        return 0
    fi

    case "$1" in
        ADIOS) printf "high-performance dump/read_dump I/O through ADIOS\n" ;;
        ASPHERE) printf "aspherical finite-size particle models\n" ;;
        ATC) printf "atom-to-continuum coupling methods\n" ;;
        AWPMD) printf "antisymmetrized wave packet molecular dynamics\n" ;;
        BOCS) printf "bottom-up coarse-graining pressure correction\n" ;;
        BODY) printf "body-style particles with internal structure\n" ;;
        BPM) printf "bonded particle models for fracture and solids\n" ;;
        BROWNIAN) printf "Brownian dynamics and self-propelled particles\n" ;;
        CG-DNA) printf "coarse-grained DNA force fields\n" ;;
        CG-SDK) printf "SPICA coarse-grained force field styles\n" ;;
        CLASS2) printf "class II molecular force fields\n" ;;
        COLLOID) printf "colloidal particle models\n" ;;
        COLVARS) printf "collective variables library interface\n" ;;
        COMPRESS) printf "compressed I/O for dump and related files\n" ;;
        CORESHELL) printf "adiabatic core/shell model\n" ;;
        DIELECTRIC) printf "dielectric boundary solvers and force styles\n" ;;
        DIFFRACTION) printf "virtual x-ray and electron diffraction computes\n" ;;
        DIPOLE) printf "point dipole particle models\n" ;;
        DPD-BASIC) printf "basic dissipative particle dynamics models\n" ;;
        DPD-MESO) printf "mesoscale dissipative particle dynamics models\n" ;;
        DPD-REACT) printf "reactive dissipative particle dynamics models\n" ;;
        DPD-SMOOTH) printf "smoothed dissipative particle dynamics models\n" ;;
        DRUDE) printf "Drude oscillator polarizable force fields\n" ;;
        EFF) printf "electron force field models\n" ;;
        ELECTRODE) printf "electrode charge equilibration to target potential\n" ;;
        EXTRA-COMPUTE) printf "additional compute styles\n" ;;
        EXTRA-DUMP) printf "additional dump styles\n" ;;
        EXTRA-FIX) printf "additional fix styles\n" ;;
        EXTRA-MOLECULE) printf "additional molecular styles\n" ;;
        EXTRA-PAIR) printf "additional pair styles\n" ;;
        FEP) printf "free energy perturbation tools\n" ;;
        GPU) printf "CUDA/OpenCL GPU-accelerated styles\n" ;;
        GRANULAR) printf "granular material models\n" ;;
        H5MD) printf "HDF5/H5MD dump output support\n" ;;
        INTEL) printf "Intel CPU and KNL optimized styles\n" ;;
        INTERLAYER) printf "inter-layer pair potentials\n" ;;
        KIM) printf "OpenKIM model driver interface\n" ;;
        KOKKOS) printf "Kokkos portable CPU/GPU accelerated styles\n" ;;
        KSPACE) printf "long-range Coulombic solvers\n" ;;
        LATBOLTZ) printf "lattice Boltzmann fluid coupling\n" ;;
        LATTE) printf "LATTE tight-binding interface\n" ;;
        MACHDYN) printf "smoothed Mach dynamics models\n" ;;
        MANIFOLD) printf "motion constrained to 2D manifolds\n" ;;
        MANYBODY) printf "many-body interatomic potentials\n" ;;
        MC) printf "Monte Carlo moves and sampling fixes\n" ;;
        MDI) printf "MolSSI Driver Interface client/server coupling\n" ;;
        MEAM) printf "modified embedded atom method potential\n" ;;
        MESONT) printf "mesoscopic tubular potential models\n" ;;
        MGPT) printf "fast MGPT multi-ion potentials\n" ;;
        MISC) printf "miscellaneous single-file commands\n" ;;
        ML-HDNNP) printf "high-dimensional neural network potentials\n" ;;
        ML-IAP) printf "machine-learning interatomic potentials\n" ;;
        ML-PACE) printf "atomic cluster expansion potentials\n" ;;
        ML-QUIP) printf "QUIP/libatoms potential interface\n" ;;
        ML-RANN) printf "random activation neural network potentials\n" ;;
        ML-SNAP) printf "spectral neighbor analysis potentials\n" ;;
        MOFFF) printf "MOF-FF force-field styles\n" ;;
        MOLECULE) printf "molecular system force fields\n" ;;
        MOLFILE) printf "VMD molfile plugin dump support\n" ;;
        MPIIO) printf "MPI-IO based dump/restart support\n" ;;
        MSCG) printf "multi-scale coarse-graining interface\n" ;;
        NETCDF) printf "NetCDF dump output support\n" ;;
        OPENMP) printf "OpenMP threaded styles\n" ;;
        OPT) printf "optimized CPU pair styles\n" ;;
        ORIENT) printf "orientation-dependent force fixes\n" ;;
        PERI) printf "peridynamics models\n" ;;
        PHONON) printf "phonon dynamical matrix tools\n" ;;
        PLUGIN) printf "runtime plugin loader command\n" ;;
        PLUMED) printf "PLUMED free-energy library interface\n" ;;
        POEMS) printf "rigid body dynamics through POEMS\n" ;;
        PTM) printf "polyhedral template matching\n" ;;
        PYTHON) printf "embed Python code in input scripts\n" ;;
        QEQ) printf "charge equilibration fixes\n" ;;
        QMMM) printf "quantum/classical QM/MM coupling\n" ;;
        QTB) printf "quantum thermal bath methods\n" ;;
        REACTION) printf "chemical reactions in classical MD\n" ;;
        REAXFF) printf "ReaxFF reactive force field\n" ;;
        REPLICA) printf "multi-replica simulation methods\n" ;;
        RIGID) printf "rigid body and constraint fixes\n" ;;
        SCAFACOS) printf "ScaFaCoS long-range solver wrapper\n" ;;
        SHOCK) printf "shock loading methods\n" ;;
        SMTBQ) printf "second-moment tight-binding potentials\n" ;;
        SPH) printf "smoothed particle hydrodynamics\n" ;;
        SPIN) printf "magnetic atomic spin dynamics\n" ;;
        SRD) printf "stochastic rotation dynamics\n" ;;
        TALLY) printf "pairwise tally computes\n" ;;
        UEF) printf "uniform extensional flow fixes\n" ;;
        VORONOI) printf "Voronoi tessellation computes\n" ;;
        VTK) printf "VTK dump output support\n" ;;
        YAFF) printf "additional styles from the YAFF force field\n" ;;
        *) printf "see LAMMPS package documentation for details\n" ;;
    esac
}

version_package_dependency_kind() {
    case "$1" in
        ADIOS|COMPRESS|GPU|H5MD|KIM|KOKKOS|LATTE|MACHDYN|MDI|ML-HDNNP|ML-PACE|ML-QUIP|MOLFILE|MSCG|NETCDF|PLUMED|PYTHON|SCAFACOS|VORONOI|VTK)
            printf "external"
            ;;
        ATC|AWPMD|COLVARS|ELECTRODE|INTEL|KSPACE|LATBOLTZ|ML-IAP|MPIIO|OPENMP|OPT|PHONON|POEMS|QMMM)
            printf "extra"
            ;;
        *)
            printf "builtin"
            ;;
    esac
}

version_package_dependency() {
    if is_zh; then
        case "$1" in
            ADIOS) printf "第三方库: ADIOS2；需设置 ADIOS2_DIR 或 adios2-config，MPI 开关需匹配" ;;
            ATC) printf "附带库: lib/atc；还需 MANYBODY 和 BLAS/LAPACK 或内置 linalg" ;;
            AWPMD) printf "附带库: lib/awpmd；还需 BLAS/LAPACK 或内置 linalg" ;;
            COLVARS) printf "附带库: Colvars" ;;
            COMPRESS) printf "第三方库: zlib；可选 libzstd >= 1.4" ;;
            ELECTRODE) printf "依赖 package: KSPACE；还需 BLAS/LAPACK 或内置 linalg" ;;
            GPU) printf "第三方工具链: CUDA/OpenCL/HIP；本脚本 CUDA 构建需 nvcc" ;;
            H5MD) printf "第三方库: HDF5 C 库" ;;
            INTEL) printf "编译器/运行库: Intel 编译器，建议 OpenMP/TBB/MKL" ;;
            KIM) printf "第三方库: KIM API v2；可选 libcurl/Python/kim-property" ;;
            KOKKOS) printf "附带/外部库: Kokkos；GPU 后端需 CUDA/HIP/SYCL，本脚本用 CUDA/CUFFT" ;;
            KSPACE) printf "可选第三方 FFT: FFTW3/MKL/NVPL/heFFTe；可回退 KISSFFT" ;;
            LATBOLTZ) printf "构建要求: 必须启用 MPI 并行" ;;
            LATTE) printf "第三方程序/库: LATTE 紧束缚代码" ;;
            MACHDYN) printf "第三方头文件库: Eigen3" ;;
            MDI) printf "第三方库: MDI Library；CMake 可下载" ;;
            ML-HDNNP) printf "第三方库: n2p2；Kokkos GPU 下载构建会自动剔除" ;;
            ML-IAP) printf "依赖 package: ML-SNAP；Python 模型还需 PYTHON 和 cythonize" ;;
            ML-PACE) printf "第三方库: libpace；CMake 可下载" ;;
            ML-QUIP) printf "第三方库: QUIP/libAtoms；还需 Fortran 和 BLAS/LAPACK" ;;
            MOLFILE) printf "运行时/系统库: VMD molfile plugins；链接 libdl" ;;
            MPIIO) printf "依赖 MPI-IO 支持的 MPI 库" ;;
            MSCG) printf "第三方库: MSCG/OpenMSCG (mscg.h/libmscg)" ;;
            NETCDF) printf "第三方库: NetCDF；MPI 构建可用 PNetCDF" ;;
            OPENMP) printf "编译器运行库: OpenMP 支持" ;;
            OPT) printf "编译参数: Intel 编译器建议 -restrict" ;;
            PHONON) printf "构建要求: FFT 支持" ;;
            PLUMED) printf "第三方库: PLUMED；静态链接还需 GSL/BLAS/LAPACK" ;;
            POEMS) printf "附带库: lib/poems" ;;
            PYTHON) printf "第三方库: Python 3 开发头文件和 libpython" ;;
            QMMM) printf "附带库: lib/qmmm；实际 QM/MM 还需 Quantum ESPRESSO 联合可执行文件" ;;
            SCAFACOS) printf "第三方库: ScaFaCoS；还需 GSL、MPI C/Fortran" ;;
            VORONOI) printf "第三方库: Voro++" ;;
            VTK) printf "第三方库: VTK" ;;
            *) printf "无已知第三方编译库依赖" ;;
        esac
        return 0
    fi

    case "$1" in
        ADIOS) printf "third-party library: ADIOS2; set ADIOS2_DIR or adios2-config, MPI mode must match" ;;
        ATC) printf "bundled library: lib/atc; also needs MANYBODY and BLAS/LAPACK or internal linalg" ;;
        AWPMD) printf "bundled library: lib/awpmd; also needs BLAS/LAPACK or internal linalg" ;;
        COLVARS) printf "bundled library: Colvars" ;;
        COMPRESS) printf "third-party library: zlib; optional libzstd >= 1.4" ;;
        ELECTRODE) printf "package dependency: KSPACE; also needs BLAS/LAPACK or internal linalg" ;;
        GPU) printf "third-party toolchain: CUDA/OpenCL/HIP; CUDA builds in this script need nvcc" ;;
        H5MD) printf "third-party library: HDF5 C library" ;;
        INTEL) printf "compiler/runtime: Intel compiler, OpenMP/TBB/MKL recommended" ;;
        KIM) printf "third-party library: KIM API v2; optional libcurl/Python/kim-property" ;;
        KOKKOS) printf "bundled/external library: Kokkos; GPU backends need CUDA/HIP/SYCL, this script uses CUDA/CUFFT" ;;
        KSPACE) printf "optional third-party FFT: FFTW3/MKL/NVPL/heFFTe; can fall back to KISSFFT" ;;
        LATBOLTZ) printf "build requirement: MPI parallel mode" ;;
        LATTE) printf "third-party program/library: LATTE tight-binding code" ;;
        MACHDYN) printf "third-party header library: Eigen3" ;;
        MDI) printf "third-party library: MDI Library; CMake can download it" ;;
        ML-HDNNP) printf "third-party library: n2p2; auto-removed for downloaded Kokkos GPU builds" ;;
        ML-IAP) printf "package dependency: ML-SNAP; Python models also need PYTHON and cythonize" ;;
        ML-PACE) printf "third-party library: libpace; CMake can download it" ;;
        ML-QUIP) printf "third-party library: QUIP/libAtoms; also needs Fortran and BLAS/LAPACK" ;;
        MOLFILE) printf "runtime/system library: VMD molfile plugins; links libdl" ;;
        MPIIO) printf "depends on an MPI library with MPI-IO support" ;;
        MSCG) printf "third-party library: MSCG/OpenMSCG (mscg.h/libmscg)" ;;
        NETCDF) printf "third-party library: NetCDF; MPI builds may use PNetCDF" ;;
        OPENMP) printf "compiler runtime: OpenMP support" ;;
        OPT) printf "compiler flags: Intel compiler benefits from -restrict" ;;
        PHONON) printf "build requirement: FFT support" ;;
        PLUMED) printf "third-party library: PLUMED; static linking also needs GSL/BLAS/LAPACK" ;;
        POEMS) printf "bundled library: lib/poems" ;;
        PYTHON) printf "third-party library: Python 3 development headers and libpython" ;;
        QMMM) printf "bundled library: lib/qmmm; real QM/MM also needs a Quantum ESPRESSO coupled executable" ;;
        SCAFACOS) printf "third-party library: ScaFaCoS; also needs GSL and MPI C/Fortran" ;;
        VORONOI) printf "third-party library: Voro++" ;;
        VTK) printf "third-party library: VTK" ;;
        *) printf "no known third-party build library" ;;
    esac
}

version_kokkos_precision_definitions() {
    case "${KOKKOS_PRECISION,,}" in
        single|float|1) printf "LMP_PRECISION=1 PREC_FORCE=1 PREC_ENERGY=1 PREC_POS=1 PREC_VELOCITIES=1\n" ;;
        mixed) printf "LMP_PRECISION=1 PREC_FORCE=1 PREC_ENERGY=2 PREC_POS=2 PREC_VELOCITIES=2\n" ;;
        double|2) printf "LMP_PRECISION=2 PREC_FORCE=2 PREC_ENERGY=2 PREC_POS=2 PREC_VELOCITIES=2\n" ;;
        *)
            if is_zh; then
                die "KOKKOS_PRECISION 必须是 single、mixed 或 double"
            else
                die "KOKKOS_PRECISION must be single, mixed, or double"
            fi
            ;;
    esac
}

version_kokkos_core_precision_label() {
    case "${KOKKOS_PRECISION,,}" in
        single|float|1) printf "single\n" ;;
        mixed) printf "mixed\n" ;;
        double|2) printf "double\n" ;;
        auto|"") printf "auto\n" ;;
        *) printf "%s\n" "$KOKKOS_PRECISION" ;;
    esac
}

version_default_kokkos_gpu_arch() {
    printf "AMPERE86\n"
}

version_normalize_kokkos_arch() {
    local arch="${1^^}"

    arch="${arch#KOKKOS_ARCH_}"
    arch="${arch#SM_}"
    arch="${arch#COMPUTE_}"
    arch="${arch//./}"

    case "$arch" in
        AUTO|"") printf "%s\n" "$(version_default_kokkos_gpu_arch)" ;;
        60) printf "PASCAL60\n" ;;
        61) printf "PASCAL61\n" ;;
        70) printf "VOLTA70\n" ;;
        72) printf "VOLTA72\n" ;;
        75) printf "TURING75\n" ;;
        80) printf "AMPERE80\n" ;;
        86) printf "AMPERE86\n" ;;
        *) printf "%s\n" "$arch" ;;
    esac
}

version_gpu_sm_arch() {
    local arch="${1,,}"

    arch="${arch#sm_}"
    arch="${arch#compute_}"
    arch="${arch#kokkos_arch_}"

    case "$arch" in
        auto|"") printf "sm_86\n" ;;
        pascal60|60) printf "sm_60\n" ;;
        pascal61|61) printf "sm_61\n" ;;
        volta70|70) printf "sm_70\n" ;;
        volta72|72) printf "sm_72\n" ;;
        turing75|75) printf "sm_75\n" ;;
        ampere80|80) printf "sm_80\n" ;;
        ampere86|86) printf "sm_86\n" ;;
        [0-9][0-9]|[0-9][0-9][0-9]) printf "sm_%s\n" "$arch" ;;
        *) printf "%s\n" "$arch" ;;
    esac
}

version_kokkos_gpu_arch_values() {
    printf "%s\n" \
        PASCAL60 \
        PASCAL61 \
        VOLTA70 \
        VOLTA72 \
        TURING75 \
        AMPERE80 \
        AMPERE86
}

version_kokkos_gpu_arch_label() {
    case "$(version_normalize_kokkos_arch "$1")" in
        PASCAL60) printf "Pascal sm_60\n" ;;
        PASCAL61) printf "Pascal sm_61\n" ;;
        VOLTA70) printf "Volta sm_70\n" ;;
        VOLTA72) printf "Volta sm_72\n" ;;
        TURING75) printf "Turing sm_75\n" ;;
        AMPERE80) printf "Ampere sm_80\n" ;;
        AMPERE86) printf "Ampere sm_86\n" ;;
        *) printf "%s\n" "$1" ;;
    esac
}

version_choose_package_options_interactive() {
    local kokkos_default

    if package_enabled KOKKOS; then
        if [[ "$KOKKOS_PRECISION" == "auto" ]]; then
            if [[ "${KSPACE_PRECISION,,}" == "double" && "$FFT_SINGLE" == "0" ]]; then
                kokkos_default="double"
            else
                kokkos_default="single"
            fi
        else
            kokkos_default="$KOKKOS_PRECISION"
        fi
        KOKKOS_PRECISION="$(choose_precision_interactive "KOKKOS/KSPACE FFT" "$kokkos_default" 1)"
        case "$KOKKOS_PRECISION" in
            double)
                KSPACE_PRECISION="double"
                FFT_SINGLE="0"
                ;;
            single|mixed)
                KSPACE_PRECISION="single"
                FFT_SINGLE="1"
                ;;
        esac
    elif package_enabled KSPACE; then
        KSPACE_PRECISION="$(choose_precision_interactive "KSPACE" "$KSPACE_PRECISION" 0)"
        if [[ "$KSPACE_PRECISION" == "double" ]]; then
            FFT_SINGLE="0"
        else
            FFT_SINGLE="1"
        fi
    fi

    if package_enabled GPU || [[ "$ENABLE_GPU_PACKAGE" == "1" ]]; then
        GPU_PREC="$(choose_precision_interactive "GPU package" "$GPU_PREC" 1)"
    fi

    if [[ "$ACC_TYPE" == "gpu" ]] || package_enabled KOKKOS || package_enabled GPU || [[ "$ENABLE_GPU_PACKAGE" == "1" ]]; then
        KOKKOS_GPU_ARCH="$(choose_gpu_arch_interactive)"
        SM_ARCH="$(gpu_sm_arch "$KOKKOS_GPU_ARCH")"
    fi
}

version_sync_precision_options() {
    case "${KOKKOS_PRECISION,,}" in
        double)
            if package_enabled KOKKOS; then
                KSPACE_PRECISION="double"
                FFT_SINGLE="0"
            fi
            ;;
        single|mixed)
            if package_enabled KOKKOS; then
                KSPACE_PRECISION="single"
                FFT_SINGLE="1"
            fi
            ;;
    esac

    if [[ "${KSPACE_PRECISION,,}" == "mixed" ]]; then
        KSPACE_PRECISION="single"
    fi

    if [[ -n "$USER_SET_KSPACE_PRECISION" && -z "$USER_SET_FFT_SINGLE" ]]; then
        case "${KSPACE_PRECISION,,}" in
            double) FFT_SINGLE="0" ;;
            single|float|1) FFT_SINGLE="1" ;;
        esac
    fi
}

version_lammps_make_template_path() {
    printf "%s\n" "${LMP_SRC}/src/MAKE/OPTIONS/Makefile.intel_cpu_intelmpi"
}

version_lammps_makefile_path() {
    printf "%s\n" "${LMP_SRC}/src/MAKE/OPTIONS/Makefile.intel_cpu"
}

version_lammps_make_target() {
    printf "intel_cpu\n"
}

version_lammps_make_binary_path() {
    printf "%s\n" "${LMP_SRC}/src/lmp_intel_cpu"
}

version_choose_external_package_paths() {
    if package_enabled VORONOI; then
        VORONOI_PATH="$(choose_external_path "voro++" "$VORONOI_PATH" "${HOME}/apps/libs/voro++-0.4.6")"
    fi

    if package_enabled MACHDYN; then
        EIGEN_PATH="$(choose_external_path "Eigen" "$EIGEN_PATH" "${HOME}/apps/libs/eigen-3.4.0")"
    fi
}

version_prepare_external_libraries() {
    if package_enabled VORONOI; then
        install_voronoi
    fi

    if package_enabled MACHDYN; then
        install_eigen
    fi

    prepare_kim_archive
}

version_add_cmake_package_args() {
    local -n cmake_args_ref=$1
    local mpi_cxx_path=$2
    local nvcc_wrapper kokkos_arch precision_define kokkos_precision_define cmake_cxx_flags
    local kokkos_host_path cuda_warning_flags filtered_cxx_flags

    if package_enabled KOKKOS; then
        nvcc_wrapper="${LMP_SRC}/lib/kokkos/bin/nvcc_wrapper"
        [[ -x "$nvcc_wrapper" ]] || { if is_zh; then die "找不到 Kokkos nvcc_wrapper: $nvcc_wrapper"; else die "Kokkos nvcc_wrapper not found: $nvcc_wrapper"; fi; }
        kokkos_arch="$(normalize_kokkos_arch "$KOKKOS_GPU_ARCH")"
        if [[ "$KOKKOS_PRECISION" == "double" ]]; then
            KSPACE_PRECISION="double"
            FFT_SINGLE="0"
        elif [[ "$KOKKOS_PRECISION" == "single" || "$KOKKOS_PRECISION" == "mixed" ]]; then
            KSPACE_PRECISION="single"
            FFT_SINGLE="1"
        fi
        precision_define="$(precision_definition)"
        kokkos_precision_define="$(kokkos_precision_definitions)"
        kokkos_host_path="${KOKKOS_HOST_COMPILER_PATH:-$(resolve_tool "$KOKKOS_HOST_COMPILER" "Kokkos host compiler")}"
        cmake_cxx_flags="-D${precision_define}"
        for precision_define in $kokkos_precision_define; do
            cmake_cxx_flags="${cmake_cxx_flags} -D${precision_define}"
        done
        if [[ -n "$INTEL_CXX_FLAGS" ]]; then
            filtered_cxx_flags="$(strip_optimization_flags "$INTEL_CXX_FLAGS")"
            [[ -n "$filtered_cxx_flags" ]] && cmake_cxx_flags="${cmake_cxx_flags} ${filtered_cxx_flags}"
        fi
        export NVCC_WRAPPER_DEFAULT_COMPILER="${NVCC_WRAPPER_DEFAULT_COMPILER:-$kokkos_host_path}"

        cmake_args_ref+=(
            "-D" "CMAKE_CXX_COMPILER=${nvcc_wrapper}"
            "-D" "MPI_CXX_COMPILER=${mpi_cxx_path}"
            "-D" "Kokkos_ENABLE_SERIAL=ON"
            "-D" "Kokkos_ENABLE_CUDA=ON"
            "-D" "Kokkos_ARCH_${kokkos_arch}=ON"
            "-D" "Kokkos_ENABLE_DEPRECATION_WARNINGS=OFF"
            "-D" "FFT_KOKKOS=CUFFT"
            "-D" "CMAKE_CXX_FLAGS=${cmake_cxx_flags}"
        )

        if truthy "$FFT_SINGLE"; then
            cmake_args_ref+=("-D" "FFT_SINGLE=ON")
        fi
    fi

    if [[ "$ENABLE_GPU_PACKAGE" == "1" ]] || package_enabled GPU; then
        cmake_args_ref+=(
            "-D" "PKG_GPU=ON"
            "-D" "GPU_API=cuda"
            "-D" "GPU_PREC=${GPU_PREC,,}"
            "-D" "GPU_ARCH=${SM_ARCH}"
            "-D" "CUDA_BUILD_MULTIARCH=OFF"
        )
    fi

    if truthy "$SUPPRESS_WARNINGS"; then
        cuda_warning_flags="-w -Xcompiler=-w"
        cmake_args_ref+=(
            "-D" "CMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON"
            "-D" "CMAKE_CUDA_FLAGS=${cuda_warning_flags}"
        )
    fi

    if package_enabled VORONOI; then
        cmake_args_ref+=(
            "-D" "VORO_INCLUDE_DIR=${VORONOI_PATH}/include/voro++"
            "-D" "VORO_LIBRARY=${VORONOI_PATH}/lib/libvoro++.a"
        )
    fi

    if package_enabled MACHDYN; then
        cmake_args_ref+=("-D" "Eigen3_INCLUDE_DIR=${EIGEN_PATH}")
    fi

    if package_enabled KIM; then
        cmake_args_ref+=(
            "-D" "KIM_URL=file://${KIM_API_ARCHIVE}"
            "-D" "KIM_MD5=${KIM_API_MD5}"
        )
    fi
}

version_configure_lammps_makefile() {
    local makefile=$1

    sed -i \
        -e "s@-xCORE-AVX2@-xHost@g" \
        -e "s@-std=c++11@-std=c++14 -no-ip @g" \
        -e "s@mpiicpc@mpiicc@g" \
        "$makefile"

    if ! grep -q -- "-diag-disable=10441" "$makefile"; then
        sed -i \
            -e "s@^CC =\\(.*\\)@CC =\\1 -diag-disable=10441@" \
            -e "s@^LINK =\\(.*\\)@LINK =\\1 -diag-disable=10441@" \
            "$makefile"
    fi

    if ! grep -q "^KOKKOS_DEVICES =" "$makefile"; then
        sed -i "/SHLIBFLAGS =/ a\\KOKKOS_DEVICES = OpenMP" "$makefile"
    fi
}

version_build_atc() {
    local atc_dir="${LMP_SRC}/lib/atc"

    [[ -d "$atc_dir" ]] || { if is_zh; then die "找不到 ATC package 目录: $atc_dir"; else die "ATC package directory not found: $atc_dir"; fi; }
    [[ -n "${I_MPI_ROOT:-}" ]] || { if is_zh; then die "加载 MPI module 后 I_MPI_ROOT 仍未设置"; else die "I_MPI_ROOT is not set after loading MPI module"; fi; }

    if is_zh; then
        log "编译 ATC 库"
    else
        log "Building ATC library"
    fi
    pushd "$atc_dir" >/dev/null
    cp "${I_MPI_ROOT}/include/"*.h ./
    sed -i "s@icc@icc -diag-disable=10441 -diag-disable=2196@g" Makefile.icc
    make -j "$ATC_JN" -f Makefile.icc
    popd >/dev/null
}

version_configure_gpu_package() {
    local gpu_dir="${LMP_SRC}/lib/gpu"

    [[ -d "$gpu_dir" ]] || { if is_zh; then die "找不到 GPU package 目录: $gpu_dir"; else die "GPU package directory not found: $gpu_dir"; fi; }

    if is_zh; then
        log "编译 GPU 库"
    else
        log "Building GPU library"
    fi
    pushd "$gpu_dir" >/dev/null
    sed -i \
        -e "s@/usr/local/cuda@${CUDA_ROOT}@g" \
        -e "s@sm_60@${SM_ARCH}@g" \
        -e "s@mpicxx@mpiicc@g" \
        -e "s@SINGLE_DOUBLE@SINGLE_SINGLE@g" \
        -e "s@mpiicc@mpiicc -std=c++11@g" \
        Makefile.linux
    make -j "$JN" -f Makefile.linux
    sed -i "s@/usr/local/cuda@${CUDA_ROOT}@g" Makefile.lammps
    popd >/dev/null
}

version_build_pace() {
    [[ -d "${LMP_SRC}/lib/pace" ]] || { if is_zh; then die "找不到 ML-PACE package 目录: ${LMP_SRC}/lib/pace"; else die "ML-PACE package directory not found: ${LMP_SRC}/lib/pace"; fi; }

    if is_zh; then
        log "编译 ML-PACE 库"
    else
        log "Building ML-PACE library"
    fi
    pushd "${LMP_SRC}/src" >/dev/null
    make lib-pace args="-b"
    popd >/dev/null
}

version_link_voronoi_package() {
    local voronoi_dir="${LMP_SRC}/lib/voronoi"

    [[ -d "$voronoi_dir" ]] || { if is_zh; then die "找不到 VORONOI package 目录: $voronoi_dir"; else die "VORONOI package directory not found: $voronoi_dir"; fi; }
    pushd "$voronoi_dir" >/dev/null
    rm -f includelink liblink
    ln -s "$VORONOI_PATH/include/voro++" includelink
    ln -s "$VORONOI_PATH/lib" liblink
    popd >/dev/null
}

version_link_machdyn_package() {
    local machdyn_dir="${LMP_SRC}/lib/machdyn"

    [[ -d "$machdyn_dir" ]] || { if is_zh; then die "找不到 MACHDYN package 目录: $machdyn_dir"; else die "MACHDYN package directory not found: $machdyn_dir"; fi; }
    pushd "$machdyn_dir" >/dev/null
    rm -f includelink
    ln -s "$EIGEN_PATH" includelink
    popd >/dev/null
}
