# Old Javanese Wordnet

The Old Javanese Wordnet (OJW) is a lexical resource for Old Javanese, built
from vocabulary extracted from the digitised *Old Javanese–English Dictionary*
(Zoetmulder, 1982).  It uses the Princeton WordNet synset hierarchy as a
backbone and is linked to English and Indonesian.

The resource is developed by David Moeljadi and Zakariya Pamuji Aminullah.

Browse the wordnet at **[davidmoeljadi.github.io/OJW](https://davidmoeljadi.github.io/OJW)**
or download the databases from the [latest release](https://github.com/davidmoeljadi/OJW/releases/latest).

---

## Raw data format

The source data is in `wn-kaw.tab`, one entry per line:

```
synset<TAB>lemma<TAB>variants
```

`synset` is the offset-pos from Princeton WordNet 3.0.

```
09815790-n	pariwṛta	pariwṛtta, pariwarta
00460735-a	ahĕniṅ	mahĕniṅ, ahniṅ
01332730-v	tumutupi
```

---

## Building

The build script produces a WordNet LMF XML package and two Cygnet SQLite
databases, then deploys the web UI to `docs/` for GitHub Pages.

### Prerequisites

- [uv](https://github.com/astral-sh/uv)
- `curl`, `tar`, `xz`, `wget`, `xmlstarlet`, `python3`
- `libxml2-dev`, `libxslt-dev`
- The [cygnet](https://github.com/rowanhm/cygnet) repository checked out as a
  sibling directory: `../cygnet`

```bash
# Debian/Ubuntu
sudo apt-get install -y curl tar xz-utils wget xmlstarlet libxml2-dev libxslt-dev

# macOS
brew install curl wget xmlstarlet libxml2 libxslt
```

### Full build

```bash
bash build.sh
```

This:

1. Clones required external data (CILI map, OMW scripts) into `external/`
2. Converts `wn-kaw.tab` to WordNet LMF XML and validates it against the DTD
3. Packages the XML as `build/wnkaw-VERSION.tar.xz`
4. Calls cygnet's build pipeline to produce two gzipped SQLite databases
5. Copies the web UI and databases to `docs/`

### Outputs

| File | Description |
|---|---|
| `build/wnkaw-VERSION.tar.xz` | WordNet LMF package (for release) |
| `docs/kaw-cygnet.db.gz` | Main Cygnet database — synsets, senses, forms, relations |
| `docs/kaw-provenance.db.gz` | Provenance database — per-row source attribution |
| `docs/index.html` etc. | Web UI (for GitHub Pages) |

### Local testing

```bash
bash run.sh
```

Opens `http://localhost:8801` (or similar) serving `docs/` — the full web UI
with the locally-built databases.

---

## Releases

Releases are tagged `YYYY.MM.DD` and include three assets:

| Asset | Contents |
|---|---|
| `wnkaw-VERSION.tar.xz` | WordNet LMF XML package |
| `kaw-cygnet.db.gz` | Main Cygnet database |
| `kaw-provenance.db.gz` | Provenance database |

To create a release:

```bash
git tag 2026.03.14
git push origin 2026.03.14

gh release create 2026.03.14 \
  --title "OJW 2026.03.14" \
  --notes "Description of changes." \
  docs/kaw-cygnet.db.gz \
  docs/kaw-provenance.db.gz \
  build/wnkaw-2026.03.14.tar.xz
```

The live web UI at `davidmoeljadi.github.io/OJW` fetches the databases from the
latest release automatically.

---

## Web interface

The web UI (`docs/index.html`) is the
[Cygnet](https://github.com/rowanhm/cygnet) browser, configured for OJW via
`docs/local.json`.  It runs entirely in the browser using
[sql.js](https://sql.js.org/) — no server-side component is needed.

Configuration is in `etc/local.json`; the build script copies it to `docs/`.
See [`cygnet/CUSTOMIZE.md`](../cygnet/CUSTOMIZE.md) for full documentation on
all available `local.json` fields.

---

## Citation

If you use the Old Javanese Wordnet, please cite:

> David Moeljadi and Zakariya Pamuji Aminullah (2020).
> [Building the Old Javanese Wordnet](https://aclanthology.org/2020.lrec-1.359/).
> In *Proceedings of LREC 2020*, pages 2940–2946. ELRA.

For the web interface, please cite:

> Rowan Hall Maudslay and Francis Bond (2026).
> Cygnet: A merged multilingual wordnet browser.

---

## Licence

The Old Javanese Wordnet data is released under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
