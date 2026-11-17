#!/bin/sh
# SPDX-License-Identifier: MIT
#
# Adds the packages of the releases that `sources` pins to the [ounce] pacman
# repository. Runs in devkitPro's image (dkp-repo-add) with the signing key
# imported into GnuPG:
#   SIGNING_KEY=FINGERPRINT sh update.sh
# It reads the repository's current database from REPO_URL and writes what
# must be uploaded to upload/: each new package, its signature, and the
# database and file lists with their signatures. upload/ stays empty when the
# database already has every pinned package.
#
# Environment:
#   SIGNING_KEY   the signing key's fingerprint
#   GITHUB_TOKEN  read the releases with this token (optional)
#   REPO_URL      default https://pkg.ouncebrew.org
set -eu

SIGNING_KEY="${SIGNING_KEY:?set SIGNING_KEY to the signing key fingerprint}"
REPO_URL="${REPO_URL:-https://pkg.ouncebrew.org}"
REPO=ounce
here=$(cd "$(dirname "$0")" && pwd)
work="$here/work"
upload="$here/upload"
rm -rf "$work" "$upload"
mkdir -p "$work" "$upload"

# A GitHub API request.
github() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/$1"
    else
        curl -fsSL "https://api.github.com/$1"
    fi
}

# The current database, or none for the first update.
if curl -fsSL -o "$work/$REPO.db.tar.gz" "$REPO_URL/$REPO.db"; then
    curl -fsSL -o "$work/$REPO.files.tar.gz" "$REPO_URL/$REPO.files"
else
    rm -f "$work/$REPO.db.tar.gz"
    echo "No database at $REPO_URL: starting a new repository."
fi

# The packages of each pinned release that the database does not have yet.
while read -r source version; do
    case "$source" in '' | '#'*) continue ;; esac
    github "repos/$source/releases/tags/${version:?no release tag for $source}" |
        jq -r '.assets[] | select(.name | endswith(".pkg.tar.zst")) | .browser_download_url' |
    while read -r url; do
        package=$(basename "$url")
        entry=${package%-any.pkg.tar.zst}
        if [ -f "$work/$REPO.db.tar.gz" ] &&
            tar -tzf "$work/$REPO.db.tar.gz" | grep -qx "$entry/"; then
            continue
        fi
        echo "== $source: $package"
        curl -fsSL -o "$upload/$package" "$url"
        (cd "$upload" && curl -fsSL "$url.sha256" | sha256sum -c -)
        gpg --batch --yes --local-user "$SIGNING_KEY" --detach-sign \
            --output "$upload/$package.sig" "$upload/$package"
        echo "$package" >> "$work/new"
    done
done < "$here/sources"

if [ ! -s "$work/new" ]; then
    echo "No new packages."
    rm -rf "$upload"
    mkdir "$upload"
    exit 0
fi

# repo-add finds the packages next to the database.
cd "$work"
while read -r package; do
    ln -s "$upload/$package" "$package"
    ln -s "$upload/$package.sig" "$package.sig"
done < new
dkp-repo-add --sign --key "$SIGNING_KEY" --verify "$REPO.db.tar.gz" $(cat new)

# The server has no symbolic links: upload/ gets the database under both
# names, as repo-add links them.
for name in db files; do
    cp "$REPO.$name.tar.gz" "$upload/$REPO.$name.tar.gz"
    cp "$REPO.$name.tar.gz.sig" "$upload/$REPO.$name.tar.gz.sig"
    cp "$REPO.$name.tar.gz" "$upload/$REPO.$name"
    cp "$REPO.$name.tar.gz.sig" "$upload/$REPO.$name.sig"
done
gpg --batch --export --armor "$SIGNING_KEY" > "$upload/$REPO.gpg"
ls -l "$upload"
