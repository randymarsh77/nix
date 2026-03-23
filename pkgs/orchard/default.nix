{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "orchard";
  version = "0.15.0";

  src = fetchurl {
    url = "https://github.com/cirruslabs/orchard/releases/download/${finalAttrs.version}/orchard-darwin-arm64.tar.gz";
    sha256 = "sha256-9iQZxaVuSFDD/0hbPraM4OpsCCL8+yPEdgaodrxpGJs=";
  };
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r orchard $out/bin
    install -Dm444 LICENSE $out/share/orchard/LICENSE

    runHook postInstall
  '';

  meta = with lib; {
    description = "Orchestration for tart";
    homepage = "https://tart.run";
    license = licenses.fairsource09;
    mainProgram = finalAttrs.pname;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
