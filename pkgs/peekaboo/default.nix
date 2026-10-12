{ pkgs }:
let
  version = "4.5.0";
  sources = {
    aarch64-darwin = {
      arch = "arm64";
      sha256 = "a65323e5c79a0094c860199c86f99248c60955d9803ac2fa7a62b18494186beb";
    };
    x86_64-darwin = {
      arch = "x86_64";
      sha256 = "7d744bad6b118737e3113c89e071729ebe6de4a73359da93f922c3d0446bf744";
    };
  };
  source = sources.${pkgs.stdenv.hostPlatform.system};
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "peekaboo";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/openclaw/Peekaboo/releases/download/v${version}/peekaboo-macos-${source.arch}.tar.gz";
    inherit (source) sha256;
  };

  sourceRoot = "peekaboo-macos-${source.arch}";
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 peekaboo "$out/bin/peekaboo"
    for library in libswiftCompatibility*.dylib; do
      if [ -f "$library" ]; then
        install -m755 "$library" "$out/bin/"
      fi
    done
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "macOS screen capture, accessibility inspection, and UI automation CLI";
    homepage = "https://github.com/openclaw/Peekaboo";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "peekaboo";
  };
}
