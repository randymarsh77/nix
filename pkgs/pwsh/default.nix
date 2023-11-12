{ pkgs }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "pwsh";
  version = "7.2.4";

  phases = [ "installPhase" ];

  nativeBuildInputs = [ powershell ];

  installPhase = ''
    OUT_DIR="${builtins.placeholder "out"}"
    mkdir -p $OUT_DIR
    mkdir -p $OUT_DIR/bin
    ln -s ${powershell}/share/powershell/pwsh $OUT_DIR/bin/pwsh
  '';

  meta = with lib; {
    description = "pwsh";
    homepage = "";
    license = [ ];
    maintainers = [ ];
    platforms = platforms.darwin;
  };
}
