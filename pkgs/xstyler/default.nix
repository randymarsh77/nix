{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "xamlstyler.console";
  version = "3.2501.8";
  nugetSha256 = "sha256-We/IFFuZ0uw6coE+L+C4iEK9mzzb63QXtRXHbFRPtc0=";

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
