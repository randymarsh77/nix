{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "JetBrains.ReSharper.GlobalTools";
  version = "2026.1.1";
  nugetSha256 = "sha256-OvUvJNfjHSFg0+kDW/nM0iR5HptvTQocjs4kfiTYXUY=";

  dotnet-sdk = dotnetCorePackages.sdk_8_0;

  executables = "jb";

  meta = with lib; {
    description = "Standalone command line tools that enable running ReSharper inspections outside of Visual Studio.";
    homepage = "https://www.jetbrains.com/resharper/features/command-line.html";
    changelog = "https://www.jetbrains.com/resharper/whatsnew/";
    license = {
      fullName = "License Agreement for ReSharper Command Line Tools";
      url = "https://www.nuget.org/packages/JetBrains.ReSharper.GlobalTools/2026.1.1/License";
    };
  };
}
