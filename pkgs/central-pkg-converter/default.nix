{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "CentralisedPackageConverter";
  version = "1.0.74";
  nugetSha256 = "sha256-byMgF9JsLJzOqBMrnfB/35y1iTM++zMe4V1BZkDr2Rs=";

  executables = "central-pkg-converter";

  meta = with lib; {
    description = "Converts a project to use Centralised Package Management.";
    homepage = "https://github.com/Webreaper/CentralisedPackageConverter";
    changelog = "https://github.com/Webreaper/CentralisedPackageConverter/releases/tag/Release ${version}";
    license = licenses.asl20;
  };
}
