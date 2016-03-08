CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
TMP_BRANCH=$1

git stash save "${TMP_BRANCH}" && git stash apply
git checkout -b ${TMP_BRANCH}
git add .
git commit -m "${TMP_BRANCH}"
git push alandovskis ${TMP_BRANCH}
git checkout ${CURRENT_BRANCH}
git merge ${TMP_BRANCH}
git reset HEAD^
