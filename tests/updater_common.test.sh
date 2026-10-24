#!/bin/bash
# Offline check for updater release selection and version order. Needs jq. Run: bash tests/updater_common.test.sh
cd "$(dirname "$0")/.." || exit 1
log_message() { :; }
source docker/utils/updater_common.sh

fail=0
eq() { [ "$2" = "$3" ] || { echo "FAIL $1: expected '$2', got '$3'"; fail=1; }; }
rc() { semver_compare "$1" "$2"; echo $?; }

eq "betas sort numerically" "v1.4.11-beta.14" "$(printf 'v1.4.11-beta.9\nv1.4.11-beta.14\nv1.4.11-beta.10\n' | version_sort | tail -n1)"
eq "release sorts above its betas" "v1.4.11" "$(printf 'v1.4.11\nv1.4.11-beta.14\n' | version_sort | tail -n1)"
eq "beta.14 newer than beta.9" 1 "$(PRERELEASE=1 rc v1.4.11-beta.14 v1.4.11-beta.9)"
eq "release newer than its beta" 1 "$(PRERELEASE=1 rc v1.4.11 v1.4.11-beta.14)"
eq "stable channel reverts beta" 1 "$(PRERELEASE=0 rc v1.4.10 v1.4.11-beta.14)"

# A leading "v" must go, one inside a word must not (preview.10 is newer than preview.2)
eq "only a leading v is stripped" 2 "$(PRERELEASE=1 rc v1.0.0-preview.2 1.0.0-preview.10)"

# curl is stubbed for the rest of the file; each block sets FIXTURE to the API response
curl() { printf '%s' "$FIXTURE"; }

# GitHub's own order: newest day first, same-day tags compared as text
FIXTURE='
[{"tag_name":"v1.4.11-beta.9","created_at":"2026-09-23T06:14:58Z","assets":[{"name":"linux-with-runtimes.zip","browser_download_url":"b9"}]},
 {"tag_name":"v1.4.11-beta.15","created_at":"2026-09-23T13:00:00Z","assets":[]},
 {"tag_name":"v1.4.11-beta.14","created_at":"2026-09-23T12:50:34Z","assets":[{"name":"linux-with-runtimes.zip","browser_download_url":"b14"}]},
 {"tag_name":"v2.0.0-alpha.1","created_at":"2025-12-08T10:03:54Z","assets":[{"name":"linux-with-runtimes.zip","browser_download_url":"stale"}]}]'
eq "newest day's highest release with the asset" "b14" "$(PRERELEASE=1 get_github_release r 'linux.*with-runtimes\.zip' | jq -r .asset_url)"

# MetaMod ships Source 1 (1.x) and Source 2 (2.x) builds with the same -linux.tar.gz suffix.
# 1.12 released a day later here: only the branch pin keeps CS2 off a Source 1 build.
MM='^mmsource-2\.[0-9.]+-git[0-9]+-linux\.tar\.gz$'
FIXTURE='
[{"tag_name":"1.12.0.1228","created_at":"2026-10-19T10:00:00Z","assets":[{"name":"mmsource-1.12.0-git1228-linux.tar.gz","browser_download_url":"source1"}]},
 {"tag_name":"2.0.0.1483","created_at":"2026-10-18T10:00:00Z","assets":[{"name":"mmsource-2.0.0-git1483-linux.tar.gz","browser_download_url":"source2"}]}]'
eq "metamod ignores the Source 1 branch" "source2" "$(PRERELEASE=1 get_github_release r "$MM" | jq -r .asset_url)"
eq "metamod version comes from the 2.x asset" "mmsource-2.0.0-git1483-linux.tar.gz" "$(PRERELEASE=1 get_github_release r "$MM" | jq -r .asset_name)"

# ModSharp tags are git-N and it publishes several a day. Text order puts git-99 above
# git-100, so the first array entry is the older build.
FIXTURE='
[{"tag_name":"git-99","created_at":"2026-10-23T09:00:00Z","assets":[{"name":"ModSharp-git99-linux.zip","browser_download_url":"core99"},{"name":"ModSharp-git99-linux-extensions.zip","browser_download_url":"ext99"}]},
 {"tag_name":"git-100","created_at":"2026-10-23T18:00:00Z","assets":[{"name":"ModSharp-git100-linux.zip","browser_download_url":"core100"},{"name":"ModSharp-git100-linux-extensions.zip","browser_download_url":"ext100"}]}]'
ms=$(PRERELEASE=1 get_github_release_json r 'linux\.zip$')
eq "modsharp picks the higher same-day build" "git-100" "$(echo "$ms" | jq -r .tag_name)"
eq "modsharp core asset" "core100" "$(echo "$ms" | jq -r '.assets[] | select(.name | contains("linux.zip") and (contains("extensions") | not)) | .browser_download_url')"
eq "modsharp extensions asset" "ext100" "$(echo "$ms" | jq -r '.assets[] | select(.name | contains("linux-extensions.zip")) | .browser_download_url')"
eq "modsharp tag normalises to the asset form" "git100" "$(echo "git-100" | sed 's/^git-/git/')"
eq "normalising leaves a semver tag alone" "v1.2.3-beta.1" "$(echo "v1.2.3-beta.1" | sed 's/^git-/git/')"

[ "$fail" -eq 0 ] && echo "OK"
exit "$fail"
