# Patch workflow for MediaMTX (v1.14.0 and newer)

## 1) Create your patch commit on v1.14.0

```bash
git switch -c patch/srt-query-v1.14 v1.14.0
# edit files

git add internal/servers/srt/streamid.go internal/servers/srt/streamid_test.go
git commit -m "srt: <describe your patch>"
```

Save the patch commit SHA:

```bash
git rev-parse --short HEAD
```

## 2) Build patched v1.14.0

```bash
scripts/update-and-build.sh --patch-commit <SHA> --tag v1.14.0
```

## 3) Move patch to latest v1 release and build

```bash
scripts/update-and-build.sh --patch-commit <SHA> --latest-v1
```

## Notes

- Script requires a clean working tree.
- It creates a new branch `prod/<tag>-patched` from the target tag.
- If cherry-pick conflicts occur, resolve and continue with `git cherry-pick --continue`.
