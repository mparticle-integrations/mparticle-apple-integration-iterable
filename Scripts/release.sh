VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
#

# Update Carthage release json file
jq --indent 3 '. += {'"\"$VERSION\""': "'"https://github.com/mparticle-integrations/mparticle-apple-integration-iterable/releases/download/$PREFIXED_VERSION/mParticle_Iterable.framework.zip?alt=https://github.com/mparticle-integrations/mparticle-apple-integration-iterable/releases/download/$PREFIXED_VERSION/mParticle_Iterable.xcframework.zip"'"}'
mParticle_Iterable.json > tmp.json
mv tmp.json mParticle_Iterable.json

# Update CocoaPods podspec file
sed -i '' 's/\(^    s.version[^=]*= \).*/\1"'"$VERSION"'"/' mParticle-Iterable.podspec

# Make the release commit in git
#

git add mParticle-Iterable.podspec
git add mParticle_Iterable.json
git add CHANGELOG.md
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"
