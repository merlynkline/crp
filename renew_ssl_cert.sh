#!/bin/sh
/usr/local/bin/carton exec le.pl --key ssl/lets_encrypt_account.key --csr ssl/kidsreflex.co.uk.csr --csr-key ssl/kidsreflex.co.uk.key --crt ssl/kidsreflex.co.uk.crt --domains "www.kidsreflex.co.uk" --generate-missing --handle-with Crypt::LE::Challenge::File --handle-params '{"public_doc_path": "public"}' --live
