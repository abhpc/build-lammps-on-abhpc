# Repository Guidelines

## Project Structure & Module Organization

This repository contains Bash tooling for building LAMMPS on ABHPC:

- `build-lmp.sh`: interactive build script. It selects a LAMMPS release, checks or installs external libraries, enables packages, builds the binary, and writes a modulefile.
- `path.conf`: install paths and compiler flags consumed by `build-lmp.sh`.
- Version directories such as `23Jun2022/` and `22Jul2025_update4/`: release-specific package metadata and hooks. `package.list` is the inventory, `package.sta` marks packages enabled with `YES`, and `packages.sh` contains version-specific package build functions.
- `README.md`: short user-facing setup notes.

When adding a LAMMPS version, create a sibling directory such as `8Aug2023/` with matching package files and a `packages.sh` hook file.

## Build, Test, and Development Commands

- `bash -n build-lmp.sh`: syntax-check the script without downloads or compilation.
- `./build-lmp.sh`: run the ABHPC build. It loads proxy settings when available, loads modules, downloads missing dependencies, builds LAMMPS, and installs under `~/apps/lammps/<version>` by default.
- `./build-lmp.sh --check 23Jun2022`: validate configuration and package metadata without downloading or compiling.
- `JN=20 ./build-lmp.sh 22Jul2025_update4`: set the build job count explicitly; interactive runs prompt for this value and default to 20.
- `sed -n '1,120p' path.conf`: inspect current install paths before running a build.
- `git diff -- build-lmp.sh path.conf 23Jun2022/package.sta`: review build-affecting changes before committing.

The build script expects ABHPC module commands and Intel oneAPI/MPI tooling. Avoid running it on machines without that environment.

## Coding Style & Naming Conventions

Use Bash and keep scripts executable. Prefer uppercase names for exported or build-wide settings, matching `LMP_VERSION`, `VORONOI_PATH`, and `JN`. Quote variable expansions that may contain paths or flags. Keep release package files named `package.list` and `package.sta`; package names should stay uppercase to match LAMMPS.

## Testing Guidelines

There is no formal test suite. At minimum, run `bash -n build-lmp.sh` and `./build-lmp.sh --check 23Jun2022` after script edits. For package changes, verify `package.sta` contains only names from the matching `package.list`. For real validation, run `./build-lmp.sh` on ABHPC and confirm the binary appears under `~/apps/lammps/<version>/bin/`.

## Commit & Pull Request Guidelines

Recent commits use short, lowercase messages such as `update build-lmp.sh` and `check eigen`. Keep messages concise and scoped.

Pull requests should describe the target LAMMPS version, changed packages, modified paths or flags, and whether `bash -n build-lmp.sh` or a full ABHPC build was run. Link related issues when available.

## Security & Configuration Tips

Do not commit site-specific secrets or credentials. Treat `path.conf` as cluster configuration and review path changes carefully, especially overrides outside `~/apps`. Downloads use fixed HTTP endpoints; document the source when changing mirrors.
