{
  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      overlays.default = final: prev: {
        sourcetree = final.callPackage ./sourcetree { };
        direnv-exec = final.callPackage ./direnv-exec { };
        refresh-spotlight = final.callPackage ./refresh-spotlight { };
        remote-build-flake = final.callPackage ./remote-build-flake { };
        xcode = final.callPackage ./xcode { };
        dotnet = final.callPackage ./dotnet { };
        pwsh = final.callPackage ./pwsh { };
        mysql-workbench-dist = final.callPackage ./mysql-workbench { };
        docker-desktop = final.callPackage ./docker-desktop { };
        charles = final.callPackage ./charles { };
        db-browser = final.callPackage ./db-browser { };
        nitguard = final.callPackage ./nitguard { };
        csharprepl = final.callPackage ./csharprepl { };
        xstyler = final.callPackage ./xstyler { };

        dotcover = final.callPackage ./resharper-tools/dotcover { };
        dotmemory = final.callPackage ./resharper-tools/dotmemory { };
        dottrace = final.callPackage ./resharper-tools/dottrace { };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in {
        packages = {
          sourcetree = pkgs.sourcetree;
          direnv-exec = pkgs.direnv-exec;
          refresh-spotlight = pkgs.refresh-spotlight;
          remote-build-flake = pkgs.remote-build-flake;
          xcode = pkgs.xcode;
          dotnet = pkgs.dotnet;
          pwsh = pkgs.pwsh;
          mysql-workbench-dist = pkgs.mysql-workbench-dist;
          docker-desktop = pkgs.docker-desktop;
          charles = pkgs.charles;
          db-browser = pkgs.db-browser;
          nitguard = pkgs.nitguard;
          csharprepl = pkgs.csharprepl;
          dotcover = pkgs.dotcover;
          dotmemory = pkgs.dotmemory;
          dottrace = pkgs.dottrace;
          xstyler = pkgs.xstyler;
          default = pkgs.hello;
        };
      });
}
