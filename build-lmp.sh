#!/usr/bin/env bash
set -Eeuo pipefail

is_zh() {
    [[ "${SCRIPT_LANG:-en}" == "zh" ]]
}

die() {
    if is_zh; then
        echo "错误: $*" >&2
    else
        echo "Error: $*" >&2
    fi
    exit 1
}

log() {
    echo
    echo "==> $*"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/path.conf}"
WORK_DIR=""

USER_SET_ACC_TYPE="${ACC_TYPE+x}"
USER_SET_BUILD_SYSTEM="${BUILD_SYSTEM+x}"
USER_SET_CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS+x}"
USER_SET_ENABLE_GPU_PACKAGE="${ENABLE_GPU_PACKAGE+x}"
USER_SET_FFT_SINGLE="${FFT_SINGLE+x}"
USER_SET_GPU_RUNTIME_MODULE_LIST="${GPU_RUNTIME_MODULE_LIST+x}"
USER_SET_KSPACE_PRECISION="${KSPACE_PRECISION+x}"
USER_SET_LMP_PATH="${LMP_PATH+x}"
USER_SET_LMP_VERSION="${LMP_VERSION+x}"

# Defaults. Override them in path.conf or via the environment.
APP_ROOT="${APP_ROOT:-${HOME}/apps}"
SOFT_SERV="${SOFT_SERV:-http://118.123.172.217:40899}"
VORONOI_URL="${VORONOI_URL:-http://mx.yinhe596.cn:40899/files/voro++-0.4.6.tar.gz}"
EIGEN_URL="${EIGEN_URL:-http://mx.yinhe596.cn:40899/files/eigen-3.4.0.tar.bz2}"
KIM_API_URL="${KIM_API_URL:-https://s3.openkim.org/kim-api/kim-api-2.2.1.txz}"
KIM_API_MD5="${KIM_API_MD5:-ae1ddda2ef7017ea07934e519d023dca}"
PROXY_FILE="${PROXY_FILE:-/lufs/apps/bin/tmpporxy.sh}"
USE_PROXY="${USE_PROXY:-auto}"

if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

LIB_ROOT="${LIB_ROOT:-${APP_ROOT}/libs}"
LMP_ROOT="${LMP_ROOT:-${APP_ROOT}/lammps}"
LMP_VERSION="${LMP_VERSION:-}"
LMP_PATH="${LMP_PATH:-}"
BUILD_ROOT="${BUILD_ROOT:-${APP_ROOT}/build/lammps}"
DOWNLOAD_ROOT="${DOWNLOAD_ROOT:-${APP_ROOT}/downloads/lammps}"
VORONOI_PATH="${VORONOI_PATH:-${LIB_ROOT}/voro++-0.4.6}"
EIGEN_PATH="${EIGEN_PATH:-${LIB_ROOT}/eigen-3.4.0}"
KIM_API_ARCHIVE="${KIM_API_ARCHIVE:-${DOWNLOAD_ROOT}/kim-api-2.2.1.txz}"
VORONOI_CXX="${VORONOI_CXX:-icpc}"
VORONOI_CFLAG="${VORONOI_CFLAG:-O2 -xHost}"
C_COMPILER="${C_COMPILER:-icc}"
FORTRAN_COMPILER="${FORTRAN_COMPILER:-ifort}"
ACC_TYPE="${ACC_TYPE:-cpu}"
CUDA_ROOT="${CUDA_ROOT:-/opt/cuda-12.0}"
SM_ARCH="${SM_ARCH:-}"
BUILD_SYSTEM="${BUILD_SYSTEM:-auto}"
CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
CMAKE_EXTRA_ARGS="${CMAKE_EXTRA_ARGS:-}"
GPU_MODULE_LIST="${GPU_MODULE_LIST:-cmake/3.28.1 cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0}"
GPU_RUNTIME_MODULE_LIST="${GPU_RUNTIME_MODULE_LIST:-cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0}"
MPI_CXX_COMPILER="${MPI_CXX_COMPILER:-mpiicpc}"
KOKKOS_HOST_COMPILER="${KOKKOS_HOST_COMPILER:-mpiicpc}"
SUPPRESS_WARNINGS="${SUPPRESS_WARNINGS:-1}"
INTEL_DIAG_DISABLES="${INTEL_DIAG_DISABLES:-10441 2196 611 997 497 10006 10148 6843 6178 8291 810 268}"
ALLOW_ML_HDNNP_KOKKOS_GPU="${ALLOW_ML_HDNNP_KOKKOS_GPU:-0}"
INTEL_CXX_FLAGS="${INTEL_CXX_FLAGS:--xHost -no-ip}"
INTEL_C_FLAGS="${INTEL_C_FLAGS:-$INTEL_CXX_FLAGS}"
INTEL_FC_FLAGS="${INTEL_FC_FLAGS:-$INTEL_CXX_FLAGS}"
KOKKOS_GPU_ARCH="${KOKKOS_GPU_ARCH:-auto}"
KOKKOS_PRECISION="${KOKKOS_PRECISION:-auto}"
KSPACE_PRECISION="${KSPACE_PRECISION:-single}"
FFT_SINGLE="${FFT_SINGLE:-1}"
GPU_PREC="${GPU_PREC:-single}"
ENABLE_GPU_PACKAGE="${ENABLE_GPU_PACKAGE:-0}"
JN="${JN:-20}"
ATC_JN="${ATC_JN:-20}"
MENU_TIMEOUT="${MENU_TIMEOUT:-15}"
INTERACTIVE="${INTERACTIVE:-auto}"
LMP_LANG="${LMP_LANG:-auto}"
KEEP_BUILD="${KEEP_BUILD:-0}"
LOAD_MODULES="${LOAD_MODULES:-1}"
MODULE_LIST="${MODULE_LIST:-compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0}"
RUNTIME_MODULE_LIST_OVERRIDE="${RUNTIME_MODULE_LIST_OVERRIDE:-}"
SAVE_BUILD_CONFIG="${SAVE_BUILD_CONFIG:-auto}"
BUILD_CONFIG_OUTPUT="${BUILD_CONFIG_OUTPUT:-auto}"
WGET_CONNECT_TIMEOUT="${WGET_CONNECT_TIMEOUT:-20}"
WGET_READ_TIMEOUT="${WGET_READ_TIMEOUT:-120}"
WGET_TRIES="${WGET_TRIES:-2}"

LMP_VERSIONS=()
PACKAGE_NAMES=()
PACKAGE_SELECTED=()
PACKAGE_DEFAULT_SELECTED=()
YES_PACKAGES=()
REMOVED_PACKAGES=()
ACTIVE_MODULE_LIST=""
RUNTIME_MODULE_LIST=""
MPI_CXX_COMPILER_PATH=""
KOKKOS_HOST_COMPILER_PATH=""
C_COMPILER_PATH=""
FORTRAN_COMPILER_PATH=""
SCRIPT_LANG=""
BUILD_CONFIG_INPUT=""
CONFIG_OUTPUT_PATH=""
CONFIG_LOADED=0
VERSION_HOOK_FILE=""
TERMINAL_CURSOR_HIDDEN=0
PACKAGE_MENU_COLOR=0
PACKAGE_MENU_LAST_LINES=()

hide_terminal_cursor() {
    [[ -t 1 ]] || return 0
    [[ "$TERMINAL_CURSOR_HIDDEN" == "1" ]] && return 0
    printf "\033[?25l"
    TERMINAL_CURSOR_HIDDEN=1
}

show_terminal_cursor() {
    [[ "$TERMINAL_CURSOR_HIDDEN" == "1" ]] || return 0
    printf "\033[?25h"
    TERMINAL_CURSOR_HIDDEN=0
}

reset_package_menu_render_cache() {
    PACKAGE_MENU_LAST_LINES=()
}

setup_package_menu_color() {
    if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
        PACKAGE_MENU_COLOR=1
    else
        PACKAGE_MENU_COLOR=0
    fi
}

load_version_package_hooks() {
    VERSION_HOOK_FILE="${SCRIPT_DIR}/${LMP_VERSION}/packages.sh"
    if [[ -f "$VERSION_HOOK_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$VERSION_HOOK_FILE"
    fi
}

run_version_hook() {
    local hook=$1
    shift

    if declare -F "$hook" >/dev/null; then
        "$hook" "$@"
    fi
}

require_version_hook() {
    local hook=$1
    shift

    if declare -F "$hook" >/dev/null; then
        "$hook" "$@"
        return 0
    fi

    if is_zh; then
        die "版本 ${LMP_VERSION} 缺少 package hook: ${hook}"
    else
        die "LAMMPS ${LMP_VERSION} is missing package hook: ${hook}"
    fi
}

setup_language() {
    case "${LMP_LANG,,}" in
        zh|zh_cn|zh-cn|cn|chinese)
            SCRIPT_LANG="zh"
            ;;
        en|en_us|en-us|english)
            SCRIPT_LANG="en"
            ;;
        auto)
            case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
                zh*|ZH*) SCRIPT_LANG="zh" ;;
                *) SCRIPT_LANG="en" ;;
            esac
            ;;
        *)
            SCRIPT_LANG="en"
            die "LMP_LANG must be auto, zh, or en"
            ;;
    esac
}

setup_language

redraw_prompt_line() {
    local prompt=$1
    local value=$2
    local cursor=$3
    local right=$(( ${#value} - cursor ))

    printf "\r\033[K%s%s" "$prompt" "$value" >&2
    if ((right > 0)); then
        printf "\033[%dD" "$right" >&2
    fi
}

read_prompt_line_core() {
    local __result_var=$1
    local prompt=$2
    local timeout=${3:-}
    local line_value="" key rest cursor=0 start=$SECONDS elapsed remaining

    if [[ ! -t 0 ]]; then
        printf "%s" "$prompt" >&2
        if [[ -n "$timeout" ]]; then
            IFS= read -r -t "$timeout" line_value || return 1
        else
            IFS= read -r line_value || return 1
        fi
        printf -v "$__result_var" "%s" "$line_value"
        return 0
    fi

    redraw_prompt_line "$prompt" "$line_value" "$cursor"
    while true; do
        if [[ -n "$timeout" ]]; then
            elapsed=$((SECONDS - start))
            remaining=$((timeout - elapsed))
            if ((remaining <= 0)); then
                printf "\n" >&2
                return 1
            fi
            IFS= read -rsn1 -t "$remaining" key || { printf "\n" >&2; return 1; }
        else
            IFS= read -rsn1 key || return 1
        fi

        case "$key" in
            ""|$'\n'|$'\r')
                printf "\n" >&2
                break
                ;;
            $'\177'|$'\b')
                if ((cursor > 0)); then
                    line_value="${line_value:0:cursor-1}${line_value:cursor}"
                    cursor=$((cursor - 1))
                fi
                ;;
            $'\x1b')
                IFS= read -rsn1 -t 0.05 rest || rest=""
                if [[ "$rest" == "[" ]]; then
                    IFS= read -rsn1 -t 0.05 rest || rest=""
                    case "$rest" in
                        D)
                            ((cursor > 0)) && cursor=$((cursor - 1))
                            ;;
                        C)
                            ((cursor < ${#line_value})) && cursor=$((cursor + 1))
                            ;;
                        H)
                            cursor=0
                            ;;
                        F)
                            cursor=${#line_value}
                            ;;
                        1|7)
                            IFS= read -rsn1 -t 0.05 rest || true
                            cursor=0
                            ;;
                        4|8)
                            IFS= read -rsn1 -t 0.05 rest || true
                            cursor=${#line_value}
                            ;;
                        3)
                            IFS= read -rsn1 -t 0.05 rest || true
                            if ((cursor < ${#line_value})); then
                                line_value="${line_value:0:cursor}${line_value:cursor+1}"
                            elif ((cursor > 0)); then
                                line_value="${line_value:0:cursor-1}${line_value:cursor}"
                                cursor=$((cursor - 1))
                            fi
                            ;;
                    esac
                elif [[ "$rest" == "O" ]]; then
                    IFS= read -rsn1 -t 0.05 rest || rest=""
                    case "$rest" in
                        H) cursor=0 ;;
                        F) cursor=${#line_value} ;;
                    esac
                fi
                ;;
            *)
                line_value="${line_value:0:cursor}${key}${line_value:cursor}"
                cursor=$((cursor + ${#key}))
                ;;
        esac
        redraw_prompt_line "$prompt" "$line_value" "$cursor"
    done

    printf -v "$__result_var" "%s" "$line_value"
}

read_prompt_line() {
    read_prompt_line_core "$1" "$2"
}

read_prompt_line_timeout() {
    read_prompt_line_core "$1" "$3" "$2"
}

choose_language() {
    local choice

    interactive_enabled || return 0
    [[ "${LMP_LANG,,}" == "auto" ]] || return 0

    echo "Select language / 选择语言 [default: 中文]:"
    echo "  1) 中文"
    echo "  2) English"

    choice=""
    if ! read_prompt_line_timeout choice "$MENU_TIMEOUT" "Enter number / 输入编号 within ${MENU_TIMEOUT}s [1]: "; then
        echo
        choice="1"
    fi
    choice="${choice:-1}"

    case "$choice" in
        1)
            SCRIPT_LANG="zh"
            ;;
        2)
            SCRIPT_LANG="en"
            ;;
        *)
            SCRIPT_LANG="zh"
            die "无效的语言选择 / Invalid language selection: $choice"
            ;;
    esac
}

load_build_config() {
    local config_file=$1

    [[ -f "$config_file" ]] || { SCRIPT_LANG="en"; die "Build config file not found: $config_file"; }
    BUILD_CONFIG_INPUT="$config_file"
    CONFIG_LOADED=1
    # shellcheck source=/dev/null
    source "$config_file"
    USER_SET_ACC_TYPE=x
    USER_SET_BUILD_SYSTEM=x
    USER_SET_CMAKE_EXTRA_ARGS=x
    USER_SET_ENABLE_GPU_PACKAGE=x
    USER_SET_FFT_SINGLE=x
    USER_SET_GPU_RUNTIME_MODULE_LIST=x
    USER_SET_KSPACE_PRECISION=x
    USER_SET_LMP_PATH=x
    USER_SET_LMP_VERSION=x
    setup_language
}

cleanup() {
    local status=$?
    show_terminal_cursor
    if [[ $status -eq 0 && "$KEEP_BUILD" != "1" && -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    elif [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]]; then
        if is_zh; then
            echo "保留构建目录: $WORK_DIR"
        else
            echo "Build directory retained: $WORK_DIR"
        fi
    fi
}
trap cleanup EXIT

usage() {
    if is_zh; then
        cat <<EOF
用法: ./build-lmp.sh [LAMMPS_VERSION]
      ./build-lmp.sh --check [LAMMPS_VERSION]
      ./build-lmp.sh -c BUILD_CONFIG.conf

交互模式先选择语言；package 菜单用上下键移动、左右键翻页、空格勾选、回车确认。

选项:
  -c, --config FILE        读取可复用配置文件
      --config-output FILE 指定交互模式生成的配置文件
      --no-save-config     不生成可复用配置文件

示例:
  ./build-lmp.sh
  ./build-lmp.sh 22Jul2025_update4
  ./build-lmp.sh --check 22Jul2025_update4
  ./build-lmp.sh -c lammps-build-22Jul2025_update4.conf
  ./build-lmp.sh 23Jun2022
  ./build-lmp.sh --check 23Jun2022
  USE_PROXY=0 ./build-lmp.sh 23Jun2022
  INTERACTIVE=0 ./build-lmp.sh 22Jul2025_update4
  LMP_LANG=en ./build-lmp.sh --check 22Jul2025_update4
  ATC_JN=2 JN=20 ./build-lmp.sh 23Jun2022
  ACC_TYPE=gpu JN=20 ./build-lmp.sh 22Jul2025_update4
EOF
        return 0
    fi

    cat <<EOF
Usage: ./build-lmp.sh [LAMMPS_VERSION]
       ./build-lmp.sh --check [LAMMPS_VERSION]
       ./build-lmp.sh -c BUILD_CONFIG.conf

Interactive mode starts with language selection. The package menu uses Up/Down to move, Left/Right to page, Space to toggle, and Enter to confirm.

Options:
  -c, --config FILE        read a reusable build config
      --config-output FILE write the interactive config to FILE
      --no-save-config     do not write a reusable config

Examples:
  ./build-lmp.sh
  ./build-lmp.sh 22Jul2025_update4
  ./build-lmp.sh --check 22Jul2025_update4
  ./build-lmp.sh -c lammps-build-22Jul2025_update4.conf
  ./build-lmp.sh 23Jun2022
  ./build-lmp.sh --check 23Jun2022
  USE_PROXY=0 ./build-lmp.sh 23Jun2022
  INTERACTIVE=0 ./build-lmp.sh 22Jul2025_update4
  LMP_LANG=zh ./build-lmp.sh --check 22Jul2025_update4
  ATC_JN=2 JN=20 ./build-lmp.sh 23Jun2022
  ACC_TYPE=gpu JN=20 ./build-lmp.sh 22Jul2025_update4
EOF
}

require_command() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            if is_zh; then
                die "缺少必要命令: $cmd"
            else
                die "Required command not found: $cmd"
            fi
        fi
    done
}

resolve_tool() {
    local tool=$1
    local label=${2:-tool}
    local path

    if [[ "$tool" == */* ]]; then
        if [[ ! -x "$tool" ]]; then
            if is_zh; then
                die "${label} 不可执行: $tool"
            else
                die "${label} is not executable: $tool"
            fi
        fi
        printf "%s\n" "$tool"
        return 0
    fi

    path="$(command -v "$tool" 2>/dev/null || true)"
    if [[ -z "$path" ]]; then
        if is_zh; then
            die "PATH 中找不到 ${label}: $tool"
        else
            die "${label} not found in PATH: $tool"
        fi
    fi
    printf "%s\n" "$path"
}

discover_versions() {
    local package_file version_dir

    for package_file in "$SCRIPT_DIR"/*/package.sta; do
        [[ -f "$package_file" ]] || continue
        version_dir="$(basename "$(dirname "$package_file")")"
        LMP_VERSIONS+=("$version_dir")
    done

    if ((${#LMP_VERSIONS[@]} == 0)); then
        if is_zh; then
            die "未找到包含 package.sta 的 LAMMPS 版本目录"
        else
            die "No LAMMPS version directories with package.sta were found."
        fi
    fi
}

version_supported() {
    local version
    for version in "${LMP_VERSIONS[@]}"; do
        [[ "$version" == "$1" ]] && return 0
    done
    return 1
}

interactive_enabled() {
    case "${INTERACTIVE,,}" in
        1|true|yes|on) return 0 ;;
        0|false|no|off) return 1 ;;
        auto) [[ -t 0 && -t 1 ]] ;;
        *)
            if is_zh; then
                die "INTERACTIVE 必须是 auto、1 或 0"
            else
                die "INTERACTIVE must be auto, 1, or 0"
            fi
            ;;
    esac
}

choose_version() {
    local i choice

    if is_zh; then
        echo "选择要编译的 LAMMPS 版本 [默认: ${LMP_VERSIONS[0]}]:"
    else
        echo "Choose LAMMPS version to compile [default: ${LMP_VERSIONS[0]}]:"
    fi
    for i in "${!LMP_VERSIONS[@]}"; do
        printf "  %d) %s\n" "$((i + 1))" "${LMP_VERSIONS[$i]}"
    done

    choice=""
    if is_zh; then
        if ! read_prompt_line_timeout choice "$MENU_TIMEOUT" "请在 ${MENU_TIMEOUT} 秒内输入编号 [1]: "; then
            echo
            choice="1"
        fi
    elif ! read_prompt_line_timeout choice "$MENU_TIMEOUT" "Enter number within ${MENU_TIMEOUT}s [1]: "; then
        echo
        choice="1"
    fi
    choice="${choice:-1}"

    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#LMP_VERSIONS[@]})); then
        LMP_VERSION="${LMP_VERSIONS[$((choice - 1))]}"
    else
        if is_zh; then
            die "无效的 LAMMPS 版本选择: $choice"
        else
            die "Invalid LAMMPS version selection: $choice"
        fi
    fi
}

read_package_status() {
    local package_sta package_list missing pkg default_pkg selected
    local default_packages=()

    package_sta="${SCRIPT_DIR}/${LMP_VERSION}/package.sta"
    package_list="${SCRIPT_DIR}/${LMP_VERSION}/package.list"
    if [[ ! -f "$package_sta" ]]; then
        if is_zh; then
            die "缺少 package 状态文件: $package_sta"
        else
            die "Missing package status file: $package_sta"
        fi
    fi

    mapfile -t default_packages < <(awk 'toupper($1) == "YES" && NF >= 2 {print $2}' "$package_sta")
    if ((${#default_packages[@]} == 0)); then
        if is_zh; then
            die "$package_sta 中没有启用的 package"
        else
            die "No enabled packages found in $package_sta"
        fi
    fi

    if [[ -f "$package_list" ]]; then
        mapfile -t PACKAGE_NAMES < <(awk 'NF > 0 && $1 !~ /^#/ && $1 !~ /^(DEPEND|MAKE|STUBS)$/ {print $1}' "$package_list")
        missing="$(comm -23 <(printf "%s\n" "${default_packages[@]}" | sort -u) <(sort -u "$package_list") || true)"
        if [[ -n "$missing" ]]; then
            if is_zh; then
                die "package.sta 中存在 package.list 没有的名称: ${missing//$'\n'/, }"
            else
                die "package.sta contains names missing from package.list: ${missing//$'\n'/, }"
            fi
        fi
    else
        PACKAGE_NAMES=("${default_packages[@]}")
    fi

    PACKAGE_DEFAULT_SELECTED=()
    PACKAGE_SELECTED=()
    YES_PACKAGES=()

    for pkg in "${PACKAGE_NAMES[@]}"; do
        selected=0
        for default_pkg in "${default_packages[@]}"; do
            if [[ "$pkg" == "$default_pkg" ]]; then
                selected=1
                break
            fi
        done
        PACKAGE_DEFAULT_SELECTED+=("$selected")
        PACKAGE_SELECTED+=("$selected")
        [[ "$selected" == "1" ]] && YES_PACKAGES+=("$pkg")
    done
}

set_yes_packages_from_selection() {
    local i

    YES_PACKAGES=()
    for i in "${!PACKAGE_NAMES[@]}"; do
        [[ "${PACKAGE_SELECTED[$i]}" == "1" ]] && YES_PACKAGES+=("${PACKAGE_NAMES[$i]}")
    done

    if ((${#YES_PACKAGES[@]} == 0)); then
        if is_zh; then
            die "至少需要选择一个 LAMMPS package"
        else
            die "At least one LAMMPS package must be selected"
        fi
    fi
}

apply_config_packages() {
    local selected_list=${CONFIG_YES_PACKAGES:-${YES_PACKAGES_CONFIG:-}}
    local pkg wanted i found

    [[ -n "$selected_list" ]] || return 0

    for i in "${!PACKAGE_SELECTED[@]}"; do
        PACKAGE_SELECTED[$i]=0
    done

    for pkg in $selected_list; do
        found=0
        for i in "${!PACKAGE_NAMES[@]}"; do
            if [[ "${PACKAGE_NAMES[$i]}" == "$pkg" ]]; then
                PACKAGE_SELECTED[$i]=1
                found=1
                break
            fi
        done
        if [[ "$found" == "0" ]]; then
            if is_zh; then
                die "配置文件中包含当前版本不存在的 package: $pkg"
            else
                die "Config file contains package missing from this LAMMPS version: $pkg"
            fi
        fi
    done

    set_yes_packages_from_selection
}

package_description() {
    require_version_hook version_package_description "$1"
}

package_dependency_kind() {
    require_version_hook version_package_dependency_kind "$1"
}

package_dependency_marker_from_kind() {
    case "$1" in
        external)
            if is_zh; then printf "[外部]"; else printf "[ext]"; fi
            ;;
        extra)
            if is_zh; then printf "[额外]"; else printf "[extra]"; fi
            ;;
        *)
            if is_zh; then printf "[内置]"; else printf "[base]"; fi
            ;;
    esac
}

package_dependency_marker() {
    package_dependency_marker_from_kind "$(package_dependency_kind "$1")"
}

package_marker_color_enabled() {
    [[ "${PACKAGE_MENU_COLOR:-0}" == "1" ]] || return 1
    [[ -z "${NO_COLOR:-}" ]] || return 1
    [[ "${TERM:-}" != "dumb" ]] || return 1
}

package_marker_color_code() {
    case "$1" in
        external) printf "31" ;;
        extra) printf "33" ;;
        *) printf "32" ;;
    esac
}

colorize_package_marker_field() {
    local field=$1
    local kind=$2
    local marker label suffix color

    if ! package_marker_color_enabled; then
        printf "%s" "$field"
        return 0
    fi

    marker="${field%%]*}"
    marker="${marker}]"
    if [[ "$marker" != \[*\] ]]; then
        printf "%s" "$field"
        return 0
    fi

    label="${marker#\[}"
    label="${label%\]}"
    suffix="${field#"$marker"}"
    color="$(package_marker_color_code "$kind")"
    printf "[\033[%sm%s\033[39m]%s" "$color" "$label" "$suffix"
}

format_package_marker() {
    local kind=$1
    local width=${2:-0}
    local marker field

    marker="$(package_dependency_marker_from_kind "$kind")"
    if ((width > 0)); then
        field="$(printf "%-*s" "$width" "$marker")"
    else
        field="$marker"
    fi
    colorize_package_marker_field "$field" "$kind"
}

package_dependency() {
    require_version_hook version_package_dependency "$1"
}

fit_description() {
    local text=$1
    local width=$2

    if ((width <= 0)); then
        return 0
    fi

    if ((${#text} > width)); then
        if ((width > 3)); then
            printf "%s..." "${text:0:$((width - 3))}"
        else
            printf "%s" "${text:0:$width}"
        fi
    else
        printf "%s" "$text"
    fi
}

render_package_menu() {
    local current=$1
    local offset=$2
    local page_size=$3
    local total=${#PACKAGE_NAMES[@]}
    local end=$((offset + page_size))
    local i max_lines old_count line mark cursor default_mark selected_count=0
    local cols desc_width desc desc_text dep_kind dep_mark current_desc current_dep
    local base_mark extra_mark external_mark
    local lines=()

    if ((end > total)); then
        end=$total
    fi
    for i in "${!PACKAGE_SELECTED[@]}"; do
        if [[ "${PACKAGE_SELECTED[$i]}" == "1" ]]; then
            selected_count=$((selected_count + 1))
        fi
    done

    cols="$(tput cols 2>/dev/null || printf "100")"
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=100
    if is_zh; then
        desc_width=$(((cols - 47) / 2))
    else
        desc_width=$((cols - 47))
    fi
    if ((desc_width < 24)); then
        desc_width=0
    fi
    current_desc="$(package_description "${PACKAGE_NAMES[$current]}")"
    current_dep="$(package_dependency "${PACKAGE_NAMES[$current]}")"
    base_mark="$(format_package_marker base)"
    extra_mark="$(format_package_marker extra)"
    external_mark="$(format_package_marker external)"

    if is_zh; then
        lines+=("选择 ${LMP_VERSION} 要编译的 LAMMPS packages")
        lines+=("上下: 移动  左右: 翻页  空格: 勾选/取消  回车: 确认  a: 全选  n: 全不选  d: 默认  q: 退出")
        lines+=("默认勾选来自 ${LMP_VERSION}/package.sta。已选择: ${selected_count}/${total}")
        lines+=("")
        lines+=("${base_mark} 无已知第三方编译库  ${extra_mark} 有额外构建/运行要求  ${external_mark} 需要第三方库或工具链")
    else
        lines+=("Select LAMMPS packages for ${LMP_VERSION}")
        lines+=("Up/Down: move  Left/Right: page  Space: toggle  Enter: confirm  a: all  n: none  d: default  q: quit")
        lines+=("Default selections come from ${LMP_VERSION}/package.sta. Selected: ${selected_count}/${total}")
        lines+=("")
        lines+=("${base_mark} no known third-party build library  ${extra_mark} extra build/runtime requirements  ${external_mark} needs third-party library/toolchain")
    fi

    for ((i = offset; i < end; i++)); do
        [[ "${PACKAGE_SELECTED[$i]}" == "1" ]] && mark="[x]" || mark="[ ]"
        [[ "$i" -eq "$current" ]] && cursor=">" || cursor=" "
        [[ "${PACKAGE_DEFAULT_SELECTED[$i]}" == "1" ]] && default_mark="*" || default_mark=" "
        dep_kind="$(package_dependency_kind "${PACKAGE_NAMES[$i]}")"
        dep_mark="$(format_package_marker "$dep_kind" 8)"
        desc="$(package_description "${PACKAGE_NAMES[$i]}")"
        desc_text="$(fit_description "$desc" "$desc_width")"
        if ((desc_width > 0)); then
            lines+=("$(printf "%s %s %s %-24s %s %s" "$cursor" "$mark" "$default_mark" "${PACKAGE_NAMES[$i]}" "$dep_mark" "$desc_text")")
        else
            lines+=("$(printf "%s %s %s %-24s %s" "$cursor" "$mark" "$default_mark" "${PACKAGE_NAMES[$i]}" "$dep_mark")")
        fi
    done

    if is_zh; then
        lines+=("")
        lines+=("显示 $((offset + 1))-${end} / ${total}。'*' 表示仓库默认 package 集合。")
        lines+=("说明: ${PACKAGE_NAMES[$current]} - ${current_desc}")
        lines+=("依赖: ${current_dep}")
    else
        lines+=("")
        lines+=("Showing $((offset + 1))-${end} of ${total}. '*' marks the repository default package set.")
        lines+=("Info: ${PACKAGE_NAMES[$current]} - ${current_desc}")
        lines+=("Deps: ${current_dep}")
    fi

    if ((${#PACKAGE_MENU_LAST_LINES[@]} == 0)); then
        printf "\033[H"
        for i in "${!lines[@]}"; do
            printf "\033[K%s" "${lines[$i]}"
            if ((i < ${#lines[@]} - 1)); then
                printf "\n"
            fi
        done
        printf "\033[J"
    else
        old_count=${#PACKAGE_MENU_LAST_LINES[@]}
        max_lines=${#lines[@]}
        if ((old_count > max_lines)); then
            max_lines=$old_count
        fi
        for ((i = 0; i < max_lines; i++)); do
            line="${lines[$i]:-}"
            if ((i >= old_count)) || [[ "${PACKAGE_MENU_LAST_LINES[$i]}" != "$line" ]]; then
                printf "\033[%d;1H\033[K%s" "$((i + 1))" "$line"
            fi
        done
    fi
    PACKAGE_MENU_LAST_LINES=("${lines[@]}")
}

choose_packages_interactive() {
    local total=${#PACKAGE_NAMES[@]}
    local current=0 offset=0 page_size rows key rest i

    if ((total == 0)); then
        if is_zh; then
            die "${LMP_VERSION} 没有可用 package"
        else
            die "No packages are available for ${LMP_VERSION}"
        fi
    fi
    rows="$(tput lines 2>/dev/null || printf "24")"
    [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
    page_size=$((rows - 9))
    if ((page_size < 8)); then
        page_size=8
    fi

    hide_terminal_cursor
    setup_package_menu_color
    printf "\033[H\033[J"
    reset_package_menu_render_cache
    while true; do
        render_package_menu "$current" "$offset" "$page_size"

        if ! IFS= read -rsn1 key; then
            if is_zh; then
                die "package 选择被中断"
            else
                die "Package selection was interrupted"
            fi
        fi
        case "$key" in
            "")
                break
                ;;
            " ")
                if [[ "${PACKAGE_SELECTED[$current]}" == "1" ]]; then
                    PACKAGE_SELECTED[$current]=0
                else
                    PACKAGE_SELECTED[$current]=1
                fi
                ;;
            a|A)
                for i in "${!PACKAGE_SELECTED[@]}"; do
                    PACKAGE_SELECTED[$i]=1
                done
                ;;
            n|N)
                for i in "${!PACKAGE_SELECTED[@]}"; do
                    PACKAGE_SELECTED[$i]=0
                done
                ;;
            d|D)
                PACKAGE_SELECTED=("${PACKAGE_DEFAULT_SELECTED[@]}")
                ;;
            q|Q)
                if is_zh; then
                    die "已取消 package 选择"
                else
                    die "Package selection cancelled"
                fi
                ;;
            $'\x1b')
                IFS= read -rsn2 -t 0.1 rest || rest=""
                case "$rest" in
                    "[A")
                        if ((current > 0)); then
                            current=$((current - 1))
                        fi
                        ;;
                    "[B")
                        if ((current < total - 1)); then
                            current=$((current + 1))
                        fi
                        ;;
                    "[D")
                        offset=$((offset - page_size))
                        if ((offset < 0)); then
                            offset=0
                        fi
                        current=$offset
                        ;;
                    "[C")
                        offset=$((offset + page_size))
                        if ((offset >= total)); then
                            offset=$((total - page_size))
                        fi
                        if ((offset < 0)); then
                            offset=0
                        fi
                        current=$offset
                        ;;
                    "[5")
                        offset=$((offset - page_size))
                        if ((offset < 0)); then
                            offset=0
                        fi
                        current=$offset
                        IFS= read -rsn1 -t 0.1 rest || true
                        ;;
                    "[6")
                        offset=$((offset + page_size))
                        if ((offset >= total)); then
                            offset=$((total - page_size))
                        fi
                        if ((offset < 0)); then
                            offset=0
                        fi
                        current=$offset
                        IFS= read -rsn1 -t 0.1 rest || true
                        ;;
                esac
                ;;
        esac

        if ((current < offset)); then
            offset=$current
        elif ((current >= offset + page_size)); then
            offset=$((current - page_size + 1))
        fi
    done

    set_yes_packages_from_selection
    printf "\033[H\033[J"
    reset_package_menu_render_cache
    PACKAGE_MENU_COLOR=0
    show_terminal_cursor
}

read_version_config() {
    local version_config="${SCRIPT_DIR}/${LMP_VERSION}/build.conf"

    DEFAULT_ACC_TYPE=""
    DEFAULT_BUILD_SYSTEM=""
    DEFAULT_CMAKE_EXTRA_ARGS=""
    DEFAULT_ENABLE_GPU_PACKAGE=""
    DEFAULT_FFT_SINGLE=""
    DEFAULT_KSPACE_PRECISION=""
    DEFAULT_RUNTIME_MODULE_LIST=""

    if [[ -f "$version_config" ]]; then
        # shellcheck source=/dev/null
        source "$version_config"
    fi

    if [[ -z "$USER_SET_ACC_TYPE" && -n "$DEFAULT_ACC_TYPE" ]]; then
        ACC_TYPE="$DEFAULT_ACC_TYPE"
    fi

    if [[ -z "$USER_SET_BUILD_SYSTEM" && -n "$DEFAULT_BUILD_SYSTEM" ]]; then
        BUILD_SYSTEM="$DEFAULT_BUILD_SYSTEM"
    fi

    if [[ -z "$USER_SET_CMAKE_EXTRA_ARGS" && -n "$DEFAULT_CMAKE_EXTRA_ARGS" ]]; then
        CMAKE_EXTRA_ARGS="$DEFAULT_CMAKE_EXTRA_ARGS"
    fi

    if [[ -z "$USER_SET_ENABLE_GPU_PACKAGE" && -n "$DEFAULT_ENABLE_GPU_PACKAGE" ]]; then
        ENABLE_GPU_PACKAGE="$DEFAULT_ENABLE_GPU_PACKAGE"
    fi

    if [[ -z "$USER_SET_FFT_SINGLE" && -n "$DEFAULT_FFT_SINGLE" ]]; then
        FFT_SINGLE="$DEFAULT_FFT_SINGLE"
    fi

    if [[ -z "$USER_SET_KSPACE_PRECISION" && -n "$DEFAULT_KSPACE_PRECISION" ]]; then
        KSPACE_PRECISION="$DEFAULT_KSPACE_PRECISION"
    fi

    if [[ -z "$USER_SET_GPU_RUNTIME_MODULE_LIST" && -n "$DEFAULT_RUNTIME_MODULE_LIST" ]]; then
        GPU_RUNTIME_MODULE_LIST="$DEFAULT_RUNTIME_MODULE_LIST"
    fi
}

package_enabled() {
    local pkg
    for pkg in "${YES_PACKAGES[@]}"; do
        [[ "$pkg" == "$1" ]] && return 0
    done
    return 1
}

remove_selected_package() {
    local pkg=$1
    local reason=$2
    local i kept=()

    package_enabled "$pkg" || return 0

    for i in "${!PACKAGE_NAMES[@]}"; do
        if [[ "${PACKAGE_NAMES[$i]}" == "$pkg" ]]; then
            PACKAGE_SELECTED[$i]=0
            break
        fi
    done

    for i in "${YES_PACKAGES[@]}"; do
        [[ "$i" == "$pkg" ]] && continue
        kept+=("$i")
    done
    YES_PACKAGES=("${kept[@]}")
    REMOVED_PACKAGES+=("${pkg}: ${reason}")
}

prune_incompatible_packages() {
    REMOVED_PACKAGES=()
    run_version_hook version_prune_incompatible_packages
}

print_removed_package_summary() {
    local item

    ((${#REMOVED_PACKAGES[@]} > 0)) || return 0

    if is_zh; then
        log "已剔除不兼容 package"
    else
        log "Removed incompatible packages"
    fi

    for item in "${REMOVED_PACKAGES[@]}"; do
        printf "  %s\n" "$item"
    done
}

print_selected_dependency_summary() {
    local pkg kind printed=0

    for pkg in "${YES_PACKAGES[@]}"; do
        kind="$(package_dependency_kind "$pkg")"
        [[ "$kind" == "builtin" ]] && continue

        if ((printed == 0)); then
            if is_zh; then
                log "已选 package 依赖提示"
            else
                log "Selected package dependency notes"
            fi
            printed=1
        fi

        printf "  %-12s %-8s %s\n" "$pkg" "$(package_dependency_marker "$pkg")" "$(package_dependency "$pkg")"
    done
}

resolve_build_system() {
    case "$BUILD_SYSTEM" in
        auto)
            if package_enabled KOKKOS; then
                BUILD_SYSTEM="cmake"
            else
                BUILD_SYSTEM="make"
            fi
            ;;
        make|cmake) ;;
        *)
            if is_zh; then
                die "BUILD_SYSTEM 必须是 auto、make 或 cmake"
            else
                die "BUILD_SYSTEM must be one of: auto, make, cmake"
            fi
            ;;
    esac
}

detect_cuda_compute_capability() {
    local nvidia_smi cc

    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia_smi="$(command -v nvidia-smi)"
    elif [[ -x /usr/bin/nvidia-smi ]]; then
        nvidia_smi="/usr/bin/nvidia-smi"
    else
        return 1
    fi

    cc="$("$nvidia_smi" --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | sed -n '/^[[:space:]]*[0-9][0-9]*\(\.[0-9][0-9]*\)\?[[:space:]]*$/ { s/[[:space:]]//g; p; q; }')"
    [[ -n "$cc" ]] || return 1
    printf "%s\n" "$cc"
}

default_kokkos_gpu_arch() {
    local cc

    if cc="$(detect_cuda_compute_capability)"; then
        normalize_kokkos_arch "$cc"
    else
        normalize_kokkos_arch "$(kokkos_default_gpu_arch)"
    fi
}

kokkos_default_gpu_arch() {
    require_version_hook version_default_kokkos_gpu_arch
}

normalize_kokkos_arch() {
    require_version_hook version_normalize_kokkos_arch "$1"
}

gpu_sm_arch() {
    require_version_hook version_gpu_sm_arch "$1"
}

kokkos_gpu_arch_values() {
    require_version_hook version_kokkos_gpu_arch_values
}

kokkos_gpu_arch_label() {
    require_version_hook version_kokkos_gpu_arch_label "$1"
}

normalize_precision_choice() {
    local value="${1,,}"

    case "$value" in
        1|single|float)
            printf "single\n"
            ;;
        2|mixed)
            printf "mixed\n"
            ;;
        3|double)
            printf "double\n"
            ;;
        *)
            return 1
            ;;
    esac
}

precision_definition() {
    case "${KSPACE_PRECISION,,}" in
        single|float|1) printf "PREC_KSPACE=1\n" ;;
        mixed) printf "PREC_KSPACE=1\n" ;;
        double|2) printf "PREC_KSPACE=2\n" ;;
        *)
            if is_zh; then
                die "KSPACE_PRECISION 必须是 single、mixed 或 double"
            else
                die "KSPACE_PRECISION must be single, mixed, or double"
            fi
            ;;
    esac
}

kokkos_precision_definitions() {
    require_version_hook version_kokkos_precision_definitions
}

kokkos_core_precision_label() {
    require_version_hook version_kokkos_core_precision_label
}

truthy() {
    case "${1,,}" in
        1|true|yes|on|是|需要|启用|加载) return 0 ;;
        *) return 1 ;;
    esac
}

yes_no_label() {
    if truthy "${1:-0}"; then
        if is_zh; then printf "是\n"; else printf "yes\n"; fi
    else
        if is_zh; then printf "否\n"; else printf "no\n"; fi
    fi
}

normalize_yes_no_choice() {
    case "${1,,}" in
        1|y|yes|true|on|是|需要|启用|加载)
            printf "1\n"
            ;;
        0|2|n|no|false|off|否|不需要|禁用|不加载)
            printf "0\n"
            ;;
        *)
            return 1
            ;;
    esac
}

proxy_mode_label() {
    case "${1,,}" in
        auto)
            printf "auto\n"
            ;;
        1|true|yes|on)
            if is_zh; then printf "需要\n"; else printf "yes\n"; fi
            ;;
        0|false|no|off)
            if is_zh; then printf "不需要\n"; else printf "no\n"; fi
            ;;
        *)
            printf "%s\n" "$1"
            ;;
    esac
}

normalize_proxy_mode_choice() {
    case "${1,,}" in
        auto|a|自动)
            printf "auto\n"
            ;;
        1|yes|y|true|on|需要|启用|加载)
            printf "1\n"
            ;;
        0|no|n|false|off|不需要|禁用|不加载)
            printf "0\n"
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_proxy_menu_choice() {
    case "${1,,}" in
        1|auto|a|自动)
            printf "auto\n"
            ;;
        2|yes|y|true|on|需要|启用|加载)
            printf "1\n"
            ;;
        0|3|no|n|false|off|不需要|禁用|不加载)
            printf "0\n"
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_space_list() {
    local value=$1
    local words=()

    # shellcheck disable=SC2206
    words=($value)
    printf "%s\n" "${words[*]}"
}

prompt_path() {
    local label=$1
    local default_value=$2
    local value

    read_prompt_line value "${label} [${default_value}]: "
    value="${value:-$default_value}"
    printf "%s\n" "$value"
}

prompt_choice() {
    local label=$1
    local default_value=$2
    local value

    read_prompt_line value "${label} [${default_value}]: "
    value="${value:-$default_value}"
    printf "%s\n" "$value"
}

prompt_positive_integer() {
    local label=$1
    local default_value=$2
    local value

    while true; do
        value="$(prompt_choice "$label" "$default_value")"
        if [[ "$value" =~ ^[0-9]+$ && "$value" -gt 0 ]]; then
            printf "%s\n" "$value"
            return 0
        fi

        if is_zh; then
            echo "请输入正整数: $value" >&2
        else
            echo "Enter a positive integer: $value" >&2
        fi
    done
}

choose_yes_no_interactive() {
    local label=$1
    local current_value=$2
    local choice normalized

    if is_zh; then
        echo "$label:" >&2
        echo "  1) 是" >&2
        echo "  2) 否" >&2
        choice="$(prompt_choice "请输入编号或 yes/no" "$(yes_no_label "$current_value")")"
    else
        echo "$label:" >&2
        echo "  1) yes" >&2
        echo "  2) no" >&2
        choice="$(prompt_choice "Enter number or yes/no" "$(yes_no_label "$current_value")")"
    fi

    normalized="$(normalize_yes_no_choice "$choice" 2>/dev/null || true)"
    if [[ -z "$normalized" ]]; then
        if is_zh; then
            die "无效的是/否选择: $choice"
        else
            die "Invalid yes/no choice: $choice"
        fi
    fi

    printf "%s\n" "$normalized"
}

choose_proxy_interactive() {
    local current_mode choice normalized

    current_mode="$(proxy_mode_label "$USE_PROXY")"
    if is_zh; then
        echo "代理设置:" >&2
        echo "  默认代理脚本: $PROXY_FILE" >&2
        echo "  1) auto  代理脚本存在时自动加载" >&2
        echo "  2) 是    强制加载代理脚本，不存在则报错" >&2
        echo "  3) 否    不加载代理" >&2
        choice="$(prompt_choice "是否需要代理，输入编号或名称" "$current_mode")"
    else
        echo "Proxy settings:" >&2
        echo "  Default proxy script: $PROXY_FILE" >&2
        echo "  1) auto  load the proxy script when it exists" >&2
        echo "  2) yes   require the proxy script" >&2
        echo "  3) no    do not load a proxy" >&2
        choice="$(prompt_choice "Need a proxy? Enter number or name" "$current_mode")"
    fi

    normalized="$(normalize_proxy_menu_choice "$choice" 2>/dev/null || true)"
    if [[ -z "$normalized" ]]; then
        if is_zh; then
            die "无效的代理选择: $choice"
        else
            die "Invalid proxy choice: $choice"
        fi
    fi
    USE_PROXY="$normalized"

    if [[ "$USE_PROXY" != "0" ]]; then
        if is_zh; then
            PROXY_FILE="$(absolute_path "$(prompt_path "代理脚本路径" "$PROXY_FILE")")"
        else
            PROXY_FILE="$(absolute_path "$(prompt_path "Proxy script path" "$PROXY_FILE")")"
        fi
    fi
}

configure_proxy_and_modules_interactive() {
    local modules_enabled module_label runtime_label active_default runtime_default

    interactive_enabled || return 0

    choose_proxy_interactive

    modules_enabled="$(normalize_yes_no_choice "$LOAD_MODULES" 2>/dev/null || true)"
    if [[ -z "$modules_enabled" ]]; then
        modules_enabled=1
    fi

    if is_zh; then
        LOAD_MODULES="$(choose_yes_no_interactive "是否自动加载编译 module" "$modules_enabled")"
    else
        LOAD_MODULES="$(choose_yes_no_interactive "Automatically load build modules?" "$modules_enabled")"
    fi

    [[ "$LOAD_MODULES" == "1" ]] || return 0

    active_default="$ACTIVE_MODULE_LIST"
    runtime_default="$RUNTIME_MODULE_LIST"

    if is_zh; then
        case "$BUILD_SYSTEM:$ACC_TYPE" in
            cmake:gpu)
                module_label="GPU/CMake 编译 module 列表"
                runtime_label="GPU 运行时 module 列表"
                ;;
            *)
                module_label="CPU/Make 编译 module 列表"
                runtime_label="CPU 运行时 module 列表"
                ;;
        esac
        echo "默认编译 module: $active_default" >&2
        echo "默认运行 module: $runtime_default" >&2
        ACTIVE_MODULE_LIST="$(normalize_space_list "$(prompt_choice "$module_label" "$active_default")")"
        RUNTIME_MODULE_LIST="$(normalize_space_list "$(prompt_choice "$runtime_label" "$runtime_default")")"
    else
        case "$BUILD_SYSTEM:$ACC_TYPE" in
            cmake:gpu)
                module_label="GPU/CMake build module list"
                runtime_label="GPU runtime module list"
                ;;
            *)
                module_label="CPU/Make build module list"
                runtime_label="CPU runtime module list"
                ;;
        esac
        echo "Default build modules: $active_default" >&2
        echo "Default runtime modules: $runtime_default" >&2
        ACTIVE_MODULE_LIST="$(normalize_space_list "$(prompt_choice "$module_label" "$active_default")")"
        RUNTIME_MODULE_LIST="$(normalize_space_list "$(prompt_choice "$runtime_label" "$runtime_default")")"
    fi

    case "$BUILD_SYSTEM:$ACC_TYPE" in
        cmake:gpu)
            GPU_MODULE_LIST="$ACTIVE_MODULE_LIST"
            GPU_RUNTIME_MODULE_LIST="$RUNTIME_MODULE_LIST"
            ;;
        *)
            MODULE_LIST="$ACTIVE_MODULE_LIST"
            RUNTIME_MODULE_LIST_OVERRIDE="$RUNTIME_MODULE_LIST"
            ;;
    esac
}

choose_gpu_arch_interactive() {
    local current_arch sm_current choice custom arch
    local arch_values=()
    local arch_labels=()

    mapfile -t arch_values < <(kokkos_gpu_arch_values)
    for arch in "${arch_values[@]}"; do
        arch_labels+=("$(kokkos_gpu_arch_label "$arch")")
    done
    arch_values+=("custom")
    arch_labels+=("custom/manual")

    if [[ -n "$SM_ARCH" && "${SM_ARCH,,}" != "auto" ]]; then
        current_arch="$(normalize_kokkos_arch "$SM_ARCH")"
    elif [[ -z "$KOKKOS_GPU_ARCH" || "${KOKKOS_GPU_ARCH,,}" == "auto" ]]; then
        current_arch="$(default_kokkos_gpu_arch)"
    else
        current_arch="$(normalize_kokkos_arch "$KOKKOS_GPU_ARCH")"
    fi
    sm_current="$(gpu_sm_arch "$current_arch")"

    if is_zh; then
        echo "CUDA GPU 架构选项:" >&2
    else
        echo "CUDA GPU architecture options:" >&2
    fi
    for choice in "${!arch_values[@]}"; do
        if [[ "${arch_values[$choice]}" == "custom" ]]; then
            printf "  %2d) %s\n" "$((choice + 1))" "${arch_labels[$choice]}" >&2
        else
            printf "  %2d) %-12s %s\n" "$((choice + 1))" "${arch_values[$choice]}" "${arch_labels[$choice]}" >&2
        fi
    done

    if is_zh; then
        choice="$(prompt_choice "请选择 CUDA GPU 架构编号或直接输入架构名/sm 值" "${current_arch} (${sm_current})")"
    else
        choice="$(prompt_choice "Select CUDA GPU architecture by number or enter an arch/sm value" "${current_arch} (${sm_current})")"
    fi

    case "$choice" in
        *" ("*) choice="${choice%% (*}" ;;
    esac

    if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#arch_values[@]} ]]; then
        arch="${arch_values[$((choice - 1))]}"
    else
        arch="$choice"
    fi

    if [[ "$arch" == "custom" ]]; then
        if is_zh; then
            custom="$(prompt_choice "输入 Kokkos 架构名或 CUDA SM 值，例如 AMPERE80、sm_80、80" "$current_arch")"
        else
            custom="$(prompt_choice "Enter Kokkos arch or CUDA SM value, e.g. AMPERE80, sm_80, 80" "$current_arch")"
        fi
        arch="$custom"
    fi

    normalize_kokkos_arch "$arch"
}

lammps_make_template_path() {
    require_version_hook version_lammps_make_template_path
}

lammps_makefile_path() {
    require_version_hook version_lammps_makefile_path
}

lammps_make_target() {
    require_version_hook version_lammps_make_target
}

lammps_make_binary_path() {
    require_version_hook version_lammps_make_binary_path
}

absolute_path() {
    local path=$1

    case "$path" in
        "~") printf "%s\n" "$HOME" ;;
        "~/"*) printf "%s/%s\n" "$HOME" "${path#~/}" ;;
        /*) printf "%s\n" "$path" ;;
        *) printf "%s/%s\n" "$PWD" "$path" ;;
    esac
}

path_parent_writable() {
    local path=$1
    local parent

    if [[ -e "$path" ]]; then
        [[ -d "$path" && -w "$path" ]]
        return $?
    fi

    parent="$(dirname "$path")"
    while [[ ! -e "$parent" && "$parent" != "/" ]]; do
        parent="$(dirname "$parent")"
    done

    [[ -d "$parent" && -w "$parent" ]]
}

external_library_present() {
    local name=$1
    local path=$2

    case "$name" in
        voro++)
            [[ -d "${path}/include/voro++" && -d "${path}/lib" ]]
            ;;
        Eigen)
            [[ -d "${path}/Eigen" ]]
            ;;
        *)
            [[ -d "$path" ]]
            ;;
    esac
}

choose_external_path() {
    local name=$1
    local current_path=$2
    local fallback_path=$3
    local chosen

    if is_zh; then
        chosen="$(prompt_path "${name} 安装路径" "$current_path")"
    else
        chosen="$(prompt_path "${name} install path" "$current_path")"
    fi
    chosen="$(absolute_path "$chosen")"
    fallback_path="$(absolute_path "$fallback_path")"

    if external_library_present "$name" "$chosen"; then
        printf "%s\n" "$chosen"
        return 0
    fi

    if path_parent_writable "$chosen"; then
        printf "%s\n" "$chosen"
        return 0
    fi

    if is_zh; then
        echo "${name} 路径不可写或无法创建: $chosen" >&2
        echo "改用默认路径: $fallback_path" >&2
    else
        echo "${name} path is not writable or cannot be created: $chosen" >&2
        echo "Falling back to: $fallback_path" >&2
    fi
    printf "%s\n" "$fallback_path"
}

choose_external_package_paths() {
    require_version_hook version_choose_external_package_paths
}

choose_precision_interactive() {
    local label=$1
    local current_value=$2
    local allow_mixed=${3:-1}
    local choice precision

    current_value="$(normalize_precision_choice "$current_value" 2>/dev/null || printf "single")"

    if is_zh; then
        echo "$label 精度选项:" >&2
        echo "  1) single  单精度，速度优先" >&2
        if [[ "$allow_mixed" == "1" ]]; then
            echo "  2) mixed   混合精度，兼顾精度和速度" >&2
            echo "  3) double  双精度，精度优先" >&2
        else
            echo "  2) double  双精度，精度优先" >&2
        fi
        choice="$(prompt_choice "请选择 $label 精度，输入编号或名称" "$current_value")"
    else
        echo "$label precision options:" >&2
        echo "  1) single  single precision, speed first" >&2
        if [[ "$allow_mixed" == "1" ]]; then
            echo "  2) mixed   mixed precision, balances accuracy and speed" >&2
            echo "  3) double  double precision, accuracy first" >&2
        else
            echo "  2) double  double precision, accuracy first" >&2
        fi
        choice="$(prompt_choice "Select $label precision by number or name" "$current_value")"
    fi

    if [[ "$allow_mixed" == "0" && "$choice" == "2" ]]; then
        choice="double"
    fi
    precision="$(normalize_precision_choice "$choice" 2>/dev/null || true)"
    if [[ "$allow_mixed" == "0" && "$precision" == "mixed" ]]; then
        precision=""
    fi
    if [[ -z "$precision" ]]; then
        if is_zh; then
            die "无效的 $label 精度选择: $choice"
        else
            die "Invalid $label precision selection: $choice"
        fi
    fi

    printf "%s\n" "$precision"
}

choose_package_options_interactive() {
    interactive_enabled || return 0
    require_version_hook version_choose_package_options_interactive
}

sync_precision_options() {
    require_version_hook version_sync_precision_options
}

append_flag_once() {
    local flags=$1
    local flag=$2

    if [[ " $flags " != *" $flag "* ]]; then
        flags="${flags} ${flag}"
    fi
    printf "%s\n" "${flags# }"
}

normalize_intel_flags() {
    local flags=$1 warning_flag

    flags="${flags//-xCORE-AVX2/-xHost}"
    flags="${flags//-XCORE-AVX2/-xHost}"
    for warning_flag in $(intel_warning_flags); do
        flags="$(append_flag_once "$flags" "$warning_flag")"
    done
    printf "%s\n" "$flags"
}

intel_warning_flags() {
    local flags="" diag

    truthy "$SUPPRESS_WARNINGS" || return 0
    flags="$(append_flag_once "$flags" "-w")"
    for diag in $INTEL_DIAG_DISABLES; do
        flags="$(append_flag_once "$flags" "-diag-disable=${diag}")"
    done
    printf "%s\n" "$flags"
}

strip_optimization_flags() {
    local flags=$1 flag
    local filtered=()

    # shellcheck disable=SC2206
    local parts=($flags)
    for flag in "${parts[@]}"; do
        case "$flag" in
            -O|-O[0-9]|-O[gsz]|-Ofast)
                continue
                ;;
        esac
        filtered+=("$flag")
    done
    printf "%s\n" "${filtered[*]}"
}

normalize_compiler_flags() {
    VORONOI_CFLAG="$(normalize_intel_flags "$VORONOI_CFLAG")"
    INTEL_CXX_FLAGS="$(normalize_intel_flags "$INTEL_CXX_FLAGS")"
    INTEL_C_FLAGS="$(normalize_intel_flags "$INTEL_C_FLAGS")"
    INTEL_FC_FLAGS="$(normalize_intel_flags "$INTEL_FC_FLAGS")"
}

append_env_flags() {
    local var_name=$1
    local flags=$2
    local current="${!var_name-}"
    local flag merged="$current"

    for flag in $flags; do
        merged="$(append_flag_once "$merged" "$flag")"
    done
    printf -v "$var_name" "%s" "$merged"
    export "$var_name"
}

export_compiler_warning_flags() {
    local warning_flags

    warning_flags="$(intel_warning_flags)"
    [[ -n "$warning_flags" ]] || return 0
    append_env_flags CFLAGS "$warning_flags"
    if [[ "$BUILD_SYSTEM" != "cmake" ]] || ! package_enabled KOKKOS; then
        append_env_flags CXXFLAGS "$warning_flags"
    fi
    append_env_flags FFLAGS "$warning_flags"
    append_env_flags FCFLAGS "$warning_flags"
    export GIT_DISCOVERY_ACROSS_FILESYSTEM="${GIT_DISCOVERY_ACROSS_FILESYSTEM:-1}"
}

write_compiler_wrapper() {
    local wrapper=$1
    local target=$2
    local flags=$3

    [[ -x "$target" ]] || return 0
    {
        printf '#!/usr/bin/env bash\n'
        printf 'set -e\n'
        printf 'target=%q\n' "$target"
        printf 'flags=%q\n' "$flags"
        printf '# shellcheck disable=SC2206\n'
        printf 'extra=($flags)\n'
        printf 'exec "$target" "${extra[@]}" "$@"\n'
    } >"$wrapper"
    chmod 755 "$wrapper"
}

create_compiler_wrappers() {
    local wrapper_dir target wrapper_flags

    truthy "$SUPPRESS_WARNINGS" || return 0

    wrapper_dir="${WORK_DIR}/compiler-wrappers"
    mkdir -p "$wrapper_dir"
    wrapper_flags="$(intel_warning_flags)"

    target="$(command -v icc 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/icc" "$target" "$wrapper_flags"
    target="$(command -v icpc 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/icpc" "$target" "$wrapper_flags"
    target="$(command -v ifort 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/ifort" "$target" "$wrapper_flags"
    target="$(command -v mpiicc 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/mpiicc" "$target" "$wrapper_flags"
    target="$(command -v mpiicpc 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/mpiicpc" "$target" "$wrapper_flags"
    target="$(command -v mpiifort 2>/dev/null || true)"
    write_compiler_wrapper "${wrapper_dir}/mpiifort" "$target" "$wrapper_flags"

    PATH="${wrapper_dir}:${PATH}"
    export PATH

    [[ -x "${wrapper_dir}/icc" ]] && C_COMPILER_PATH="${wrapper_dir}/icc"
    [[ -x "${wrapper_dir}/ifort" ]] && FORTRAN_COMPILER_PATH="${wrapper_dir}/ifort"
    [[ -x "${wrapper_dir}/icpc" ]] && VORONOI_CXX="${wrapper_dir}/icpc"
    if [[ "$BUILD_SYSTEM" != "cmake" ]] || ! package_enabled KOKKOS; then
        [[ -x "${wrapper_dir}/mpiicpc" ]] && MPI_CXX_COMPILER_PATH="${wrapper_dir}/mpiicpc"
        [[ -x "${wrapper_dir}/mpiicpc" ]] && KOKKOS_HOST_COMPILER_PATH="${wrapper_dir}/mpiicpc"
        [[ -x "${wrapper_dir}/icpc" ]] && export CUDAHOSTCXX="${wrapper_dir}/icpc"
    fi
}

normalize_gpu_arch_options() {
    local requested_kokkos="${KOKKOS_GPU_ARCH,,}"

    if [[ -n "$SM_ARCH" && ( -z "$requested_kokkos" || "$requested_kokkos" == "auto" ) ]]; then
        KOKKOS_GPU_ARCH="$(normalize_kokkos_arch "$SM_ARCH")"
    elif [[ -z "$requested_kokkos" || "$requested_kokkos" == "auto" ]]; then
        KOKKOS_GPU_ARCH="$(default_kokkos_gpu_arch)"
    else
        KOKKOS_GPU_ARCH="$(normalize_kokkos_arch "$KOKKOS_GPU_ARCH")"
    fi

    if [[ -z "$SM_ARCH" || "${SM_ARCH,,}" == "auto" ]]; then
        SM_ARCH="$(gpu_sm_arch "$KOKKOS_GPU_ARCH")"
    else
        SM_ARCH="$(gpu_sm_arch "$SM_ARCH")"
    fi
}

validate_config() {
    case "$ACC_TYPE" in
        cpu|avx2|gpu) ;;
        *)
            if is_zh; then
                die "ACC_TYPE 必须是 cpu、avx2 或 gpu"
            else
                die "ACC_TYPE must be one of: cpu, avx2, gpu"
            fi
            ;;
    esac

    case "$BUILD_SYSTEM" in
        make|cmake) ;;
        *)
            if is_zh; then
                die "BUILD_SYSTEM 最终必须解析为 make 或 cmake"
            else
                die "BUILD_SYSTEM must resolve to make or cmake"
            fi
            ;;
    esac

    KOKKOS_PRECISION="$(normalize_precision_choice "$KOKKOS_PRECISION" 2>/dev/null || printf "%s" "$KOKKOS_PRECISION")"
    case "${KOKKOS_PRECISION,,}" in
        auto|double|mixed|single) ;;
        *)
            if is_zh; then
                die "KOKKOS_PRECISION 必须是 auto、single、mixed 或 double"
            else
                die "KOKKOS_PRECISION must be auto, single, mixed, or double"
            fi
            ;;
    esac

    GPU_PREC="$(normalize_precision_choice "$GPU_PREC" 2>/dev/null || printf "%s" "$GPU_PREC")"
    case "${GPU_PREC,,}" in
        double|mixed|single) ;;
        *)
            if is_zh; then
                die "GPU_PREC 必须是 double、mixed 或 single"
            else
                die "GPU_PREC must be one of: double, mixed, single"
            fi
            ;;
    esac

    if [[ ! "$JN" =~ ^[0-9]+$ || "$JN" -le 0 ]]; then
        if is_zh; then die "JN 必须是正整数"; else die "JN must be a positive integer"; fi
    fi
    if [[ ! "$ATC_JN" =~ ^[0-9]+$ || "$ATC_JN" -le 0 ]]; then
        if is_zh; then die "ATC_JN 必须是正整数"; else die "ATC_JN must be a positive integer"; fi
    fi
    if [[ -z "$APP_ROOT" || -z "$LMP_ROOT" || -z "$BUILD_ROOT" || -z "$DOWNLOAD_ROOT" ]]; then
        if is_zh; then die "安装路径不能为空"; else die "Install paths must not be empty"; fi
    fi
    if [[ -z "$VORONOI_PATH" || -z "$EIGEN_PATH" ]]; then
        if is_zh; then die "第三方库路径不能为空"; else die "External library paths must not be empty"; fi
    fi
    if [[ "$APP_ROOT" != /* || "$LMP_ROOT" != /* || "$BUILD_ROOT" != /* || "$DOWNLOAD_ROOT" != /* ]]; then
        if is_zh; then die "安装路径必须是绝对路径"; else die "Install paths must be absolute"; fi
    fi
    if [[ "$VORONOI_PATH" != /* || "$EIGEN_PATH" != /* ]]; then
        if is_zh; then die "第三方库路径必须是绝对路径"; else die "External library paths must be absolute"; fi
    fi

    case "${USE_PROXY,,}" in
        auto|0|1|true|false|yes|no|on|off|自动|需要|启用|加载|不需要|禁用|不加载) ;;
        *)
            if is_zh; then
                die "USE_PROXY 必须是 auto、0、1、true、false、yes、no、on 或 off"
            else
                die "USE_PROXY must be auto, 0, 1, true, false, yes, no, on, or off"
            fi
            ;;
    esac
    USE_PROXY="$(normalize_proxy_mode_choice "$USE_PROXY" 2>/dev/null || printf "%s" "$USE_PROXY")"

    case "${LOAD_MODULES,,}" in
        0|1|true|false|yes|no|on|off|是|需要|启用|加载|否|不需要|禁用|不加载) ;;
        *)
            if is_zh; then
                die "LOAD_MODULES 必须是 0、1、true、false、yes、no、on 或 off"
            else
                die "LOAD_MODULES must be 0, 1, true, false, yes, no, on, or off"
            fi
            ;;
    esac
    LOAD_MODULES="$(normalize_yes_no_choice "$LOAD_MODULES" 2>/dev/null || printf "%s" "$LOAD_MODULES")"
    if [[ "$LOAD_MODULES" == "1" && -z "$ACTIVE_MODULE_LIST" ]]; then
        if is_zh; then
            die "启用 LOAD_MODULES 时 module 列表不能为空"
        else
            die "Module list must not be empty when LOAD_MODULES is enabled"
        fi
    fi

    case "${INTERACTIVE,,}" in
        auto|0|1|true|false|yes|no|on|off) ;;
        *)
            if is_zh; then
                die "INTERACTIVE 必须是 auto、1 或 0"
            else
                die "INTERACTIVE must be auto, 1, or 0"
            fi
            ;;
    esac

    case "${LMP_LANG,,}" in
        auto|zh|zh_cn|zh-cn|cn|chinese|en|en_us|en-us|english) ;;
        *)
            if is_zh; then
                die "LMP_LANG 必须是 auto、zh 或 en"
            else
                die "LMP_LANG must be auto, zh, or en"
            fi
            ;;
    esac

    sync_precision_options
}

configure_interactive_inputs() {
    local default_lmp_path requested_lmp_path

    interactive_enabled || return 0

    choose_packages_interactive
    choose_package_options_interactive

    if is_zh; then
        JN="$(prompt_positive_integer "编译核数（make -j / cmake --parallel）" "$JN")"
        if package_enabled ATC; then
            ATC_JN="$(prompt_positive_integer "ATC 库编译核数" "$ATC_JN")"
        fi
    else
        JN="$(prompt_positive_integer "Build jobs (make -j / cmake --parallel)" "$JN")"
        if package_enabled ATC; then
            ATC_JN="$(prompt_positive_integer "ATC library build jobs" "$ATC_JN")"
        fi
    fi

    default_lmp_path="${HOME}/apps/lammps-${LMP_VERSION}"
    requested_lmp_path="${LMP_PATH:-$default_lmp_path}"
    if is_zh; then
        LMP_PATH="$(absolute_path "$(prompt_path "LAMMPS 安装路径" "$requested_lmp_path")")"
    else
        LMP_PATH="$(absolute_path "$(prompt_path "LAMMPS install path" "$requested_lmp_path")")"
    fi

    choose_external_package_paths
}

assert_safe_rm_path() {
    local path=$1
    local label=$2

    case "$path" in
        ""|"/"|"$HOME"|"$APP_ROOT"|"$LIB_ROOT"|"$LMP_ROOT"|"$BUILD_ROOT"|"$DOWNLOAD_ROOT")
            if is_zh; then
                die "拒绝删除不安全的 ${label}: $path"
            else
                die "Refusing to remove unsafe ${label}: $path"
            fi
            ;;
    esac
}

set_install_paths() {
    if [[ -z "$LMP_PATH" ]]; then
        LMP_PATH="${HOME}/apps/lammps-${LMP_VERSION}"
    fi
    LMP_PATH="$(absolute_path "$LMP_PATH")"
    WORK_DIR="${BUILD_ROOT}/${LMP_VERSION}-$(date +%Y%m%d-%H%M%S)-$$"
}

create_directories() {
    mkdir -p \
        "$APP_ROOT" \
        "$LIB_ROOT" \
        "$LMP_PATH/bin" \
        "$BUILD_ROOT" \
        "$DOWNLOAD_ROOT" \
        "$(dirname "$VORONOI_PATH")" \
        "$(dirname "$EIGEN_PATH")" \
        "$WORK_DIR"
}

select_module_lists() {
    case "$BUILD_SYSTEM:$ACC_TYPE" in
        cmake:gpu)
            ACTIVE_MODULE_LIST="$GPU_MODULE_LIST"
            RUNTIME_MODULE_LIST="${GPU_RUNTIME_MODULE_LIST:-${DEFAULT_RUNTIME_MODULE_LIST:-cuda/12.1 compiler/2023.1.0 mkl/2023.1.0 mpi/2021.9.0}}"
            ;;
        *)
            ACTIVE_MODULE_LIST="$MODULE_LIST"
            RUNTIME_MODULE_LIST="${RUNTIME_MODULE_LIST_OVERRIDE:-${DEFAULT_RUNTIME_MODULE_LIST:-mkl/2023.1.0 mpi/2021.9.0}}"
            ;;
    esac
}

shell_quote() {
    printf "%q" "$1"
}

write_build_config() {
    local output_path packages_string

    case "${SAVE_BUILD_CONFIG,,}" in
        auto)
            interactive_enabled || return 0
            ;;
        0|false|no|off) return 0 ;;
        1|true|yes|on) ;;
        *)
            if is_zh; then
                die "SAVE_BUILD_CONFIG 必须是 auto、1 或 0"
            else
                die "SAVE_BUILD_CONFIG must be auto, 1, or 0"
            fi
            ;;
    esac

    if [[ "$BUILD_CONFIG_OUTPUT" == "auto" || -z "$BUILD_CONFIG_OUTPUT" ]]; then
        output_path="${CONFIG_OUTPUT_PATH:-${PWD}/lammps-build-${LMP_VERSION}.conf}"
    else
        output_path="$BUILD_CONFIG_OUTPUT"
    fi
    output_path="$(absolute_path "$output_path")"
    mkdir -p "$(dirname "$output_path")"
    packages_string="${YES_PACKAGES[*]}"

    {
        echo "# Generated by build-lmp.sh. Reuse with: ./build-lmp.sh -c $output_path"
        printf "LMP_VERSION=%s\n" "$(shell_quote "$LMP_VERSION")"
        printf "LMP_LANG=%s\n" "$(shell_quote "$SCRIPT_LANG")"
        printf "INTERACTIVE=0\n"
        printf "CONFIG_YES_PACKAGES=%s\n" "$(shell_quote "$packages_string")"
        printf "LMP_PATH=%s\n" "$(shell_quote "$LMP_PATH")"
        printf "APP_ROOT=%s\n" "$(shell_quote "$APP_ROOT")"
        printf "LIB_ROOT=%s\n" "$(shell_quote "$LIB_ROOT")"
        printf "BUILD_ROOT=%s\n" "$(shell_quote "$BUILD_ROOT")"
        printf "DOWNLOAD_ROOT=%s\n" "$(shell_quote "$DOWNLOAD_ROOT")"
        printf "VORONOI_PATH=%s\n" "$(shell_quote "$VORONOI_PATH")"
        printf "EIGEN_PATH=%s\n" "$(shell_quote "$EIGEN_PATH")"
        printf "ACC_TYPE=%s\n" "$(shell_quote "$ACC_TYPE")"
        printf "BUILD_SYSTEM=%s\n" "$(shell_quote "$BUILD_SYSTEM")"
        printf "CMAKE_BUILD_TYPE=%s\n" "$(shell_quote "$CMAKE_BUILD_TYPE")"
        printf "CMAKE_EXTRA_ARGS=%s\n" "$(shell_quote "$CMAKE_EXTRA_ARGS")"
        printf "KOKKOS_GPU_ARCH=%s\n" "$(shell_quote "$KOKKOS_GPU_ARCH")"
        printf "SM_ARCH=%s\n" "$(shell_quote "$SM_ARCH")"
        printf "KOKKOS_PRECISION=%s\n" "$(shell_quote "$KOKKOS_PRECISION")"
        printf "KSPACE_PRECISION=%s\n" "$(shell_quote "$KSPACE_PRECISION")"
        printf "FFT_SINGLE=%s\n" "$(shell_quote "$FFT_SINGLE")"
        printf "GPU_PREC=%s\n" "$(shell_quote "$GPU_PREC")"
        printf "ENABLE_GPU_PACKAGE=%s\n" "$(shell_quote "$ENABLE_GPU_PACKAGE")"
        printf "ALLOW_ML_HDNNP_KOKKOS_GPU=%s\n" "$(shell_quote "$ALLOW_ML_HDNNP_KOKKOS_GPU")"
        printf "JN=%s\n" "$(shell_quote "$JN")"
        printf "ATC_JN=%s\n" "$(shell_quote "$ATC_JN")"
        printf "USE_PROXY=%s\n" "$(shell_quote "$USE_PROXY")"
        printf "PROXY_FILE=%s\n" "$(shell_quote "$PROXY_FILE")"
        printf "LOAD_MODULES=%s\n" "$(shell_quote "$LOAD_MODULES")"
        printf "MODULE_LIST=%s\n" "$(shell_quote "$MODULE_LIST")"
        printf "RUNTIME_MODULE_LIST_OVERRIDE=%s\n" "$(shell_quote "$RUNTIME_MODULE_LIST_OVERRIDE")"
        printf "GPU_MODULE_LIST=%s\n" "$(shell_quote "$GPU_MODULE_LIST")"
        printf "GPU_RUNTIME_MODULE_LIST=%s\n" "$(shell_quote "$GPU_RUNTIME_MODULE_LIST")"
        printf "MPI_CXX_COMPILER=%s\n" "$(shell_quote "$MPI_CXX_COMPILER")"
        printf "KOKKOS_HOST_COMPILER=%s\n" "$(shell_quote "$KOKKOS_HOST_COMPILER")"
        printf "C_COMPILER=%s\n" "$(shell_quote "$C_COMPILER")"
        printf "FORTRAN_COMPILER=%s\n" "$(shell_quote "$FORTRAN_COMPILER")"
        printf "SUPPRESS_WARNINGS=%s\n" "$(shell_quote "$SUPPRESS_WARNINGS")"
        printf "INTEL_DIAG_DISABLES=%s\n" "$(shell_quote "$INTEL_DIAG_DISABLES")"
        printf "INTEL_CXX_FLAGS=%s\n" "$(shell_quote "$INTEL_CXX_FLAGS")"
        printf "INTEL_C_FLAGS=%s\n" "$(shell_quote "$INTEL_C_FLAGS")"
        printf "INTEL_FC_FLAGS=%s\n" "$(shell_quote "$INTEL_FC_FLAGS")"
        printf "SAVE_BUILD_CONFIG=0\n"
    } >"$output_path"

    CONFIG_OUTPUT_PATH="$output_path"
    if is_zh; then
        echo "已写入可复用配置文件: $output_path"
    else
        echo "Reusable build config written: $output_path"
    fi
}

load_build_modules() {
    [[ "$LOAD_MODULES" == "1" ]] || return 0
    if ! command -v module >/dev/null 2>&1; then
        if is_zh; then
            die "环境 modules 不可用。如果构建环境已加载，可设置 LOAD_MODULES=0"
        else
            die "Environment modules are unavailable. Set LOAD_MODULES=0 if the build environment is already loaded."
        fi
    fi

    if is_zh; then
        log "加载编译器和 MPI modules"
        log "编译 module 列表: $ACTIVE_MODULE_LIST"
    else
        log "Loading compiler and MPI modules"
        log "Build module list: $ACTIVE_MODULE_LIST"
    fi
    module purge
    # shellcheck disable=SC2086
    module load $ACTIVE_MODULE_LIST
}

post_module_checks() {
    if [[ "$BUILD_SYSTEM" == "cmake" ]]; then
        require_command cmake
        C_COMPILER_PATH="$(resolve_tool "$C_COMPILER" "C compiler")"
        FORTRAN_COMPILER_PATH="$(resolve_tool "$FORTRAN_COMPILER" "Fortran compiler")"
        MPI_CXX_COMPILER_PATH="$(resolve_tool "$MPI_CXX_COMPILER" "MPI C++ compiler")"
        if "$MPI_CXX_COMPILER_PATH" -show 2>&1 | grep -Eiq 'open[[:space:]_-]*mpi|openmpi'; then
            if is_zh; then
                die "检测到 OpenMPI C++ wrapper: $MPI_CXX_COMPILER_PATH。请使用 Intel MPI wrapper，例如 mpiicpc"
            else
                die "Detected an OpenMPI C++ wrapper: $MPI_CXX_COMPILER_PATH. Use an Intel MPI wrapper such as mpiicpc."
            fi
        fi
    fi

    if [[ "$BUILD_SYSTEM" == "cmake" && "$ACC_TYPE" == "gpu" ]]; then
        require_command nvcc
        KOKKOS_HOST_COMPILER_PATH="$(resolve_tool "$KOKKOS_HOST_COMPILER" "Kokkos host compiler")"
        CUDA_ROOT="$(cd "$(dirname "$(dirname "$(command -v nvcc)")")" && pwd)"
        export CUDA_ROOT CUDA_HOME="$CUDA_ROOT"
    fi

    if package_enabled VORONOI; then
        VORONOI_CXX="$(resolve_tool "$VORONOI_CXX" "voro++ C++ compiler")"
    fi
}

load_proxy() {
    case "$(normalize_proxy_mode_choice "$USE_PROXY" 2>/dev/null || printf "%s" "$USE_PROXY")" in
        0)
            return 0
            ;;
        1)
            if [[ ! -f "$PROXY_FILE" ]]; then
                if is_zh; then
                    die "找不到代理配置文件: $PROXY_FILE"
                else
                    die "Proxy file not found: $PROXY_FILE"
                fi
            fi
            if is_zh; then
                log "从 $PROXY_FILE 加载代理设置"
            else
                log "Loading proxy settings from $PROXY_FILE"
            fi
            # shellcheck source=/dev/null
            source "$PROXY_FILE"
            ;;
        auto)
            if [[ -f "$PROXY_FILE" ]]; then
                if is_zh; then
                    log "从 $PROXY_FILE 加载代理设置"
                else
                    log "Loading proxy settings from $PROXY_FILE"
                fi
                # shellcheck source=/dev/null
                source "$PROXY_FILE"
            fi
            ;;
    esac
}

download_file() {
    local dest=$1
    shift
    local url tmp

    if [[ -s "$dest" ]]; then
        if is_zh; then
            echo "使用缓存文件: $dest"
        else
            echo "Using cached file: $dest"
        fi
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    tmp="${dest}.tmp.$$"
    rm -f "$tmp"

    for url in "$@"; do
        if is_zh; then
            echo "下载: $url"
        else
            echo "Downloading: $url"
        fi
        if wget \
            --no-check-certificate \
            --connect-timeout="$WGET_CONNECT_TIMEOUT" \
            --read-timeout="$WGET_READ_TIMEOUT" \
            --tries="$WGET_TRIES" \
            -O "$tmp" \
            "$url"; then
            if [[ -s "$tmp" ]]; then
                mv "$tmp" "$dest"
                return 0
            fi
        fi
        rm -f "$tmp"
        if is_zh; then
            echo "下载失败，如有下一个镜像则继续尝试。"
        else
            echo "Download failed, trying next mirror if available."
        fi
    done

    if is_zh; then
        die "无法下载 $(basename "$dest")"
    else
        die "Unable to download $(basename "$dest")"
    fi
}

install_voronoi() {
    local archive src_dir

    if [[ -d "$VORONOI_PATH/include/voro++" && -d "$VORONOI_PATH/lib" ]]; then
        if is_zh; then
            echo "voro++ 已安装在 $VORONOI_PATH"
        else
            echo "voro++ is already installed in $VORONOI_PATH"
        fi
        return 0
    fi

    if is_zh; then
        log "安装 voro++ 到 $VORONOI_PATH"
    else
        log "Installing voro++ into $VORONOI_PATH"
    fi
    archive="${DOWNLOAD_ROOT}/voro++-0.4.6.tar.gz"
    src_dir="${WORK_DIR}/voro++-0.4.6"
    download_file "$archive" "$VORONOI_URL"

    tar -xzf "$archive" -C "$WORK_DIR"
    pushd "$src_dir" >/dev/null
    sed -i \
        -e "s@PREFIX=/usr/local@PREFIX=${VORONOI_PATH}@g" \
        -e "s@CXX=g++@CXX=${VORONOI_CXX}@g" \
        -e "s@O3@${VORONOI_CFLAG}@g" \
        config.mk
    make -j "$JN"
    make install
    popd >/dev/null
}

install_eigen() {
    local archive src_dir

    if [[ -d "$EIGEN_PATH/Eigen" ]]; then
        if is_zh; then
            echo "Eigen 已安装在 $EIGEN_PATH"
        else
            echo "Eigen is already installed in $EIGEN_PATH"
        fi
        return 0
    fi

    if is_zh; then
        log "安装 Eigen 到 $EIGEN_PATH"
    else
        log "Installing Eigen into $EIGEN_PATH"
    fi
    archive="${DOWNLOAD_ROOT}/eigen-3.4.0.tar.bz2"
    src_dir="${WORK_DIR}/eigen-3.4.0"
    download_file "$archive" "$EIGEN_URL"

    tar -xf "$archive" -C "$WORK_DIR"
    assert_safe_rm_path "$EIGEN_PATH" "Eigen path"
    rm -rf "$EIGEN_PATH"
    mv "$src_dir" "$EIGEN_PATH"
}

prepare_kim_archive() {
    package_enabled KIM || return 0
    [[ "$BUILD_SYSTEM" == "cmake" ]] || return 0

    if is_zh; then
        log "准备 KIM API 源码包"
    else
        log "Preparing KIM API archive"
    fi
    download_file "$KIM_API_ARCHIVE" "$KIM_API_URL"
}

prepare_external_libraries() {
    run_version_hook version_prepare_external_libraries
}

patch_lammps_source() {
    run_version_hook version_patch_lammps_source
}

copy_lammps_runtime_data() {
    assert_safe_rm_path "${LMP_PATH}/examples" "examples path"
    assert_safe_rm_path "${LMP_PATH}/potentials" "potentials path"
    rm -rf "${LMP_PATH}/examples" "${LMP_PATH}/potentials"
    cp -a "${LMP_SRC}/examples" "$LMP_PATH/"
    cp -a "${LMP_SRC}/potentials" "$LMP_PATH/"
}

install_kim_runtime() {
    local cmake_build_dir=$1
    local kim_prefix kim_dest entry

    package_enabled KIM || return 0

    kim_prefix="${cmake_build_dir}/kim_build-prefix"
    if [[ ! -d "${kim_prefix}/lib" ]]; then
        kim_prefix="$(find "$cmake_build_dir" -maxdepth 3 -type d -name kim_build-prefix -print -quit)"
    fi
    [[ -n "$kim_prefix" && -d "${kim_prefix}/lib" ]] || { if is_zh; then die "无法定位 KIM API 运行时前缀目录"; else die "Unable to locate KIM API runtime prefix"; fi; }

    kim_dest="${LMP_PATH}/kim-api"
    assert_safe_rm_path "$kim_dest" "KIM API runtime path"
    rm -rf "$kim_dest"
    mkdir -p "$kim_dest"

    for entry in bin etc include lib libexec share; do
        [[ -e "${kim_prefix}/${entry}" ]] && cp -a "${kim_prefix}/${entry}" "$kim_dest/"
    done
}

extract_lammps_source() {
    local archive src_dir
    local lmp_urls=(
        "${SOFT_SERV%/}/lammps-${LMP_VERSION}.tar.gz"
        "https://download.lammps.org/tars/lammps-${LMP_VERSION}.tar.gz"
        "https://github.com/lammps/lammps/archive/refs/tags/stable_${LMP_VERSION}.tar.gz"
    )

    archive="${DOWNLOAD_ROOT}/lammps-${LMP_VERSION}.tar.gz"
    download_file "$archive" "${lmp_urls[@]}"

    if is_zh; then
        log "解压 LAMMPS $LMP_VERSION"
    else
        log "Extracting LAMMPS $LMP_VERSION"
    fi
    tar -xzf "$archive" -C "$WORK_DIR"
    src_dir="$(find_lammps_source_dir)"
    LMP_SRC="$src_dir"
    [[ -d "${LMP_SRC}/src" ]] || { if is_zh; then die "LAMMPS 源码树缺少 src/: $LMP_SRC"; else die "LAMMPS source tree is missing src/: $LMP_SRC"; fi; }
    patch_lammps_source
}

build_lammps_make() {
    local make_template makefile make_target binary_src pkg removed_pkg binary_name

    extract_lammps_source
    export_compiler_warning_flags

    pushd "${LMP_SRC}/src" >/dev/null
    make_template="$(lammps_make_template_path)"
    makefile="$(lammps_makefile_path)"
    [[ -f "$make_template" ]] || { if is_zh; then die "缺少 makefile 模板: $make_template"; else die "Missing makefile template: $make_template"; fi; }

    cp "$make_template" "$makefile"
    require_version_hook version_configure_lammps_makefile "$makefile"

    if is_zh; then
        log "启用 LAMMPS packages"
    else
        log "Enabling LAMMPS packages"
    fi
    for pkg in "${YES_PACKAGES[@]}"; do
        make "yes-${pkg}"
    done
    for removed_pkg in "${REMOVED_PACKAGES[@]}"; do
        pkg="${removed_pkg%%:*}"
        make "no-${pkg}"
    done

    if [[ "$ACC_TYPE" != "gpu" ]]; then
        make no-gpu
    fi
    popd >/dev/null

    if package_enabled ATC; then
        require_version_hook version_build_atc
    fi

    if [[ "$ACC_TYPE" == "gpu" ]]; then
        require_version_hook version_configure_gpu_package
    fi

    if package_enabled ML-PACE; then
        require_version_hook version_build_pace
    fi

    if package_enabled VORONOI; then
        require_version_hook version_link_voronoi_package
    fi

    if package_enabled MACHDYN; then
        require_version_hook version_link_machdyn_package
    fi

    if is_zh; then
        log "编译 LAMMPS"
    else
        log "Compiling LAMMPS"
    fi
    pushd "${LMP_SRC}/src" >/dev/null
    make_target="$(lammps_make_target)"
    make -j "$JN" "$make_target"

    binary_src="$(lammps_make_binary_path)"
    [[ -x "$binary_src" ]] || { if is_zh; then die "无法定位 make 编译出的 LAMMPS 可执行文件: $binary_src"; else die "Unable to locate make-built LAMMPS binary: $binary_src"; fi; }
    binary_name="lammps-${ACC_TYPE}"
    install -m 755 "$binary_src" "${LMP_PATH}/bin/${binary_name}"
    popd >/dev/null

    copy_lammps_runtime_data
}

build_lammps_cmake() {
    local pkg binary_src binary_name cmake_build_dir
    local mpi_cxx_path
    local cmake_args=()
    local extra_args=()

    extract_lammps_source
    export_compiler_warning_flags

    cmake_build_dir="${WORK_DIR}/cmake-build"
    mkdir -p "$cmake_build_dir"
    mpi_cxx_path="${MPI_CXX_COMPILER_PATH:-$(resolve_tool "$MPI_CXX_COMPILER" "MPI C++ compiler")}"

    cmake_args+=(
        "-S" "${LMP_SRC}/cmake"
        "-B" "$cmake_build_dir"
        "-D" "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
        "-D" "CMAKE_INSTALL_PREFIX=${LMP_PATH}"
        "-D" "CMAKE_C_COMPILER=${C_COMPILER_PATH:-$(resolve_tool "$C_COMPILER" "C compiler")}"
        "-D" "CMAKE_Fortran_COMPILER=${FORTRAN_COMPILER_PATH:-$(resolve_tool "$FORTRAN_COMPILER" "Fortran compiler")}"
        "-D" "CMAKE_C_FLAGS=${INTEL_C_FLAGS}"
        "-D" "CMAKE_Fortran_FLAGS=${INTEL_FC_FLAGS}"
        "-D" "BUILD_MPI=ON"
        "-D" "BUILD_OMP=ON"
        "-D" "CMAKE_CXX_STANDARD=17"
        "-D" "CMAKE_CXX_STANDARD_REQUIRED=ON"
        "-D" "CMAKE_CXX_EXTENSIONS=OFF"
    )

    if ! package_enabled KOKKOS; then
        cmake_args+=(
            "-D" "CMAKE_CXX_COMPILER=${mpi_cxx_path}"
            "-D" "CMAKE_CXX_FLAGS=${INTEL_CXX_FLAGS}"
        )
    fi

    for pkg in "${YES_PACKAGES[@]}"; do
        cmake_args+=("-D" "PKG_${pkg}=ON")
    done
    for pkg in "${REMOVED_PACKAGES[@]}"; do
        cmake_args+=("-D" "PKG_${pkg%%:*}=OFF")
    done

    require_version_hook version_add_cmake_package_args cmake_args "$mpi_cxx_path"

    if [[ -n "$CMAKE_EXTRA_ARGS" ]]; then
        # shellcheck disable=SC2206
        extra_args=($CMAKE_EXTRA_ARGS)
    fi

    if is_zh; then
        log "使用 CMake 配置 LAMMPS"
    else
        log "Configuring LAMMPS with CMake"
    fi
    cmake -Wno-dev -Wno-deprecated "${cmake_args[@]}" "${extra_args[@]}"

    if is_zh; then
        log "编译 LAMMPS"
    else
        log "Compiling LAMMPS"
    fi
    cmake --build "$cmake_build_dir" --parallel "$JN"

    if is_zh; then
        log "安装 LAMMPS"
    else
        log "Installing LAMMPS"
    fi
    cmake --install "$cmake_build_dir"
    install_kim_runtime "$cmake_build_dir"

    if [[ -x "${cmake_build_dir}/lmp" ]]; then
        binary_src="${cmake_build_dir}/lmp"
    elif [[ -x "${cmake_build_dir}/lmp_mpi" ]]; then
        binary_src="${cmake_build_dir}/lmp_mpi"
    else
        binary_src="$(find "$cmake_build_dir" -maxdepth 2 -type f -name 'lmp*' -perm -111 -print -quit)"
    fi
    [[ -n "$binary_src" && -x "$binary_src" ]] || { if is_zh; then die "无法定位 CMake 编译出的 LAMMPS 可执行文件"; else die "Unable to locate CMake-built LAMMPS binary"; fi; }

    binary_name="lammps-${ACC_TYPE}"
    install -m 755 "$binary_src" "${LMP_PATH}/bin/${binary_name}"
    copy_lammps_runtime_data
}

build_lammps() {
    case "$BUILD_SYSTEM" in
        make) build_lammps_make ;;
        cmake) build_lammps_cmake ;;
        *) if is_zh; then die "不支持的 BUILD_SYSTEM: $BUILD_SYSTEM"; else die "Unsupported BUILD_SYSTEM: $BUILD_SYSTEM"; fi ;;
    esac
}

find_lammps_source_dir() {
    local candidate

    for candidate in "${WORK_DIR}/lammps-${LMP_VERSION}" "${WORK_DIR}/lammps-stable_${LMP_VERSION}"; do
        if [[ -d "${candidate}/src" && ( -f "${candidate}/src/lammps.cpp" || -f "${candidate}/cmake/CMakeLists.txt" ) ]]; then
            printf "%s\n" "$candidate"
            return 0
        fi
    done

    while IFS= read -r candidate; do
        printf "%s\n" "$candidate"
        return 0
    done < <(find "$WORK_DIR" -mindepth 2 -maxdepth 4 \( -path "*/src/lammps.cpp" -o -path "*/cmake/CMakeLists.txt" \) -print | sed -e 's@/src/lammps.cpp$@@' -e 's@/cmake/CMakeLists.txt$@@')

    if is_zh; then
        die "无法定位解压后的 LAMMPS 源码目录"
    else
        die "Unable to locate extracted LAMMPS source directory"
    fi
}

write_modulefile() {
    local module_name

    {
        echo "#%Module 1.0"
        echo "conflict lammps"
        for module_name in $RUNTIME_MODULE_LIST; do
            printf "prereq  %s\n" "$module_name"
        done
        printf "prepend-path    PATH                    %s/bin\n" "$LMP_PATH"
        if [[ -d "${LMP_PATH}/kim-api/lib" ]]; then
            printf "prepend-path    PATH                    %s/kim-api/bin\n" "$LMP_PATH"
            printf "prepend-path    LD_LIBRARY_PATH         %s/kim-api/lib\n" "$LMP_PATH"
            printf "prepend-path    PKG_CONFIG_PATH         %s/kim-api/lib/pkgconfig\n" "$LMP_PATH"
            printf "setenv          KIM_API_CMAKE_PREFIX_DIR %s/kim-api\n" "$LMP_PATH"
        fi
    } >"${LMP_PATH}/modulefile"
}

print_configuration() {
    if is_zh; then
        log "构建配置"
        printf "  %-14s %s\n" "版本:" "$LMP_VERSION"
        printf "  %-14s %s\n" "构建系统:" "$BUILD_SYSTEM"
        printf "  %-14s %s\n" "安装路径:" "$LMP_PATH"
        printf "  %-14s %s\n" "构建目录:" "$WORK_DIR"
        printf "  %-14s %s\n" "下载目录:" "$DOWNLOAD_ROOT"
        printf "  %-14s %s\n" "voro++:" "$VORONOI_PATH"
        printf "  %-14s %s\n" "Eigen:" "$EIGEN_PATH"
        printf "  %-14s %s\n" "ACC_TYPE:" "$ACC_TYPE"
        printf "  %-14s %s\n" "代理:" "$(proxy_mode_label "$USE_PROXY")"
        printf "  %-14s %s\n" "代理脚本:" "$PROXY_FILE"
        printf "  %-14s %s\n" "加载module:" "$(yes_no_label "$LOAD_MODULES")"
        printf "  %-14s %s\n" "Modules:" "$ACTIVE_MODULE_LIST"
        printf "  %-14s %s\n" "运行Modules:" "$RUNTIME_MODULE_LIST"
        printf "  %-14s %s\n" "并行任务:" "$JN"
        printf "  %-14s %s\n" "ATC任务:" "$ATC_JN"
    else
        log "Build configuration"
        printf "  %-14s %s\n" "Version:" "$LMP_VERSION"
        printf "  %-14s %s\n" "Build system:" "$BUILD_SYSTEM"
        printf "  %-14s %s\n" "Install path:" "$LMP_PATH"
        printf "  %-14s %s\n" "Build dir:" "$WORK_DIR"
        printf "  %-14s %s\n" "Downloads:" "$DOWNLOAD_ROOT"
        printf "  %-14s %s\n" "voro++:" "$VORONOI_PATH"
        printf "  %-14s %s\n" "Eigen:" "$EIGEN_PATH"
        printf "  %-14s %s\n" "ACC_TYPE:" "$ACC_TYPE"
        printf "  %-14s %s\n" "Proxy:" "$(proxy_mode_label "$USE_PROXY")"
        printf "  %-14s %s\n" "Proxy file:" "$PROXY_FILE"
        printf "  %-14s %s\n" "Load modules:" "$(yes_no_label "$LOAD_MODULES")"
        printf "  %-14s %s\n" "Modules:" "$ACTIVE_MODULE_LIST"
        printf "  %-14s %s\n" "Runtime mods:" "$RUNTIME_MODULE_LIST"
        printf "  %-14s %s\n" "Jobs:" "$JN"
        printf "  %-14s %s\n" "ATC jobs:" "$ATC_JN"
    fi

    if [[ "$BUILD_SYSTEM" == "cmake" && "$ACC_TYPE" == "gpu" ]]; then
        if is_zh; then
            printf "  %-14s %s\n" "CUDA根目录:" "$CUDA_ROOT"
            printf "  %-14s %s\n" "Kokkos架构:" "$(normalize_kokkos_arch "$KOKKOS_GPU_ARCH")"
            printf "  %-14s %s\n" "CUDA SM:" "$SM_ARCH"
            printf "  %-14s %s\n" "请求精度:" "$KOKKOS_PRECISION"
            printf "  %-14s %s\n" "Kokkos核心:" "$(kokkos_core_precision_label)"
            printf "  %-14s %s\n" "Kspace精度:" "$KSPACE_PRECISION"
            printf "  %-14s %s\n" "FFT单精度:" "$FFT_SINGLE"
            printf "  %-14s %s\n" "GPU精度:" "$GPU_PREC"
            printf "  %-14s %s\n" "MPI CXX:" "$MPI_CXX_COMPILER"
            printf "  %-14s %s\n" "Kokkos host:" "$KOKKOS_HOST_COMPILER"
            printf "  %-14s %s\n" "C编译器:" "$C_COMPILER"
            printf "  %-14s %s\n" "Fortran:" "$FORTRAN_COMPILER"
            printf "  %-14s %s\n" "Intel CXX:" "$INTEL_CXX_FLAGS"
            printf "  %-14s %s\n" "Intel C:" "$INTEL_C_FLAGS"
            printf "  %-14s %s\n" "Intel FC:" "$INTEL_FC_FLAGS"
            printf "  %-14s %s\n" "CMake类型:" "$CMAKE_BUILD_TYPE"
        else
            printf "  %-14s %s\n" "CUDA root:" "$CUDA_ROOT"
            printf "  %-14s %s\n" "Kokkos arch:" "$(normalize_kokkos_arch "$KOKKOS_GPU_ARCH")"
            printf "  %-14s %s\n" "CUDA SM:" "$SM_ARCH"
            printf "  %-14s %s\n" "Req precision:" "$KOKKOS_PRECISION"
            printf "  %-14s %s\n" "Kokkos core:" "$(kokkos_core_precision_label)"
            printf "  %-14s %s\n" "Kspace prec:" "$KSPACE_PRECISION"
            printf "  %-14s %s\n" "FFT single:" "$FFT_SINGLE"
            printf "  %-14s %s\n" "GPU prec:" "$GPU_PREC"
            printf "  %-14s %s\n" "MPI CXX:" "$MPI_CXX_COMPILER"
            printf "  %-14s %s\n" "Kokkos host:" "$KOKKOS_HOST_COMPILER"
            printf "  %-14s %s\n" "C compiler:" "$C_COMPILER"
            printf "  %-14s %s\n" "Fortran:" "$FORTRAN_COMPILER"
            printf "  %-14s %s\n" "Intel CXX:" "$INTEL_CXX_FLAGS"
            printf "  %-14s %s\n" "Intel C:" "$INTEL_C_FLAGS"
            printf "  %-14s %s\n" "Intel FC:" "$INTEL_FC_FLAGS"
            printf "  %-14s %s\n" "CMake type:" "$CMAKE_BUILD_TYPE"
        fi
    fi
}

main() {
    local check_only=0
    local positional=()

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    while (($# > 0)); do
        case "$1" in
            --check)
                check_only=1
                shift
                ;;
            -c|--config)
                shift
                [[ $# -gt 0 ]] || { if is_zh; then die "-c 需要指定配置文件"; else die "-c requires a config file"; fi; }
                load_build_config "$1"
                shift
                ;;
            --config=*)
                load_build_config "${1#--config=}"
                shift
                ;;
            --config-output)
                shift
                [[ $# -gt 0 ]] || { if is_zh; then die "--config-output 需要指定输出文件"; else die "--config-output requires an output file"; fi; }
                BUILD_CONFIG_OUTPUT="$1"
                shift
                ;;
            --config-output=*)
                BUILD_CONFIG_OUTPUT="${1#--config-output=}"
                shift
                ;;
            --no-save-config)
                SAVE_BUILD_CONFIG=0
                shift
                ;;
            -*)
                if is_zh; then
                    die "未知参数: $1"
                else
                    die "Unknown option: $1"
                fi
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    ((${#positional[@]} <= 1)) || { if is_zh; then die "参数过多"; else die "Too many arguments"; fi; }

    require_command awk basename comm cp date dirname find grep install make mkdir mv rm sed sort tar wget
    discover_versions
    choose_language

    if ((${#positional[@]} == 1)); then
        LMP_VERSION="${positional[0]}"
    elif [[ -n "${LMP_VERSION:-}" ]]; then
        :
    else
        choose_version
    fi

    if [[ -n "${LMP_VERSION:-}" ]]; then
        if ! version_supported "$LMP_VERSION"; then
            if is_zh; then
                die "不支持的 LAMMPS 版本: $LMP_VERSION"
            else
                die "Unsupported LAMMPS version: $LMP_VERSION"
            fi
        fi
    fi

    read_version_config
    load_version_package_hooks
    read_package_status
    apply_config_packages
    configure_interactive_inputs
    resolve_build_system
    select_module_lists
    configure_proxy_and_modules_interactive
    normalize_compiler_flags
    normalize_gpu_arch_options
    set_install_paths
    validate_config
    prune_incompatible_packages
    print_configuration
    print_removed_package_summary
    print_selected_dependency_summary
    write_build_config

    if [[ "$check_only" == "1" ]]; then
        if is_zh; then
            log "配置检查通过"
        else
            log "Configuration check passed"
        fi
        exit 0
    fi

    create_directories
    load_proxy
    load_build_modules
    post_module_checks
    create_compiler_wrappers
    prepare_external_libraries
    build_lammps
    write_modulefile

    if is_zh; then
        log "LAMMPS 编译成功"
        echo "可执行文件: ${LMP_PATH}/bin/lammps-${ACC_TYPE}"
        echo "Modulefile: ${LMP_PATH}/modulefile"
    else
        log "LAMMPS has been compiled successfully"
        echo "Binary: ${LMP_PATH}/bin/lammps-${ACC_TYPE}"
        echo "Modulefile: ${LMP_PATH}/modulefile"
    fi
}

main "$@"
