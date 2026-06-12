{
  lib,
  fetchurl,
  runCommand,
  unzip,

  utils,
  libraries,
  features ? { },
}:
let
  isAllowed = library: utils.allowedByRules features (library.rules or [ ]);

  isLibrary = library: isAllowed library && library.downloads ? artifact;
  mkLibrary =
    library:
    fetchurl {
      inherit (library.downloads.artifact) url sha1;
    };

  isNativeLibrary =
    library:
    isAllowed library && library ? natives && builtins.hasAttr utils.minecraftOsName library.natives;
  mkNative =
    library:
    let
      classifierTemplate = builtins.getAttr utils.minecraftOsName library.natives;
      classifier = utils.substituteVars { arch = utils.minecraftArch; } classifierTemplate;
      classifiers = library.downloads.classifiers or { };
      download =
        if builtins.hasAttr classifier classifiers then
          builtins.getAttr classifier classifiers
        else
          throw "missing native classifier ${classifier} for ${library.name}";
      archive = fetchurl {
        inherit (download) url sha1;
      };
      excludes = library.extract.exclude or [ ];
    in
    runCommand "minecraft-native-${classifier}" { nativeBuildInputs = [ unzip ]; } ''
      mkdir -p "$out"
      unzip -q ${archive} -d "$out"
      ${lib.concatMapStringsSep "\n" (path: "rm -rf \"$out/${path}\"") excludes}
    '';
in
{
  libraries = map mkLibrary (builtins.filter isLibrary libraries);
  natives = map mkNative (builtins.filter isNativeLibrary libraries);
}
