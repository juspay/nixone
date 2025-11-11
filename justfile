# Test setup.sh in Ubuntu 24.04 VM
test:
    nix run .#ubuntu-test

# Run all checks
check:
    nix flake check --show-trace
