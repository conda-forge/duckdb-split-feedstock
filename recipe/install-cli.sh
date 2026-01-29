#!/bin/bash

set -exuo pipefail

mkdir -p $PREFIX/bin
cp build/dist/bin/duckdb $PREFIX/bin/

if [[ "${target_platform}" == osx-* ]]; then
    codesign --sign - --force --entitlements ${RECIPE_DIR}/entitlements.plist $PREFIX/bin/duckdb
    codesign -d --entitlements :- $PREFIX/bin/duckdb
    codesign -dv --verbose=4 $PREFIX/bin/duckdb
fi

