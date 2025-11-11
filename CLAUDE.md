This project hosts a static website providing two endpoints:

1. `setup.sh`: For installing Nix on user's machine and setup home-manager
2. `health.sh`: To check the health of the user's Nix environment.

The `setup.sh` script defers to Determinate Systems nix-installer to do the actual installation. And the `health.sh` script uses omnix to do the health check.
