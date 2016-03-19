#!/usr/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR/ssl"

PERL5LIB="$DIR" le.pl --key lets_encrypt_account.key --csr kidsreflex.co.uk.csr --csr-key kidsreflex.co.uk.key --crt kidsreflex.co.uk.crt --domains "www.kidsreflex.co.uk" --generate-missing --handle-with Crypt::LE::Challenge::File --handle-params '{"public_doc_path": "$DIR/public"}' --live
