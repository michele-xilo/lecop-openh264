#!/bin/sh
# Assembles the x86_64 sources in upstream/ into <out>/<format>/<lib>/<name>.o (default: prebuilt/) so the crate
# builds without nasm. CI re-runs this with the pinned nasm and fails if the committed objects differ.
set -eu
out=${1:-prebuilt}
cd "$(dirname "$0")"
rm -rf "$out"
for target in "elf64 UNIX64" "win64 WIN64" "macho64 UNIX64 -DPREFIX"; do
  set -- $target
  fmt=$1; shift
  for root in common:upstream/codec/common decoder:upstream/codec/decoder processing:upstream/codec/processing encoder:upstream/codec/encoder; do
    lib=${root%%:*}; dir=${root#*:}
    mkdir -p "$out/$fmt/$lib"
    find "$dir" -path '*/x86/*.asm' ! -name asm_inc.asm | sort | while read -r f; do
      # Same-named sources exist in several directories of one library, so keep the parent path in the object name.
      name=$(echo "${f#$dir/}" | tr '/' '_' | sed 's/\.asm$//')
      nasm -f "$fmt" -I upstream/codec/common/x86/ -D"$1" ${2:-} -w-all "$f" -o "$out/$fmt/$lib/$name.o"
    done
  done
done
