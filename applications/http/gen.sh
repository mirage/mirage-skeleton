#!/bin/sh

hostname="${2:-localhost}"

openssl req -x509 -newkey rsa:4096 -keyout keys/$1 -out certificates/$1 -sha256 -days 365 -subj "/CN=$hostname" -nodes
