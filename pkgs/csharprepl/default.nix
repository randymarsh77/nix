# nix-update-tool.tags: https://github.com/waf/CSharpRepl
{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "csharprepl";
  version = "0.6.8";

  nugetSha256 = "sha256-TleKXF0oaLGJkpuYUADX87eAJYXwdOkZHAVUYWHTWhs=";

  dotnet-sdk = dotnetCorePackages.sdk_10_0;

  meta = with lib; {
    description =
      "A cross-platform command line REPL for the rapid experimentation and exploration of C#. It supports intellisense, installing NuGet packages, and referencing local .NET projects and assemblies.";
    homepage = "https://github.com/waf/CSharpRepl";
    changelog = "https://github.com/waf/CSharpRepl/releases/tag/v${version}";
    license = licenses.mpl20;
  };
}
