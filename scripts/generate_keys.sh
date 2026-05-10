#!/usr/bin/env bash
set -euo pipefail

# Generates unencrypted RSA key pairs for the three CI/CD service accounts.
# Run once locally when onboarding a new project.
#
# Output (written to .keys/ by default, git-ignored):
#   rsa_key_dev.p8  / rsa_key_dev.pub
#   rsa_key_test.p8 / rsa_key_test.pub
#   rsa_key_prod.p8 / rsa_key_prod.pub
#
# After running this script:
#   1. Paste each .p8 file's full content into the SNOWFLAKE_PRIVATE_KEY
#      secret variable of the matching ADO variable group.
#   2. Paste each .pub file's key body (the lines between BEGIN/END PUBLIC KEY)
#      into scripts/admin_auth_setup.sql, then run it as SECURITYADMIN.
#   3. Delete the .keys/ directory or store the files in a secrets manager.
#      Never commit private keys to source control.

KEYS_DIR="${1:-.keys}"
mkdir -p "$KEYS_DIR"

for env in dev test prod; do
  private_key="$KEYS_DIR/rsa_key_${env}.p8"
  public_key="$KEYS_DIR/rsa_key_${env}.pub"

  openssl genrsa 2048 \
    | openssl pkcs8 -topk8 -nocrypt -out "$private_key"
  openssl rsa -in "$private_key" -pubout -out "$public_key"
  chmod 600 "$private_key"

  echo "Generated $private_key and $public_key"
done

echo ""
echo "Key pairs written to $KEYS_DIR/. See script comments for next steps."
