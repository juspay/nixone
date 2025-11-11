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
            diskSize = "+40G";
            sharedDirs = {
              nixone = {
                source = "${self}";
                target = "/mnt/nixone";
              };
            };

            testScript = ''
              start_all()
              machine.wait_for_unit("multi-user.target")

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
        in
        {
          # Package the test driver (run with: nix run .#ubuntu-test)
          packages.ubuntu-test = vmTest.driver;
        };
    };
}
