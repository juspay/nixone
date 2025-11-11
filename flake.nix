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

            # Wait for network (networkd should configure ens4 via DHCP)
            machine.wait_for_unit("systemd-networkd.service")
            machine.wait_until_succeeds("ping -c 1 1.1.1.1")

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
        # Use driver (has network) wrapped as a check
        checks.ubuntu-setup-test = pkgs.stdenv.mkDerivation {
          name = "ubuntu-setup-test";
          requiredSystemFeatures = [ "kvm" "nixos-test" ];
          buildCommand = ''
            ${vmTest.driver}/bin/test-driver
            touch $out
          '';
        };

        # Expose driver for interactive testing
        packages.ubuntu-test-interactive = vmTest.driverInteractive;
      };
    };
}
