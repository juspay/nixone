{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vm-test.url = "github:numtide/nix-vm-test";
    nix-vm-test.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, nix-vm-test }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        vmTest = nix-vm-test.lib.${system}.ubuntu."24_04" {
          sharedDirs = {
            nixone = {
              source = "${self}";
              target = "/mnt/nixone";
            };
          };

          testScript = ''
            start_all()
            machine.wait_for_unit("multi-user.target")

            # Debug network status
            print("=== Checking network ===")
            print(machine.succeed("systemctl status systemd-networkd.service || true"))
            print(machine.succeed("networkctl status || true"))
            print(machine.succeed("ip addr show || true"))
            print(machine.succeed("ip route show || true"))

            # Try to bring up network manually if needed
            print("=== Attempting manual network config ===")
            machine.succeed("systemctl restart systemd-networkd || true")
            machine.succeed("sleep 5")
            print(machine.succeed("networkctl status || true"))

            machine.wait_until_succeeds("ping -c 1 1.1.1.1", timeout=30)

            # Run the setup script from shared directory
            print("Running setup.sh...")
            machine.succeed("bash /mnt/nixone/setup.sh")

            # Source Nix to get it in PATH
            print("Sourcing Nix profile...")
            machine.succeed(". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && which nix")

            # Verify home-manager setup
            machine.succeed("test -d ~/.config/home-manager")

            print("Setup test completed successfully!")
          '';
        };
      in {
        # Use driver (non-interactive, has network) for CI
        checks.ubuntu-setup-test = vmTest.driver.overrideAttrs (old: {
          requiredSystemFeatures = [ "kvm" "nixos-test" ];
        });
      };
    };
}
