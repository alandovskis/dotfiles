CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
TMP_BRANCH=$1
REMOTE=alandovskis

git stash save "${TMP_BRANCH}" && git stash apply
git checkout -b ${TMP_BRANCH}
git add .
git commit -m "${TMP_BRANCH}"

git ls-remote ${REMOTE} >/dev/null 2>&1 && git push ${REMOTE} ${TMP_BRANCH}
git checkout ${CURRENT_BRANCH}
git merge ${TMP_BRANCH}
git reset HEAD^
