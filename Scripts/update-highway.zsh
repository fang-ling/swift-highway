#!/bin/zsh

##
##  update-highway.zsh
##  swift-highway
##
##  Created by Fang Ling on 2026/3/14.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
##

# This script creates a copy of highway that is suitable for building with the
# Swift Package Manager.
#
# Usage:
#   Run this script in the package root. It will place a local copy of the
#   highway sources in Sources/CHighway.
#   Any prior contents of Sources/CHighway will be deleted.
#

set -euo pipefail

CURRENT_WORKING_DIRECTORY=$(pwd)
TEMPORARY_DIRECTORY=$(mktemp -d /tmp/swift-highway-XXXXXX)
SOURCE_DIRECTORY="${TEMPORARY_DIRECTORY}/Sources/highway"
DESTINATION_DIRECTORY="Sources/CHighway"
TRASH_DIRECTORY="${TEMPORARY_DIRECTORY}/Trash"
SOURCES=(
  "*.cc"
  "*.h"
  "ops/*.h"
)
EXCLUDES=(
  "abort_header_only_test.cc"
  "abort_test.cc"
  "aligned_allocator_test.cc"
  "auto_tune_test.cc"
  "base_test.cc"
  "bit_set_test.cc"
  "highway_test.cc"
  "nanobenchmark_test.cc"
  "perf_counters_test.cc"
  "targets_test.cc"
)
PUBLIC_HEADERS=(
  "abort.h"
  "aligned_allocator.h"
  "auto_tune.h"
  "base.h"
  "cache_control.h"
  "detect_compiler_arch.h"
  "detect_targets.h"
  "foreach_target.h"
  "highway_export.h"
  "highway.h"
  "nanobenchmark.h"
  "per_target.h"
  "print-inl.h"
  "print.h"
  "profiler.h"
  "robust_statistics.h"
  "targets.h"
  "timer-inl.h"
  "timer.h"
  "x86_cpuid.h"
  "ops/arm_neon-inl.h"
  "ops/arm_sve-inl.h"
  "ops/emu128-inl.h"
  "ops/generic_ops-inl.h"
  "ops/inside-inl.h"
  "ops/loongarch_lasx-inl.h"
  "ops/loongarch_lsx-inl.h"
  "ops/ppc_vsx-inl.h"
  "ops/rvv-inl.h"
  "ops/scalar-inl.h"
  "ops/set_macros-inl.h"
  "ops/shared-inl.h"
  "ops/wasm_128-inl.h"
  "ops/x86_128-inl.h"
  "ops/x86_256-inl.h"
  "ops/x86_512-inl.h"
  "ops/x86_avx3-inl.h"
)

# Highway revision must be passed as the first argument to this script.
if [ "$#" -gt 0 ]; then
  HIGHWAY_REVISION="$1"
else
  echo "Usage: $0 <highway-revision>"
  exit 1
fi

echo "==========================================="
echo "TRASHING any previously-copied highway code"
echo "==========================================="
mkdir -p "${TRASH_DIRECTORY}/CHighway"
mv "${DESTINATION_DIRECTORY}/"* "${TRASH_DIRECTORY}/CHighway" || true

echo "================="
echo "PREPARING highway"
echo "================="
mkdir -p "${SOURCE_DIRECTORY}"
git clone https://github.com/google/highway.git "${SOURCE_DIRECTORY}"
cd "${SOURCE_DIRECTORY}"
git checkout "${HIGHWAY_REVISION}"
cd "${CURRENT_WORKING_DIRECTORY}"

echo "==============="
echo "COPYING highway"
echo "==============="
mkdir -p "${DESTINATION_DIRECTORY}/highway"
for SOURCE in "${SOURCES[@]}"
do
  for FILE in "${SOURCE_DIRECTORY}/hwy/"${~SOURCE}
  do
    FILE_PATH=${FILE#"$SOURCE_DIRECTORY"}
    DESTINATION="${DESTINATION_DIRECTORY}/highway${FILE_PATH}"
    mkdir -p $(dirname "${DESTINATION}")

    cp "${FILE}" "${DESTINATION}"
  done
done
for EXCLUDE in "${EXCLUDES[@]}"
do
  rm -rf "${DESTINATION_DIRECTORY}/highway/hwy/"${~EXCLUDE}
done
mkdir -p "${DESTINATION_DIRECTORY}/include/hwy"
mkdir -p "${DESTINATION_DIRECTORY}/include/hwy/ops"
for PUBLIC_HEADER in "${PUBLIC_HEADERS[@]}"
do
  mv \
    "${DESTINATION_DIRECTORY}/highway/hwy/${PUBLIC_HEADER}" \
    "${DESTINATION_DIRECTORY}/include/hwy/${PUBLIC_HEADER}"
done
cp "${SOURCE_DIRECTORY}/LICENSE" "${DESTINATION_DIRECTORY}/LICENSE.txt"

echo "========================="
echo "RECORDING highway revision"
echo "========================="
cat << EOF > "${DESTINATION_DIRECTORY}/revision.txt"
This directory is derived from highway
  cloned from https://github.com/google/highway.git
EOF
echo -n "at revision" >> "${DESTINATION_DIRECTORY}/revision.txt"
echo " ${HIGHWAY_REVISION}" >> "${DESTINATION_DIRECTORY}/revision.txt"

echo "============================"
echo "CLEANING temporary directory"
echo "============================"
rm -rf "${TEMPORARY_DIRECTORY}"
