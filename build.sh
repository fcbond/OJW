#!/bin/bash

uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt


VERSION="2026.03.14"
DTD="WN-LMF-1.4.dtd"

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

if [ ! -f external/"${DTD}" ]; then
    echo "Retrieving DTD"
    wget "https://globalwordnet.github.io/schemas/${DTD}" -O external/"$DTD"
fi

citation=$( sed -r -e '/^$/d' -e 's/\s+$//' etc/citation.rst )

NAME="wnkaw-${VERSION}"
DIR="build/$NAME"

echo "Preparing package directory"
mkdir -p "$DIR"
cp README.md "$DIR"
cp LICENSE "$DIR"
cp etc/citation.bib "$DIR"

DESCRIPTION="The Old Javanese Wordnet (Moeljadi and Aminullah, 2020) is built using the data from the digitized version of the Old Javanese–English Dictionary (Zoetmulder, 1982). This wordnet is built using the ‘expand’ approach (Vossen, 1998), leveraging on the Princeton Wordnet’s core synsets and semantic hierarchy, as well as scientific names."

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
	  --requires=omw-en:1.4 \
	  --ili-map="$OLDPWD/external/cili/ili-map-pwn30.tab" \
	  --log="$OLDPWD/build/build.log"
popd

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
	   -t attr -n dc:description -v "${DESCRIPTION}"  "${DESTINATION}"

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
	   -t attr -n confidenceScore -v '1.0'  "${DESTINATION}"


# ensure the xml is valid
echo "Validating"
xmlstarlet val -e -d external/"$DTD" "$DESTINATION"

# archive the package
echo "Archiving the package"
tar -c -J -f "build/${NAME}.tar.xz" "$DIR"
