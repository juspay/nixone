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

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        checks.ubuntu-setup-test = (nix-vm-test.lib.${system}.ubuntu."24_04" {
          sharedDirs = {
            nixone = {
              source = "${self}";
              target = "/mnt/nixone";
            };
          };

          testScript = ''
            start_all()
            machine.wait_for_unit("multi-user.target")

            # Fix network - bring up eth0 and get DHCP
            print("Bringing up eth0...")
            machine.succeed("ip link set eth0 up")
            machine.succeed("dhclient -v eth0")

            # Wait for network
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
        }).sandboxed;
      };
    };
}
