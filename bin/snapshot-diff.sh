#!/bin/bash
set -e
set -u
set -o pipefail

DOTFILE="${HOME}/.snapshot"

TMPDIR=${TMPDIR:-}
if [[ -z "${TMPDIR}" ]]; then
    TMPDIR="/tmp"
fi

TMP_DIRS=""
SNAPSHOT_A_XZ="${TMPDIR}/snapshot-a.tar.xz"
SNAPSHOT_A_DIR="${TMPDIR}/snapshot-a"
SNAPSHOT_A_TAR="${TMPDIR}/snapshot-a.tar"
SNAPSHOT_B_XZ="${TMPDIR}/snapshot-b.tar.xz"
SNAPSHOT_B_DIR="${TMPDIR}/snapshot-b"
SNAPSHOT_B_TAR="${TMPDIR}/snapshot-b.tar"

usage()
{
    echo "usage: $0 TARGET SNAPSHOTA SNAPSHOTB"
    echo "	SNAPSHOTB may be either a directory or a snapshot name."
}

do_cleanup()
{
    if [[ -z "${TMP_DIRS}" ]]; then
        rm -rf ${TMP_DIRS}
    fi
}
trap do_cleanup EXIT

do_extract_snapshot()
{
    local name="${1}"
    local src_archive="${SNAPSHOT_DIR}/${TARGET}/${name}.tar.xz"
    if [ ! -e "${src_archive}" ]; then
        echo "${name} does not exist."
        exit 5
    fi

    local tmp_path=$(mktemp -d)
    if [[ -z "${tmp_path}" ]]; then
        echo "mktemp failed"
        exit 6
    fi
    TMP_DIRS="${TMP_DIRS} ${tmp_path}"

    local dst_archive=$(basename ${src_archive})
    local tarball="${tmp_path}/${name}.tar"

    cd ${tmp_path}
    cp ${src_archive} ${dst_archive}
    xz -d -k -f ${dst_archive} > ${tarball}
    tar -C ${tmp_path} -x -f ${tarball}

    rm -f ${dst_archive}
    rm -f ${tarball}
}

TARGET=${1:-}
if [[ -z "${TARGET}" ]]; then
    usage
    exit 1
fi
TARGET=$(realpath ${TARGET})

SNAPSHOT_A=${2:-}
if [[ -z "${SNAPSHOT_A}" ]]; then
    usage
    exit 1
fi

SNAPSHOT_B=${3:-}
if [[ -z "${SNAPSHOT_B}" ]]; then
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

do_extract_snapshot "${SNAPSHOT_A}"

do_extract_snapshot "${SNAPSHOT_B}"

diff -ru ${SNAPSHOT_A} ${SNAPSHOT_B}
