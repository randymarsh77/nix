{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "nbgv";
  version = "3.6.133";

  nugetSha256 = "sha256-bpTE8OdGaGdCj87DuIuuP3y/shNnpI4xaIkDefGpSIk=";

  meta = with lib; {
    description = "This is a .NET tool that provides CLI access to Nerdbank.GitVersioning functions.";
    homepage = "https://github.com/dotnet/Nerdbank.GitVersioning";
    changelog = "https://github.com/dotnet/Nerdbank.GitVersioning/releases/tag/v${version}";
    license = licenses.mit;
  };
}
