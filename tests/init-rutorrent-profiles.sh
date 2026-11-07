#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
helper=$root/rootfs/usr/local/bin/init-rutorrent-profiles
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

cat > "$tmp/php" <<'EOF'
#!/bin/sh
{
	printf '%s' "$1"
	shift
	while [ "$#" -gt 0 ]; do
		printf '\t%s' "$1"
		shift
	done
	printf '\n'
} >> "$CALLS_FILE"
EOF
chmod +x "$tmp/php"

export CALLS_FILE="$tmp/calls"
export RUTORRENT_INITPLUGINS_PHP="$tmp/php"
export RUTORRENT_INITPLUGINS_SCRIPT="$tmp/initplugins.php"
export RUTORRENT_HTPASSWD_FILE="$tmp/rutorrent.htpasswd"
: > "$CALLS_FILE"
: > "$RUTORRENT_HTPASSWD_FILE"
unset RUTORRENT_PROFILE_USERS RU_FORBID_USER_SETTINGS || true

"$helper"
printf '%s\n' "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

# Auth-file users are normalized like ruTorrent's User::getUser(), and
# usernames that normalize to the same profile are initialized only once.
printf 'Alice:hash-a\nbob:hash-b\nALICE:hash-c\n# comment:ignored\n' > "$RUTORRENT_HTPASSWD_FILE"
: > "$CALLS_FILE"
"$helper"
printf '%s\talice\n%s\tbob\n' "$RUTORRENT_INITPLUGINS_SCRIPT" "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"
if grep -q 'hash-' "$CALLS_FILE"; then
	echo 'htpasswd secrets were passed to initplugins' >&2
	exit 1
fi

# Preserve htpasswd whitespace: ruTorrent replaces it with underscores,
# including whitespace before a '#' that is part of the username.
printf ' Alice :hash-a\nbob :hash-b\n\tCarol\t:hash-c\n #D@ve :hash-d\n_alice_:hash-e\n:ignored\n' > "$RUTORRENT_HTPASSWD_FILE"
: > "$CALLS_FILE"
"$helper"
printf '%s\t_alice_\n%s\tbob_\n%s\t_carol_\n%s\t__d_ve_\n' \
	"$RUTORRENT_INITPLUGINS_SCRIPT" "$RUTORRENT_INITPLUGINS_SCRIPT" \
	"$RUTORRENT_INITPLUGINS_SCRIPT" "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

# Even a whitespace-only htpasswd username selects a named profile.
printf ' \t :hash-space\n' > "$RUTORRENT_HTPASSWD_FILE"
: > "$CALLS_FILE"
"$helper"
printf '%s\t___\n' "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

# An explicit list overrides htpasswd discovery, trims separator whitespace,
# and is normalized/deduplicated.
RUTORRENT_PROFILE_USERS=' Carol , D@ve, carol, , '
export RUTORRENT_PROFILE_USERS
: > "$CALLS_FILE"
"$helper"
printf '%s\tcarol\n%s\td_ve\n' "$RUTORRENT_INITPLUGINS_SCRIPT" "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

# An explicit list with only empty entries initializes the default profile.
RUTORRENT_PROFILE_USERS=' , , '
: > "$CALLS_FILE"
"$helper"
printf '%s\n' "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

# RU_FORBID_USER_SETTINGS collapses profile identity, so initialize default once.
RUTORRENT_PROFILE_USERS='alice,bob'
RU_FORBID_USER_SETTINGS=true
export RU_FORBID_USER_SETTINGS
: > "$CALLS_FILE"
"$helper"
printf '%s\n' "$RUTORRENT_INITPLUGINS_SCRIPT" > "$tmp/expected"
cmp "$tmp/expected" "$CALLS_FILE"

printf 'Profile initialization tests passed.\n'
