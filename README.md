# Build LAMMPS on ABHPC

[English](./README.md) | [中文](./README.zh-CN.md)

This repository provides Bash tooling for compiling [LAMMPS](https://www.lammps.org) on ABHPC with Intel compilers, Intel MPI, optional CUDA/Kokkos GPU acceleration, and reusable build configurations.

## Requirements

Run the script on an ABHPC login or build node with the site `module` command available. The default module lists are:

```text
CPU/Make: compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
GPU/CMake: cmake/3.28.1 cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
GPU runtime: cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
```

If the environment is already loaded, set `LOAD_MODULES=0`. If system BLAS/LAPACK packages are missing, install them before building:

```bash
yum install -y blas-devel lapack-devel
```

## Default Layout

By default all generated files are placed under the current user's `~/apps` tree:

```text
~/apps/
  lammps-<version>/          # LAMMPS binary, modulefile, examples, potentials
  libs/                      # third-party libraries such as voro++ and Eigen
  downloads/lammps/          # cached source archives
  build/lammps/              # temporary build trees
```

Edit `path.conf`, pass environment variables such as `APP_ROOT=/path/to/apps`, or change the install path during interactive setup.

## Quick Start

```bash
# Syntax check only
bash -n build-lmp.sh

# Validate configuration without downloading or compiling
./build-lmp.sh --check 22Jul2025_update4

# Interactive build
./build-lmp.sh 22Jul2025_update4

# Rebuild from a saved config
./build-lmp.sh -c lammps-build-22Jul2025_update4.conf

# Non-interactive example
INTERACTIVE=0 JN=20 ./build-lmp.sh 23Jun2022
```

The installed binary is written to `~/apps/lammps-<version>/bin/`, and the generated modulefile is written to `~/apps/lammps-<version>/modulefile`.

## Interactive Mode

Running `./build-lmp.sh` starts an interactive workflow:

1. Select language: Chinese or English.
2. Select the LAMMPS version.
3. Select packages with `Space`; use `Up/Down` to move, `Left/Right` to page, and `Enter` to confirm.
4. Configure precision, CUDA architecture, job count, install paths, proxy, and module lists.
5. Save a reusable config file unless `--no-save-config` is used.

Use `LMP_LANG=zh` or `LMP_LANG=en` to skip language selection. `MENU_TIMEOUT=15` controls the first menu timeout.

## Proxy and Modules

The default proxy mode is `USE_PROXY=auto`: the script sources `/lufs/apps/bin/tmpporxy.sh` when that file exists. Use `USE_PROXY=1` to require the proxy file, or `USE_PROXY=0` to disable it.

```bash
USE_PROXY=0 ./build-lmp.sh 22Jul2025_update4
USE_PROXY=1 PROXY_FILE=/lufs/apps/bin/tmpporxy.sh ./build-lmp.sh 22Jul2025_update4
```

The interactive mode shows the default build and runtime module lists before loading them, and lets the user override both lists. In non-interactive mode, override them with `MODULE_LIST`, `GPU_MODULE_LIST`, `RUNTIME_MODULE_LIST_OVERRIDE`, or `GPU_RUNTIME_MODULE_LIST`.

## GPU and Precision

For GPU builds, use `ACC_TYPE=gpu`. The script uses CMake and enables CUDA/Kokkos-related options for the selected LAMMPS version.

```bash
ACC_TYPE=gpu KOKKOS_GPU_ARCH=ADA89 SM_ARCH=sm_89 JN=20 ./build-lmp.sh 22Jul2025_update4
```

`KOKKOS_GPU_ARCH=auto` tries to detect the GPU with `nvidia-smi`; if no GPU is visible, it falls back to `AMPERE86`. You can also use values such as `AMPERE80`, `ADA89`, `HOPPER90`, or direct `SM_ARCH=sm_80`.

Common precision variables:

```text
KOKKOS_PRECISION=auto|single|mixed|double
KSPACE_PRECISION=single|double
GPU_PREC=single|mixed|double
FFT_SINGLE=0|1
```

## Reusable Config Files

Interactive runs write `lammps-build-<version>.conf` by default. Reuse it with:

```bash
./build-lmp.sh -c lammps-build-22Jul2025_update4.conf
```

Use `--config-output FILE` to choose the config path, or `--no-save-config` to disable saving.

## Useful Options

```text
JN=20                       build parallelism
ATC_JN=20                   ATC library parallelism
LMP_PATH=/path/to/install   install directory
INTERACTIVE=0               disable prompts
LOAD_MODULES=0              do not run module purge/load
KEEP_BUILD=1                keep build trees
SUPPRESS_WARNINGS=0         show compiler warnings
```

## Repository Layout

```text
build-lmp.sh                main build script
path.conf                   default paths and compiler settings
23Jun2022/                  release-specific package data
22Jul2025_update4/          release-specific package data and CMake defaults
```

When adding a LAMMPS version, create a new version directory with `package.list`, `package.sta`, and `packages.sh`. If that version needs custom CMake or package defaults, add `build.conf`.
