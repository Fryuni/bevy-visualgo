{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1";

    rust-overlay = {
      url = "https://flakehub.com/f/oxalica/rust-overlay/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {inherit system overlays;};
        inherit (pkgs) mkShell;
        inherit (pkgs.lib) optionals makeLibraryPath;
        inherit (pkgs.stdenv) isLinux isDarwin;

        general-deps = with pkgs; [
          # Rust
          cargo-watch
          cargo-expand
          rust-analyzer-unwrapped
          # Toml
          taplo
          # Other
          vulkan-loader
          vulkan-tools
          git
        ];

        linux-deps = with pkgs; [
          # Wayland
          libxkbcommon
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
          clang
          lld
        ];

        darwin-deps = [
          pkgs.apple-sdk_15
          pkgs.libiconv
        ];

        web-deps = with pkgs; [
          trunk
          wasm-bindgen-cli
          binaryen
        ];

        extensions = [
          "clippy"
          "rustfmt"
          "rust-src"
          "rustc-codegen-cranelift"
        ];
      in {
        formatter = pkgs.alejandra;

        devShells = {
          # Regular shell
          default = let
            toolchain = pkgs.rust-bin.nightly.latest.minimal.override {
              inherit extensions;
              targets =
                ["wasm32-unknown-unknown"]
                ++ optionals isLinux [
                  "x86_64-unknown-linux-musl"
                  "x86_64-unknown-linux-gnu"
                ]
                ++ optionals isDarwin [
                  "x86_64-apple-darwin"
                  "aarch64-apple-darwin"
                ];
            };
            platform = pkgs.makeRustPlatform {inherit (toolchain) cargo rustc;};
          in
            mkShell rec {
              buildInputs =
                [
                  toolchain
                  platform.bindgenHook
                ]
                ++ general-deps
                ++ web-deps
                ++ optionals isLinux linux-deps
                ++ optionals isDarwin darwin-deps;

              RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
              LD_LIBRARY_PATH = makeLibraryPath buildInputs;
              # RUSTFLAGS = "-Zshare-generics=y -Zthreads=0";
            };
          web = let
            toolchain = pkgs.rust-bin.nightly.latest.default.override {
              targets = ["wasm32-unknown-unknown"];
            };
            platform = pkgs.makeRustPlatform {inherit (toolchain) cargo rustc;};
          in
            mkShell rec {
              buildInputs =
                [
                  toolchain
                  platform.bindgenHook
                ]
                ++ general-deps ++ web-deps;

              RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
              LD_LIBRARY_PATH = makeLibraryPath buildInputs;
              # RUSTFLAGS = "-Zshare-generics=y -Zthreads=0";
            };
        };
      }
    );
}
