#!/bin/bash
set -e
set -u
set -o pipefail
IFS=$'\n\t'

DOTFILE="${HOME}/.snapshot"
IGNORE_FILE="/tmp/snapshot.ignores"
TMP_FILE="/tmp/snapshot.tmp"

usage()
{
    echo "usage: $0 TARGET NAME"
}

do_prep_ignores()
{
    local gitignores=$(find ${TARGET} -name '.gitignore')
    local gitignore=""

    local oifs=${IFS}
    IFS=$' \n\t'
    echo ".git" > ${IGNORE_FILE}
    for gitignore in ${gitignores}; do
        local pre=$(dirname ${gitignore})

        cat ${gitignore} | sed '/^#/d' | sed '/^$/d' > ${TMP_FILE}
        while read -r line
        do
            echo "${pre}/${line}" >> ${IGNORE_FILE}
        done < "${TMP_FILE}"

        rm -f ${TMP_FILE}
    done

    IFS=${oifs}
}

do_snapshot()
{
    local snapshot_path="${SNAPSHOT_DIR}/${TARGET}"
    local snapshot_tar="${snapshot_path}/${NAME}.tar"
    local snapshot_file="${snapshot_tar}.xz"

    mkdir -p ${snapshot_path}

    if [ -e "${snapshot_file}" ]; then
        echo "Snapshot ${NAME} already exists. Choose a unique name."
        exit 4
    fi

    tar -X ${IGNORE_FILE} -c -v -f ${snapshot_tar} ${TARGET}
    xz -c ${snapshot_tar} > ${snapshot_file}
}

do_cleanup()
{
    rm -rf ${TMP_FILE}
    rm -rf ${IGNORE_FILE}
}
trap do_cleanup EXIT

TARGET=${1:-}
if [[ -z "${TARGET}" ]]; then
    usage
    exit 1
fi

NAME=${2:-}
if [[ -z "${NAME}" ]]; then
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

do_prep_ignores
do_snapshot
