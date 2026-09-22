{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.55.0";

  urlInfo =
    {
      x86_64-darwin = {
        url = "https://github.com/cirruslabs/orchard/releases/download/${version}/orchard-darwin-amd64.tar.gz";
        sha256 = "sha256-2EKbYJPJ4ytkWIuvSm+/1v3veOJQpYBXp+iOekJRx/4=";
      };
      aarch64-darwin = {
        url = "https://github.com/cirruslabs/orchard/releases/download/${version}/orchard-darwin-arm64.tar.gz";
        sha256 = "sha256-cu5EQlHpHgey0F4bXvGbbxnMKt6dMGjMRbPFaZOKQas=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "orchard";
  inherit version;

  src = fetchurl urlInfo;
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
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
