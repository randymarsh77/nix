{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "xamlstyler.console";
  version = "3.2206.4";
  nugetSha256 = "sha256-SEQt+7hK3DUcIhNOcNublmjcaz3yazPB8LQk9wUjv1o=";

  executables = "xstyler";
  dotnet-sdk = dotnetCorePackages.sdk_9_0;

  meta = with lib; {
    description =
      "The power of XAML Styler wrapped up in a small executable that can be integrated into build scripts, git commit templates, and more. This package is built on top of the same styling engine that powers the Visual Studio plugin, and can be configured by specifying an external configuration.";
    homepage = "https://github.com/Xavalon/XamlStyler";
    changelog =
      "https://github.com/Xavalon/XamlStyler/releases/tag/Release-${version}";
    license = licenses.asl20;
  };
}
