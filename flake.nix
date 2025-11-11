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

            # Find network interface name
            print("Available interfaces:")
            print(machine.succeed("ip link show"))

            # Get the actual interface name (not lo)
            iface = machine.succeed("ip link show | grep -v 'lo:' | grep '^[0-9]' | head -1 | cut -d: -f2 | tr -d ' '").strip()
            print(f"Using interface: {iface}")

            # Fix network - bring up interface and get DHCP
            print(f"Bringing up {iface}...")
            machine.succeed(f"ip link set {iface} up")
            machine.succeed(f"dhclient -v {iface}")

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
