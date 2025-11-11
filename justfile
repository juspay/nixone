# Test setup.sh in Ubuntu 24.04 VM
test-ubuntu:
    nix build .#checks.x86_64-linux.ubuntu-setup-test -L

# Run all checks
check:
    nix flake check --show-trace

# Interactive test (opens VM window + Python console)
test-interactive:
    nix run .#ubuntu-test-interactive
