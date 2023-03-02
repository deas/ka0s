#!/bin/sh

name=ka0s
domain=contentreich.de

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
key_dir="$(dirname $dir_path)/keys"

[ -d "${key_dir}" ] || mkdir -p "${key_dir}"
ssh-keygen -N "" -C "${name}" -f "${key_dir}/id_rsa-${name}"
