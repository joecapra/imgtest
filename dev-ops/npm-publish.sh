cd ..

# ensure branch build-source version is package version
node ./dev-ops/version-sync.js --package package.json --bsToPkg
CURRENT_VERSION=`node -pe "require('./package.json').version"`

# prompt next version
npx bump package.json
RELEASE_VERSION=`node -pe "require('./package.json').version"`

# propagate next version back to build-source
# but restore the package-version to current,
# so the NP package doesn't insist on a new version :o
node ./dev-ops/version-sync.js --package package.json --pkgToBs --setPkg $CURRENT_VERSION

# update package name
BRANCH=`git rev-parse --abbrev-ref HEAD`
node ./dev-ops/set-package-name.js --package package.json --branch $BRANCH --version $RELEASE_VERSION

# commit updates to package
git add package.json
git commit -m 'updates build-source info'
git push

# get release name
PKG_NAME=`node -pe "require('./package.json').name"`
# prompt next version and publish to npm
NPM_RELEASE="$RELEASE_VERSION-$BRANCH"
np $NPM_RELEASE --tag=$BRANCH --any-branch --no-release-draft --no-2fa || exit $?

# note
echo
echo "Done.\033[1;31m Be sure to update BSA's version reference! \033[0m"
echo " https://github.com/ff0000-tech/build-source-assembler/blob/master/package.json"
echo "  \"buildSources\": {"
echo "    ..."
echo "    \033[1;32m\"$PKG_NAME\": \"$NPM_RELEASE\" \033[0m"
echo "    ..."
echo "  }"