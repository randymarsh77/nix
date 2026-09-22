{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "nbgv";
  version = "3.9.50";

  nugetSha256 = "sha256-ocB4KY5c7Gxi9fm2p9TGIQTXq7B8AmLRcbgeKgIudEU=";

  meta = with lib; {
    description = "This is a .NET tool that provides CLI access to Nerdbank.GitVersioning functions.";
    homepage = "https://github.com/dotnet/Nerdbank.GitVersioning";
    changelog = "https://github.com/dotnet/Nerdbank.GitVersioning/releases/tag/v${version}";
    license = licenses.mit;
  };
}
