# nix-update-tool.tags: https://github.com/waf/CSharpRepl
{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "csharprepl";
  version = "0.6.7";

  nugetSha256 = "sha256-a0CiU3D6RZp1FF459NIUUry5TFRDgm4FRhqJZNAGYWs=";

  dotnet-sdk = dotnetCorePackages.sdk_9_0;

  meta = with lib; {
    description =
      "A cross-platform command line REPL for the rapid experimentation and exploration of C#. It supports intellisense, installing NuGet packages, and referencing local .NET projects and assemblies.";
    homepage = "https://github.com/waf/CSharpRepl";
    changelog = "https://github.com/waf/CSharpRepl/releases/tag/v${version}";
    license = licenses.mpl20;
  };
}
