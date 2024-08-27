#!/bin/bash

# Private key
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048

# Public key
openssl rsa -pubout -in private.pem -out key.pub 

## nocrypt (Private key does have no password)
openssl pkcs8 -topk8 -in private.pem -nocrypt -out key.pem

mkdir certs
mv key.pem ./certs/key.pem
mv key.pub ./certs/key.pub
