final: prev: {
  sourcetree = final.callPackage ./sourcetree { };
  direnv-exec = final.callPackage ./direnv-exec { };
  refresh-spotlight = final.callPackage ./refresh-spotlight { };
  xcode = final.callPackage ./xcode { };
  dotnet = final.callPackage ./dotnet { };
  pwsh = final.callPackage ./pwsh { };
  mysql-workbench-dist = final.callPackage ./mysql-workbench { };
  docker-desktop = final.callPackage ./docker-desktop { };
  charles = final.callPackage ./charles { };
  db-browser = final.callPackage ./db-browser { };
  nitguard = final.callPackage ./nitguard { };
  csharprepl = final.callPackage ./csharprepl { };
  xstyler = final.callPackage ./xstyler { };

  dotcover = final.callPackage ./resharper-tools/dotcover { };
  dotmemory = final.callPackage ./resharper-tools/dotmemory { };
  dottrace = final.callPackage ./resharper-tools/dottrace { };
}
