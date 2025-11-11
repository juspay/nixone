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

            print("=== NETWORK INTERFACES ===")
            print(machine.succeed("ip addr show"))
            print(machine.succeed("ip link show"))

            print("\n=== ROUTING TABLE ===")
            print(machine.succeed("ip route show"))
            print(machine.succeed("ip route get 1.1.1.1 || true"))

            print("\n=== DNS CONFIGURATION ===")
            print(machine.succeed("cat /etc/resolv.conf"))
            print(machine.succeed("ls -la /etc/resolv.conf"))

            print("\n=== SYSTEMD-RESOLVED STATUS ===")
            print(machine.succeed("systemctl status systemd-resolved || true"))
            print(machine.succeed("systemctl is-active systemd-resolved || true"))
            print(machine.succeed("resolvectl status || true"))

            print("\n=== NETWORK SERVICES ===")
            print(machine.succeed("systemctl status NetworkManager || true"))
            print(machine.succeed("systemctl status networking || true"))
            print(machine.succeed("systemctl list-units | grep network || true"))

            print("\n=== CONNECTIVITY TESTS ===")
            print("Testing gateway ping:")
            print(machine.succeed("ping -c 1 $(ip route | grep default | awk '{print $3}') || true"))
            print("Testing external IP (1.1.1.1):")
            print(machine.succeed("ping -c 1 1.1.1.1 || true"))
            print("Testing external IP (8.8.8.8):")
            print(machine.succeed("ping -c 1 8.8.8.8 || true"))

            print("\n=== DNS RESOLUTION TESTS ===")
            print("Using nslookup:")
            print(machine.succeed("nslookup google.com || true"))
            print("Using dig:")
            print(machine.succeed("dig google.com || true"))
            print("Using getent:")
            print(machine.succeed("getent hosts google.com || true"))

            print("\n=== FIREWALL STATUS ===")
            print(machine.succeed("iptables -L -n || true"))
            print(machine.succeed("ufw status || true"))

            print("\n=== ALL DONE - STOPPING HERE ===")
            # Don't run setup.sh yet, just debugging

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
