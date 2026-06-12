{
  lib,
  callPackage,
  fetchurl,
  writeShellScriptBin,
  jre,

  url,
  sha1,
  features ? { },
  staticVars ? {
    game_directory = ".";
    auth_player_name = "Player";
    user_properties = "{}";
    auth_uuid = "00000000-0000-0000-0000-000000000000";
    auth_access_token = "0";
    clientid = "0";
    auth_xuid = "0";
    user_type = "legacy";
    version_type = "release";
  },
}:
let
  utils = callPackage ./utils.nix { };

  versionInfoFile = fetchurl {
    inherit url sha1;
  };
  versionInfo = builtins.fromJSON (builtins.readFile versionInfoFile);

  assets = callPackage ./assets.nix {
    inherit (versionInfo.assetIndex) id url sha1;
  };
  libraryArtifacts = callPackage ./libraries.nix {
    inherit utils features;
    inherit (versionInfo) libraries;
  };
  clientJarFile = fetchurl {
    inherit (versionInfo.downloads.client) url sha1;
  };

  classpath = lib.concatStringsSep ":" ([ clientJarFile ] ++ libraryArtifacts.libraries);

  args = callPackage ./args.nix {
    inherit utils features;

    arguments = versionInfo.arguments or null;
    minecraftArguments = versionInfo.minecraftArguments or null;

    vars = staticVars // {
      inherit classpath;

      version_name = versionInfo.id;
      assets_root = assets;
      assets_index_name = versionInfo.assetIndex.id;
      natives_directory = "$NATIVES_DIR";
    };
  };
in
writeShellScriptBin "minecraft" ''
  ${utils.mkTmpNativesDir libraryArtifacts.natives}

  JVM_ARGS=(
  ${
    if args.jvmArgs == [ ] then
      ''
        "-Djava.library.path=$NATIVES_DIR"
        "-cp"
        "${classpath}"
      ''
    else
      lib.concatMapStringsSep "\n" (arg: ''"${arg}"'') args.jvmArgs
  }
  )

  GAME_ARGS=(
  ${lib.concatMapStringsSep "\n" (arg: ''"${arg}"'') args.gameArgs}
  )

  exec ${jre}/bin/java \
    "''${JVM_ARGS[@]}" \
    ${versionInfo.mainClass} \
    "''${GAME_ARGS[@]}"
''
