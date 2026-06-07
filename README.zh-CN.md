# 在 ABHPC 上编译 LAMMPS

[English](./README.md) | [中文](./README.zh-CN.md)

本仓库提供用于在 ABHPC 上自动编译 [LAMMPS](https://www.lammps.org) 的 Bash 脚本，默认使用 Intel 编译器、Intel MPI，并支持 CUDA/Kokkos GPU 加速和可复用配置文件。

## 环境要求

请在具备 ABHPC `module` 环境的登录节点或编译节点运行脚本。默认加载的 module 为：

```text
CPU/Make: compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
GPU/CMake: cmake/3.28.1 cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
GPU runtime: cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0
```

如果当前 shell 已经加载好编译环境，可设置 `LOAD_MODULES=0`。如果系统缺少 BLAS/LAPACK，请先安装：

```bash
yum install -y blas-devel lapack-devel
```

## 默认安装目录

默认情况下，脚本会把所有生成文件放在当前用户的 `~/apps` 目录下：

```text
~/apps/
  lammps-<version>/          # LAMMPS 可执行文件、modulefile、examples、potentials
  libs/                      # voro++、Eigen 等第三方库
  downloads/lammps/          # 源码压缩包缓存
  build/lammps/              # 临时构建目录
```

可以编辑 `path.conf`、通过环境变量覆盖，例如 `APP_ROOT=/path/to/apps`，也可以在交互模式中修改安装路径。

## 快速开始

```bash
# 只做语法检查
bash -n build-lmp.sh

# 只检查配置，不下载、不编译
./build-lmp.sh --check 22Jul2025_update4

# 交互式编译
./build-lmp.sh 22Jul2025_update4

# 使用已保存配置重复编译
./build-lmp.sh -c lammps-build-22Jul2025_update4.conf

# 非交互示例
INTERACTIVE=0 JN=20 ./build-lmp.sh 23Jun2022
```

编译完成后，可执行文件位于 `~/apps/lammps-<version>/bin/`，生成的 modulefile 位于 `~/apps/lammps-<version>/modulefile`。

## 交互模式

运行 `./build-lmp.sh` 会进入交互流程：

1. 选择语言：中文或英文。
2. 选择 LAMMPS 版本。
3. 用 `Space` 勾选 package，`Up/Down` 移动，`Left/Right` 翻页，`Enter` 确认。
4. 设置精度、CUDA 架构、编译核数、安装路径、代理和 module 列表。
5. 默认生成可复用配置文件；使用 `--no-save-config` 可关闭。

可用 `LMP_LANG=zh` 或 `LMP_LANG=en` 跳过语言选择。`MENU_TIMEOUT=15` 控制首个菜单超时时间。

## 代理与 Module

默认代理模式为 `USE_PROXY=auto`：如果 `/lufs/apps/bin/tmpporxy.sh` 存在，脚本会自动加载。设置 `USE_PROXY=1` 表示强制加载代理脚本，设置 `USE_PROXY=0` 表示不使用代理。

```bash
USE_PROXY=0 ./build-lmp.sh 22Jul2025_update4
USE_PROXY=1 PROXY_FILE=/lufs/apps/bin/tmpporxy.sh ./build-lmp.sh 22Jul2025_update4
```

交互模式会显示默认编译 module 和运行时 module，并允许用户修改。非交互模式下可通过 `MODULE_LIST`、`GPU_MODULE_LIST`、`RUNTIME_MODULE_LIST_OVERRIDE` 或 `GPU_RUNTIME_MODULE_LIST` 覆盖。

## GPU 与精度

GPU 编译使用 `ACC_TYPE=gpu`。脚本会切换到 CMake，并按对应 LAMMPS 版本启用 CUDA/Kokkos 相关参数。

```bash
ACC_TYPE=gpu KOKKOS_GPU_ARCH=ADA89 SM_ARCH=sm_89 JN=20 ./build-lmp.sh 22Jul2025_update4
```

`KOKKOS_GPU_ARCH=auto` 会优先通过 `nvidia-smi` 检测显卡；如果没有可见 GPU，则回退到 `AMPERE86`。也可以手动设置 `AMPERE80`、`ADA89`、`HOPPER90`，或直接设置 `SM_ARCH=sm_80`。

常用精度变量：

```text
KOKKOS_PRECISION=auto|single|mixed|double
KSPACE_PRECISION=single|double
GPU_PREC=single|mixed|double
FFT_SINGLE=0|1
```

## 可复用配置文件

交互模式默认写出 `lammps-build-<version>.conf`，可用下面命令重复构建：

```bash
./build-lmp.sh -c lammps-build-22Jul2025_update4.conf
```

使用 `--config-output FILE` 可指定配置文件路径；使用 `--no-save-config` 可禁止保存。

## 常用选项

```text
JN=20                       编译并行核数
ATC_JN=20                   ATC 库编译核数
LMP_PATH=/path/to/install   安装目录
INTERACTIVE=0               禁用交互
LOAD_MODULES=0              不自动加载 module
KEEP_BUILD=1                保留构建目录
SUPPRESS_WARNINGS=0         显示编译警告
```

## 仓库结构

```text
build-lmp.sh                主编译脚本
path.conf                   默认路径和编译参数
23Jun2022/                  版本相关 package 数据
22Jul2025_update4/          版本相关 package 数据和 CMake 默认值
```

新增 LAMMPS 版本时，请创建对应版本目录，并提供 `package.list`、`package.sta` 和 `packages.sh`。如果该版本需要额外 CMake 或 package 默认值，可增加 `build.conf`。
