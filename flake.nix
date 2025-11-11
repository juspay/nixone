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

            # Wait for network and DNS
            print("Waiting for network...")
            machine.wait_for_unit("systemd-networkd.service")
            machine.wait_for_unit("systemd-resolved.service")

            # Test DNS resolution
            print("Testing DNS resolution...")
            machine.wait_until_succeeds("nslookup google.com", timeout=60)

            # Verify connectivity
            print("Testing connectivity...")
            machine.succeed("curl -s https://www.google.com > /dev/null")

            # Run the setup script
            print("Running setup.sh...")
            machine.succeed("bash /mnt/nixone/setup.sh")

            # Source Nix and verify installation
            print("Verifying Nix installation...")
            machine.succeed(". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && which nix")

            # Verify home-manager setup
            print("Verifying home-manager setup...")
            machine.succeed("test -d ~/.config/home-manager")

            print("Test completed successfully!")
          '';
        };
      in {
        # Run driver (has network) as a build step
        checks.ubuntu-setup-test = pkgs.stdenv.mkDerivation {
          name = "ubuntu-setup-test";
          requiredSystemFeatures = [ "kvm" "nixos-test" ];
          buildCommand = ''
            ${vmTest.driver}/bin/test-driver
            touch $out
          '';
        };
      };
    };
}
