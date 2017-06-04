#!/bin/bash
set -e
set -u
set -o pipefail
IFS=$'\n\t'

DOTFILE="${HOME}/.snapshot"

usage()
{
    echo "usage: $0 TARGET"
}

TARGET=${1:-}
if [[ -z "${TARGET}" ]]; then
    usage
    exit 1
fi

if [ ! -r "${DOTFILE}" ]; then
    echo "${DOTFILE} was not found."
    exit 2
fi

source ${DOTFILE}
SNAPSHOT_DIR=${SNAPSHOT_DIR:-}
if [[ -z "$SNAPSHOT_DIR" ]]; then
    echo "SNAPSHOT_DIR not found in ${DOTFILE}"
    exit 3
fi

TARGET=$(realpath ${TARGET})
SNAPSHOT_PATH="${SNAPSHOT_DIR}/${TARGET}"

if [ ! -d "${SNAPSHOT_PATH}" ]; then
    echo "No snapshots found for ${TARGET}"
    exit 0
fi

ls ${SNAPSHOT_PATH} | sed 's/\.tar\..*//g'
