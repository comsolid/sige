#!/bin/sh

CERT_DIR="/etc/ssl/certs/sige"
PASS="sige123456"

openssl genrsa -des3 -passout "pass:${PASS}" \
  -out "${CERT_DIR}/sige.pass.key" 2048

openssl rsa -passin "pass:${PASS}" \
  -in "${CERT_DIR}/sige.pass.key" \
  -out "${CERT_DIR}/sige.key"

openssl req -new \
  -key "${CERT_DIR}/sige.key" \
  -out "${CERT_DIR}/sige.csr" \
  -subj "/C=BR/ST=Ceará/L=Maracanaú/O=COMSOLiD/OU=LaTIM/CN=sige.comsolid.org"

openssl x509 -req -days 365 \
  -in "${CERT_DIR}/sige.csr" \
  -signkey "${CERT_DIR}/sige.key" \
  -out "${CERT_DIR}/sige.crt"

rm -rf "${CERT_DIR}/sige.pass.key"
