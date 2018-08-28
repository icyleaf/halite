#!/usr/bin/env sh

DOCS_PATH="docs"
TAGS=$(git tag -l)
DEFAULT_VERSION=$(git tag --merged master | sort | tail -n 1)
DEFAULT_VERSION=$(echo $DEFAULT_VERSION | awk '{gsub(/^v/, ""); print}')

# Clean up
rm -rf $DOCS_PATH
mkdir -p $DOCS_PATH

# Generate master docs
COMMIT_DATE=$(git log -1 --format=%ci)
MASTER_COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_STATUS="[#${MASTER_COMMIT_HASH}](${GH_REF}/commit/${MASTER_COMMIT_HASH})"
sed -i -e "s/latest commit/$(echo ${COMMIT_STATUS} | sed -e "s/\//\\\\\//g") (${COMMIT_DATE})/" README.md
crystal docs --output="${DOCS_PATH}/master"
git reset --hard

# Generate version docs
for TAG in $TAGS; do
  NAME=$(echo $TAG | awk '{gsub(/^v/, ""); print}')
  git checkout -b $NAME $TAG

  COMMIT_STATUS="[${TAG}](${GH_REF}/blob/master/CHANGELOG.md)"
  sed -i -e "s/latest commit/$(echo ${COMMIT_STATUS} | sed -e "s/\//\\\\\//g")/" README.md
  crystal docs --output="${DOCS_PATH}/${NAME}"
  git reset --hard
  git checkout master
  git branch -d $NAME
done

echo "<html>
<header>
  <meta http-equiv='Refresh' content='0; url='${GH_URL}/${DEFAULT_VERSION}/' />
  <script language='javascript' type='text/javascript'>
    window.location.href='${GH_URL}/${DEFAULT_VERSION}/';
  </script>
</header>
<body>
<p><a href='${GH_URL}/${DEFAULT_VERSION}/'>Redirect to ${DEFAULT_VERSION}</a></p>
</body>
</html>" > "${DOCS_PATH}/index.html"
