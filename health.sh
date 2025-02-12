#!/bin/sh
set -eux

nix --accept-flake-config run github:juspay/omnix health github:juspay/nixone

