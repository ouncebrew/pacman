# ounce pacman repository

The `[ounce]` repository for devkitPro's pacman: libounce, OunceVK and
libkaihen, the Switch 2 devkit's libraries, signed, at <https://pkg.ouncebrew.org>.

## Use

Import the signing key once:

```sh
curl -fsSLO https://pkg.ouncebrew.org/ounce.gpg
sudo dkp-pacman-key --add ounce.gpg
sudo dkp-pacman-key --lsign-key DFEAE7FA965D1E6C0D41D4D75DB9FDBFA4A4DE29
```

Add the repository to `/opt/devkitpro/pacman/etc/pacman.conf`:

```ini
[ounce]
Server = https://pkg.ouncebrew.org
```

Then install, and update as with devkitPro's own packages:

```sh
sudo dkp-pacman -Sy libounce ouncevk libkaihen
sudo dkp-pacman -Syu
```

## How it is updated

`sources` pins the release of each package: a repository and its release
tag. Each source repository builds its package and attaches it to the
release when a version tag is pushed. To publish it, change that release's
line in `sources` and push: the `Update` workflow signs the pinned packages
that the repository does not have yet, adds them to the database with
`dkp-repo-add`, and uploads them to the R2 bucket behind pkg.ouncebrew.org.
Pinning an older release puts that version back.

## License

MIT (`LICENSE`).
