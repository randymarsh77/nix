{ pkgs }:
with pkgs;
buildDotnetGlobalTool {
  pname = "JetBrains.dotCover.CommandLineTools";
  version = "2025.3.3";
  nugetSha256 = "sha256-IHt4HL2CyHgQSbf1peFuxzEe1XpdVCtbK5CgOyTPEBg=";

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
