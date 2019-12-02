#!/bin/bash
set -euo pipefail

TMPDIST="$(mktemp -d)"
USERBASE="$(mktemp -d)"
trap "rm -rf '$TMPDIST' '$USERBASE'" EXIT

for pybin in /opt/python/cp{27,35,36,37,38}-cp*/bin; do
    "${pybin}/pip" wheel --no-cache-dir -w "$TMPDIST" "." "pytest"
done

for whl in "$TMPDIST"/blurhash_python*.whl; do
    auditwheel repair "$whl" --plat "$PLAT" -w dist
    rm "$whl"
done

ORIGPATH="$PATH"

for pybin in /opt/python/cp{27,35,36,37,38}-cp*/bin; do
    userbindir="$USERBASE/${pybin#/opt/python/}"
    export PYTHONUSERBASE="${userbindir%/bin}"
    export PATH="$ORIGPATH:$userbindir"
    "${pybin}/pip" install --no-cache-dir --user --no-index -f dist -f "$TMPDIST" "blurhash-python" "pytest"
    "${userbindir}/pytest"
done
