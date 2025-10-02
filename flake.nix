{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.self.overlays.default
              ];
            };
          }
      );
  in {
    overlays.default = _: prev: let
      fenix = inputs.fenix.packages.${prev.stdenv.hostPlatform.system};
      toml = with builtins; (fromTOML (readFile ./rust-toolchain.toml)).toolchain;
      toolchain = fenix.fromToolchainName {
        name = toml.channel;
        # sha256 = prev.lib.fakeSha256;
        sha256 = "sha256-rCvHLpcrLKXtcpyysfi51zsSgMxB2+pXRIoJnUt2ORM=";
      };
    in {
      # rustToolchain = toolchain."${toml.profile or "default"}Toolchain";
      rustToolchain = fenix.combine (
        [
          # toolchain."${toml.profile or "default"}Toolchain"
          (toolchain.withComponents (toml.components or []))
        ]
        ++ map (target: fenix.targets.${target}.${toml.channel}.rust-std) (toml.targets or [])
      );
    };

    formatter = forEachSupportedSystem ({pkgs}: pkgs.alejandra);

    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShell rec {
          buildInputs = with pkgs; [
            rustToolchain
            clang
            lld

            # Wayland
            libxkbcommon.dev
            wayland.dev
            # Xorg
            xorg.libX11
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            # Other
            openssl
            pkg-config
            alsa-lib.dev
            systemd.dev
            vulkan-validation-layers

            vulkan-loader
            vulkan-tools

            cargo-deny
            cargo-edit
            cargo-expand
            cargo-watch
            rust-analyzer
          ];

          env = {
            # Required by rust-analyzer
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
            RUST_BACKTRACE = "1";
            CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG = "true";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
        };
      }
    );
  };
}
