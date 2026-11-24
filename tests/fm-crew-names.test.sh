#!/usr/bin/env bash
# Behavior tests for bin/fm-crew-names.sh: a pick avoids names already
# recorded as crew_name= in the home's task records, falls back to a suffixed
# name when the pool is exhausted, and every pool name is safe to record.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT=$(fm_test_tmproot fm-crew-names)
NAMES="$ROOT/bin/fm-crew-names.sh"

test_pool_is_large_unique_and_recordable() {
  local count dupes bad
  count=$(bash "$NAMES" list | wc -l)
  [ "$count" -ge 200 ] || fail "pool has only $count names"
  dupes=$(bash "$NAMES" list | sort | uniq -d)
  [ -z "$dupes" ] || fail "pool has duplicates: $dupes"
  bad=$(bash -c '. "$0"; fm_crew_names_pool | while IFS= read -r n; do fm_crew_name_valid "$n" || echo "$n"; done' "$NAMES")
  [ -z "$bad" ] || fail "pool names are not recordable: $bad"
  bash -c '. "$0"; fm_crew_name_valid "a · b"' "$NAMES" && fail "label separator accepted"
  bash -c '. "$0"; fm_crew_name_valid "a=b"' "$NAMES" && fail "key syntax accepted"
  pass "crew-name pool is large, unique, and recordable"
}

test_pick_skips_names_in_use() {
  local state pick free
  state="$TMP_ROOT/state-busy"
  mkdir -p "$state"
  free=$(bash "$NAMES" list | tail -n 1)
  bash "$NAMES" list | sed '$d' | awk '{ printf "kind=ship\ncrew_name=%s\n", $0 > (dir "/t" NR ".meta") }' dir="$state"
  pick=$(bash "$NAMES" pick "$state")
  [ "$pick" = "$free" ] || fail "pick '$pick' was not the only free name '$free'"
  pass "crew-name pick skips names recorded in this home"
}

test_pick_suffixes_when_pool_is_exhausted() {
  local state pick
  state="$TMP_ROOT/state-full"
  mkdir -p "$state"
  bash "$NAMES" list | awk '{ printf "crew_name=%s\n", $0 > (dir "/t" NR ".meta") }' dir="$state"
  pick=$(bash "$NAMES" pick "$state")
  case "$pick" in *' II') ;; *) fail "exhausted pool pick was not suffixed: $pick" ;; esac
  bash "$NAMES" list | grep -qxF "${pick% II}" || fail "suffixed pick is not a pool name: $pick"
  pass "crew-name pick suffixes a pool name once every name is taken"
}

fm_test_run \
  test_pool_is_large_unique_and_recordable \
  test_pick_skips_names_in_use \
  test_pick_suffixes_when_pool_is_exhausted
