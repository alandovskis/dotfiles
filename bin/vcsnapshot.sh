SNAPSHOT_BRANCH=""
SNAPSHOT_MESSAGE=""
SNAPSHOT_REMOTE=""
TIMESTAMP=$(date "+%Y%m%d.%H%M%S")

function usage()
{
    echo "Usage: $0 [ -b <branch> -r <remote> ] -m <message>"
}

function fatal()
{
    echo $1
    exit 1
}

function do_git()
{
    SNAPSHOT_TARGET=""
    DIRTY_WORKING_DIR=0

    [ $(git status -s | wc -l | tr -d '') -gt 0 ] && DIRTY_WORKING_DIR=1

    if [ ${DIRTY_WORKING_DIR} -eq 1 ]
    then
        git stash save -u "${SNAPSHOT_MESSAGE}" >/dev/null 2>&1 || fatal "Error: Unable to save stash."
        SNAPSHOT_TARGET="stash@{0}"
    fi

    git rev-parse --verify ${SNAPSHOT_BRANCH} >/dev/null 2>&1 && SNAPSHOT_BRANCH="${SNAPSHOT_BRANCH}-${TIMESTAMP}"
    git branch ${SNAPSHOT_BRANCH} ${SNAPSHOT_TARGET} >/dev/null 2>&1 || fatal "Error: Unable to create branch."

    if [ ${DIRTY_WORKING_DIR} -eq 1 ]
    then
        git stash pop >/dev/null 2>&1 || fatal "Error: Unable to pop stash."
    fi

    git ls-remote ${SNAPSHOT_REMOTE} >/dev/null 2>&1 && git push ${SNAPSHOT_REMOTE} ${SNAPSHOT_BRANCH} >/dev/null 2>&1
}

while getopts ":b:m:r:" opt
do
    case $opt in
        b)
            SNAPSHOT_BRANCH="${OPTARG}"
            ;;
        m)
            SNAPSHOT_MESSAGE="${OPTARG}"
            ;;
        r)
            SNAPSHOT_REMOTE="${OPTARG}"
            ;;
        \?)
            usage
            exit 1
            ;;
        :)
            echo "-${OPTARG} requires an argument."
            exit 1
            ;;
        esac
done

if [ "${SNAPSHOT_MESSAGE}" = "" ]
then
    echo "-m is required"
    usage
    exit 1
fi

if [ "${SNAPSHOT_BRANCH}" = "" ]
then
    SNAPSHOT_BRANCH="${SNAPSHOT_MESSAGE}"
fi

if [ "${SNAPSHOT_REMOTE}" = "" ]
then
    SNAPSHOT_REMOTE=alandovskis
fi

do_git
