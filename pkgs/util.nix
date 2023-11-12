{ pkgs }:
let
  installApplication = { name, appname ? name, version, src, description
    , homepage, postInstall ? "", sourceRoot ? ".", ... }:
    with pkgs;
    stdenv.mkDerivation {
      name = "${name}-${version}";
      version = "${version}";
      src = src;
      buildInputs = [ undmg unzip ];
      sourceRoot = sourceRoot;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p "$out/Applications/${appname}.app"
        cp -pR * "$out/Applications/${appname}.app"
      '' + postInstall;
      meta = with pkgs.lib; {
        description = description;
        homepage = homepage;
        maintainers = with maintainers; [ ];
        platforms = platforms.darwin;
      };
    };

  installXZCompressedApplication = { name, appname ? name, version, src
    , description, homepage, postInstall ? "", sourceRoot ? ".", ... }:
    with pkgs;
    stdenv.mkDerivation {
      name = "${name}-${version}";
      version = "${version}";
      src = src;
      buildInputs = [ ];
      sourceRoot = sourceRoot;
      phases = [ "unpackPhase" "installPhase" ];
      unpackPhase = ''
        /usr/bin/hdiutil attach $src -mountpoint ./volume
        cp -pR ./volume/${appname}.app "$sourceRoot"
        /usr/bin/hdiutil detach ./volume
      '';
      installPhase = ''
        mkdir -p "$out/Applications/${appname}.app"
        cp -pR * "$out/Applications/${appname}.app"
      '' + postInstall;
      meta = with pkgs.lib; {
        description = description;
        homepage = homepage;
        maintainers = with maintainers; [ ];
        platforms = platforms.darwin;
      };
    };

  installExecutableBundle = { name, appname ? name, version, src, description
    , homepage, sourceRoot ? ".", ... }:
    with pkgs;
    stdenv.mkDerivation {
      name = "${name}-${version}";
      version = "${version}";
      src = src;
      buildInputs = [ ];
      sourceRoot = sourceRoot;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p "$out/${name}"
        cp -pR * "$out/${name}"
        mkdir -p "$out/bin"
        printf '#!/bin/bash\nexec %s "$@"\n' "$out/${name}/${name}" > "$out/bin/${name}"
        chmod +x $out/bin/${name}
      '';
      meta = with pkgs.lib; {
        description = description;
        homepage = homepage;
        maintainers = with maintainers; [ ];
        platforms = platforms.darwin;
      };
    };
in {
  inherit installApplication installXZCompressedApplication
    installExecutableBundle;
}
