#!/bin/bash
# One-time local dev setup: create a stable self-signed code-signing identity
# so the app's TCC (Accessibility) grant survives rebuilds, and clear the
# stale ad-hoc grants. Safe + reversible (delete the "vjookh Dev" cert in
# Keychain Access to undo). You will get ONE macOS password dialog for the
# trust step — that is expected.
set -euo pipefail

KC="$HOME/Library/Keychains/login.keychain-db"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Generating self-signed code-signing certificate…"
cat > "$WORK/cnf" <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = vjookh Dev
[v3]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$WORK/key.pem" -out "$WORK/cert.pem" \
  -days 3650 -config "$WORK/cnf"

openssl pkcs12 -export \
  -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
  -out "$WORK/id.p12" -passout pass:vjookh -name "vjookh Dev"

echo "==> Importing into login keychain (codesign-accessible)…"
security import "$WORK/id.p12" -k "$KC" -P vjookh -T /usr/bin/codesign

echo "==> Marking certificate trusted for code signing (password dialog)…"
security add-trusted-cert -r trustRoot -p codeSign -k "$KC" "$WORK/cert.pem"

echo "==> Resetting stale Accessibility grants for io.github.vjookh.app…"
tccutil reset Accessibility io.github.vjookh.app || true

echo "==> Verifying identity is usable for codesigning:"
security find-identity -v -p codesigning | grep "vjookh Dev"

echo "SETUP OK"
