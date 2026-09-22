{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "JetBrains.dotCover.CommandLineTools";
  version = "2026.1.1";
  nugetSha256 = "sha256-UGchlwvyAwN36r5ZNZ5dbRerrd7AfAteNe+Lyf01r30=";

  executables = "dotcover";

  meta = with lib; {
    description = "JetBrains dotCover command line tools";
    homepage = "https://www.jetbrains.com/dotcover/";
    license = {
      fullName = "JetBrains dotUltimate License";
      url = "https://www.jetbrains.com/legal/docs/toolbox/license_personal/";
    };
  };
}
