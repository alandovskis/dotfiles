#!/bin/bash
set -e
set -u
set -o pipefail
IFS=$'\n\t'

DOTFILE="${HOME}/.snapshot"

TMPDIR=${TMPDIR:-}
if [[ -z "${TMPDIR}" ]]; then
    TMPDIR="/tmp"
fi

SNAPSHOT_A_XZ="${TMPDIR}/snapshot-a.tar.xz"
SNAPSHOT_A_DIR="${TMPDIR}snapshot-a"
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
    rm -rf ${SNAPSHOT_A_XZ}
    rm -rf ${SNAPSHOT_A_TAR}
    rm -rf ${SNAPSHOT_A_DIR}
    rm -rf ${SNAPSHOT_B_XZ}
    rm -rf ${SNAPSHOT_B_TAR}
    rm -rf ${SNAPSHOT_B_DIR}
}
trap do_cleanup EXIT

TARGET=${1:-}
if [[ -z "${TARGET}" ]]; then
    usage
    exit 1
fi

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

SNAPSHOT_DIFFER=${SNAPSHOT_DIFFER:-}
if [[ -z "$SNAPSHOT_DIFFER" ]]; then
    echo "SNAPSHOT_DIFFER not found in ${DOTFILE}"
    exit 3
fi

SNAPSHOT_A_PATH="${SNAPSHOT_DIR}/${TARGET}/${SNAPSHOT_A}.tar.xz"
if [ ! -e "${SNAPSHOT_A_PATH}" ]; then
    echo "${SNAPSHOT_A} does not exist."
    exit 5
fi

cd ${TMPDIR}
cp ${SNAPSHOT_A_PATH} ${SNAPSHOT_A_XZ}
xz -d -f ${SNAPSHOT_A_XZ} > ${SNAPSHOT_A_TAR}
mkdir -p ${SNAPSHOT_A_DIR}
tar -C ${SNAPSHOT_A_DIR} -x -v -f ${SNAPSHOT_A_TAR}
cd -
SNAPSHOT_A="${SNAPSHOT_A_DIR}/${TARGET}"

SNAPSHOT_B_PATH="${SNAPSHOT_DIR}/${TARGET}/${SNAPSHOT_B}.tar.xz"
if [ ! -e "${SNAPSHOT_B_PATH}" ]; then
    echo "${SNAPSHOT_B} does not exist."
    exit 5
fi

cd ${TMPDIR}
cp ${SNAPSHOT_B_PATH} ${SNAPSHOT_B_XZ}
xz -d -f ${SNAPSHOT_B_XZ} > ${SNAPSHOT_B_TAR}
mkdir -p ${SNAPSHOT_B_DIR}
tar -C ${SNAPSHOT_B_DIR} -x -v -f ${SNAPSHOT_B_TAR}
cd -
SNAPSHOT_B="${SNAPSHOT_B_DIR}/${TARGET}"

${SNAPSHOT_DIFFER} ${SNAPSHOT_A} ${SNAPSHOT_B}
