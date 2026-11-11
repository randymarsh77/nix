{
  description = "Opt-in macOS audio plugin inventory and official vendor installer management";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      catalog = builtins.fromJSON (builtins.readFile ./catalog.json);
      installers = builtins.fromJSON (builtins.readFile ./installers.json);
      catalogForSystem = system: catalog // {
        inherit system;
        products = map (product:
          (builtins.removeAttrs product [ "targets" ]) // product.targets.${system}
        ) catalog.products;
      };
      installersForSystem = system: builtins.mapAttrs (_: recipes: recipes.${system})
        (nixpkgs.lib.filterAttrs (_: recipes: builtins.hasAttr system recipes) installers);
    in {
      lib = { inherit catalogForSystem installersForSystem; };
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          selectedCatalog = pkgs.writeText "audio-catalog-${system}.json" (builtins.toJSON (catalogForSystem system));
          selectedInstallers = pkgs.writeText "audio-installers-${system}.json" (builtins.toJSON (installersForSystem system));
        in {
          audio-plugins = pkgs.writeShellApplication {
            name = "audio-plugins";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              exec python3 ${./audio_plugins.py} --catalog ${selectedCatalog} --installers ${selectedInstallers} "$@"
            '';
          };
        });
      apps = eachSystem (system: {
        audio-plugins = {
          type = "app";
          meta.description = "Manage official audio plugin installers explicitly";
          program = "${self.packages.${system}.audio-plugins}/bin/audio-plugins";
        };
      });
      checks = eachSystem (system:
        let pkgs = import nixpkgs { inherit system; }; in {
          unit = pkgs.runCommand "audio-plugins-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            cp -R ${./.} source
            chmod -R u+w source
            cd source
            python3 -m unittest discover -s tests -v
            touch "$out"
          '';
        });
    };
}
