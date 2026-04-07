#!/usr/bin/env bash
#
# build.sh - Build the Old Javanese Wordnet package and Cygnet databases
#
# Usage: bash build.sh [--rebuild]
#   --rebuild   Wipe the cygnet work directory first (forces re-download of
#               all wordnets — use when wordnets.toml URLs have changed)
#
# Produces:
#   build/wnkaw-VERSION.tar.xz         — WordNet LMF package
#   docs/kaw-cygnet.db.gz              — Cygnet main database
#   docs/kaw-provenance.db.gz          — Cygnet provenance database
#
# Prerequisites: uv, curl, tar, xz, wget, xmlstarlet, python3

set -euo pipefail

VERSION="2026.03.14"
DTD="WN-LMF-1.4.dtd"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
CYGNET_DIR="$(cd "$PROJECT_DIR/../cygnet" && pwd)"
CYGNET_WORK="$PROJECT_DIR/build/cygnet-work"

if [[ "${1:-}" == "--rebuild" ]]; then
    echo "Cleaning cygnet work directory for full rebuild..."
    rm -rf "$CYGNET_WORK"
fi

# Old Javanese	kaw	https://github.com/davidmoeljadi/OJW	CC BY 4.0
mkdir -p external
if [ ! -d external/cili ]; then
    echo "Retrieving ILI map"
    git clone https://github.com/globalwordnet/cili.git external/cili
fi

if [ ! -d external/omw-data ]; then
    echo "Retrieving omw-data"
    git clone https://github.com/omwn/omw-data.git external/omw-data
fi

if [ ! -f "external/${DTD}" ]; then
    echo "Retrieving DTD"
    wget "https://globalwordnet.github.io/schemas/${DTD}" -O "external/${DTD}"
fi

uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt

citation=$(sed -r -e '/^$/d' -e 's/\s+$//' etc/citation.rst)

NAME="wnkaw-${VERSION}"
DIR="build/$NAME"

echo "Preparing package directory"
mkdir -p "$DIR"
cp README.md "$DIR"
cp LICENSE "$DIR"
cp etc/citation.bib "$DIR"

DESCRIPTION="The Old Javanese Wordnet (Moeljadi and Aminullah, 2020) is built using the data from the digitized version of the Old Javanese–English Dictionary (Zoetmulder, 1982). This wordnet is built using the 'expand' approach (Vossen, 1998), leveraging on the Princeton Wordnet's core synsets and semantic hierarchy, as well as scientific names."

echo "Building wordnet"
DESTINATION="${DIR}/${NAME}.xml"
pushd external/omw-data/scripts
python3 tsv2lmf.py \
	  "$OLDPWD/wn-kaw.tab" \
	  "$OLDPWD/$DESTINATION" \
	  --id='wnkaw' \
	  --label='Old Javanese Wordnet' \
	  --language='kaw' \
	  --version="$VERSION" \
	  --email='davidmoeljadi@gmail.com' \
	  --license='https://creativecommons.org/licenses/by/4.0/' \
	  --url="https://github.com/davidmoeljadi/OJW" \
	  --citation="${citation}" \
	  --requires=omw-en:2.0 \
	  --ili-map="$OLDPWD/external/cili/ili-map-pwn30.tab" \
	  --log="$OLDPWD/build/build.log"
popd

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
	   -t attr -n dc:description -v "${DESCRIPTION}" "${DESTINATION}"

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
	   -t attr -n confidenceScore -v '1.0' "${DESTINATION}"

echo "Validating"
xmlstarlet val -e -d "external/${DTD}" "$DESTINATION"

echo "Archiving the package"
tar -c -J -f "build/${NAME}.tar.xz" "$DIR"

# ============================================================
# CYGNET DATABASE BUILD
# ============================================================
echo ""
echo "=== Building Cygnet databases ==="

mkdir -p "$CYGNET_WORK/bin/raw_wns"

# Use the project's wordnets.toml (pre-place so the download step skips kaw).
cp "$PROJECT_DIR/etc/wordnets.toml" "$CYGNET_WORK/wordnets.toml"
cp "$PROJECT_DIR/$DESTINATION" "$CYGNET_WORK/bin/raw_wns/${NAME}.xml"

bash "$CYGNET_DIR/build.sh" --work-dir "$CYGNET_WORK"

# Deploy web UI and databases to docs/ for GitHub Pages / local testing.
echo "Deploying to docs/"
mkdir -p "$PROJECT_DIR/docs"
cp "$CYGNET_DIR/web/index.html"          "$PROJECT_DIR/docs/"
cp "$CYGNET_DIR/web/relations.json"      "$PROJECT_DIR/docs/"
cp "$CYGNET_DIR/web/omw-logo.svg"        "$PROJECT_DIR/docs/" 2>/dev/null || true
cp "$PROJECT_DIR/etc/local.json"         "$PROJECT_DIR/docs/"
cp "$CYGNET_WORK/web/cygnet.db.gz"       "$PROJECT_DIR/docs/kaw-cygnet.db.gz"
cp "$CYGNET_WORK/web/provenance.db.gz"   "$PROJECT_DIR/docs/kaw-provenance.db.gz"

echo ""
echo "=== Build complete ==="
echo "  build/${NAME}.tar.xz               — wordnet package"
echo "  docs/kaw-cygnet.db.gz               — Cygnet main database"
echo "  docs/kaw-provenance.db.gz    — Cygnet provenance database"
echo "  docs/                              — web UI (run with: bash run.sh)"
