{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "JetBrains.ReSharper.GlobalTools";
  version = "2025.3.3";
  nugetSha256 = "sha256-0UnVAYwDl6sOV08SgQUuJu5wypf4uJvBnoPwYWX6G30=";

  dotnet-sdk = dotnetCorePackages.sdk_8_0;

  executables = "jb";

  meta = with lib; {
    description = "Standalone command line tools that enable running ReSharper inspections outside of Visual Studio.";
    homepage = "https://www.jetbrains.com/resharper/features/command-line.html";
    changelog = "https://www.jetbrains.com/resharper/whatsnew/";
    license = {
      fullName = "License Agreement for ReSharper Command Line Tools";
      url = "https://www.nuget.org/packages/JetBrains.ReSharper.GlobalTools/2025.3.3/License";
    };
  };
}
