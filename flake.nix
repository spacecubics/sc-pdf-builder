{
  description = "Space Cubics PDF Builder environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      environment =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          fonts = import ./nix/fonts.nix { inherit pkgs; };
          gems = pkgs.bundlerEnv {
            name = "sc-pdf-gems";
            ruby = pkgs.ruby;
            gemdir = ./.;
            gemConfig = pkgs.defaultGemConfig // {
              mathematical =
                attrs:
                (pkgs.defaultGemConfig.mathematical attrs)
                // {
                  CMAKE_POLICY_VERSION_MINIMUM = "3.5";
                  CMAKE_GENERATOR = "Unix Makefiles";
                };
            };
          };
          tools = [
            gems
            gems.wrappedRuby
            pkgs.gnumake
            pkgs.git
            pkgs.nixfmt-tree
            pkgs.d2
            pkgs.librsvg
            (pkgs.python3.withPackages (ps: [ ps.pillow ]))
          ];
          fontSettings = {
            FONTS_DIR = "${fonts}/share/fonts/truetype;${pkgs.ipaexfont}/share/fonts/truetype";
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [
                fonts
                pkgs.bakoma_ttf
                pkgs.ipaexfont
              ];
            };
          };
        in
        {
          inherit
            pkgs
            fonts
            gems
            tools
            fontSettings
            ;
        };
    in
    {
      formatter = forAllSystems (system: (environment system).pkgs.nixfmt-tree);

      devShells = forAllSystems (
        system:
        let
          env = environment system;
        in
        {
          default = env.pkgs.mkShell (
            env.fontSettings
            // {
              packages = env.tools;
            }
          );
        }
      );

      packages = forAllSystems (
        system:
        let
          env = environment system;
        in
        {
          inherit (env) fonts gems;
          inherit (env.pkgs) bundix;
        }
      );

    };
}
