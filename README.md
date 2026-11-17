# ounce pacman repository

The `[ounce]` repository for devkitPro's pacman: libounce, OunceVK and
libkaihen, the Switch 2 devkit's libraries, signed, at <https://pkg.ouncebrew.org>.

## Use

Import the signing key once:

```sh
curl -fsSLO https://pkg.ouncebrew.org/ounce.gpg
sudo dkp-pacman-key --add ounce.gpg
sudo dkp-pacman-key --lsign-key FINGERPRINT
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

Each source repository listed in `sources` publishes its package as a
GitHub release when a version tag is pushed. The `Update` workflow runs
every 30 minutes and by hand: `update.sh` signs the latest releases'
packages that the repository does not have yet, adds them to the database
with `dkp-repo-add`, and the workflow uploads them to the R2 bucket behind
pkg.ouncebrew.org.

## License

MIT (`LICENSE`).
