#!/bin/bash
set -euo pipefail

# Chrome stores cookie values AES-encrypted (the plaintext `value` column is
# empty); the key is derived from the "Chrome Safe Storage" Keychain password.
# We pull the encrypted blob with the sqlite3 CLI and decrypt it here.
# NOTE: reading Chrome's profile requires the running terminal to have
# Full Disk Access (System Settings > Privacy & Security > Full Disk Access).

COOKIES_DB="$HOME/Library/Application Support/Google/Chrome/Default/Cookies"
TMP_DB="$(mktemp -t chrome-cookies)"
trap 'rm -f "$TMP_DB"' EXIT

# Chrome keeps the DB locked; work off a copy. Reading it requires the host
# terminal to have Full Disk Access, else macOS returns "Operation not permitted".
if ! cp "$COOKIES_DB" "$TMP_DB" 2>/dev/null; then
  cat >&2 <<EOF
Cannot read Chrome's cookie store (Operation not permitted).

Grant Full Disk Access to this terminal (${TERM_PROGRAM:-your terminal app}):
  System Settings > Privacy & Security > Full Disk Access
Enable it, then fully quit (Cmd-Q) and reopen the terminal, and re-run this.
EOF
  exit 1
fi

SAFE_STORAGE_PW="$(security find-generic-password -w -s 'Chrome Safe Storage' -a 'Chrome')"

get_cookie() {
  local host="$1" name="$2" hex
  hex="$(sqlite3 "$TMP_DB" \
    "SELECT hex(encrypted_value) FROM cookies \
     WHERE host_key LIKE '%${host}' AND name='${name}' LIMIT 1;")"
  [ -n "$hex" ] || { echo "cookie '${name}' not found for '${host}'" >&2; return 1; }

  HOST="$host" HEX="$hex" PW="$SAFE_STORAGE_PW" python3 - <<'PY'
import os, sys, hashlib, subprocess
enc  = bytes.fromhex(os.environ["HEX"])
pw   = os.environ["PW"].encode()
host = os.environ["HOST"]

if enc[:3] != b"v10":
    sys.exit(f"unexpected encryption prefix {enc[:3]!r}")

key = hashlib.pbkdf2_hmac("sha1", pw, b"saltysalt", 1003, 16)
iv  = b" " * 16
plain = subprocess.run(
    ["openssl", "enc", "-d", "-aes-128-cbc", "-K", key.hex(), "-iv", iv.hex()],
    input=enc[3:], capture_output=True, check=True).stdout

# Recent Chrome prepends a 32-byte SHA256 domain hash to the plaintext.
for h in (host, host.lstrip("."), "." + host.lstrip(".")):
    if plain[:32] == hashlib.sha256(h.encode()).digest():
        plain = plain[32:]
        break

sys.stdout.buffer.write(plain)
PY
  echo
}

get_cookie "hello.atlassian.net" "tenant.session.token"
get_cookie "hello.atlassian.net" "atl.xsrf.token"
