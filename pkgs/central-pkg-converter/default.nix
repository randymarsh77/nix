{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "CentralisedPackageConverter";
  version = "1.0.67";
  nugetSha256 = "sha256-0AGZvIskj//kvaTBKfI8MgS0omZYx8z6haz/aDOmJuM=";

  executables = "central-pkg-converter";

  meta = with lib; {
    description = "Converts a project to use Centralised Package Management.";
    homepage = "https://github.com/Webreaper/CentralisedPackageConverter";
    changelog = "https://github.com/Webreaper/CentralisedPackageConverter/releases/tag/Release ${version}";
    license = licenses.asl20;
  };
}
