{ lib, stdenv }:
let
  inherit (stdenv) hostPlatform;

  minecraftOsName =
    if hostPlatform.isLinux then
      "linux"
    else if hostPlatform.isDarwin then
      "osx"
    else if hostPlatform.isWindows then
      "windows"
    else
      throw "unsupported Minecraft OS: ${hostPlatform.system}";

  minecraftArch =
    if hostPlatform.isx86_64 then
      "64"
    else if hostPlatform.isx86_32 then
      "32"
    else if hostPlatform.isAarch64 then
      "64"
    else
      throw "unsupported Minecraft arch: ${hostPlatform.system}";

  minecraftOs = {
    name = minecraftOsName;
    arch = minecraftArch;
  };

  matchesOs =
    ruleOs: lib.all (name: (minecraftOs.${name} or null) == ruleOs.${name}) (builtins.attrNames ruleOs);

  matchesFeatures =
    features: ruleFeatures:
    lib.all (name: (features.${name} or false) == ruleFeatures.${name}) (
      builtins.attrNames ruleFeatures
    );

  matchesRule =
    features: rule: matchesOs (rule.os or { }) && matchesFeatures features (rule.features or { });

  allowedByRules =
    features: rules:
    let
      matched = builtins.filter (matchesRule features) rules;
    in
    if rules == [ ] then
      true
    else if matched == [ ] then
      false
    else
      (lib.last matched).action == "allow";

  substituteVars =
    vars: value:
    lib.replaceStrings (map (name: "\${${name}}") (builtins.attrNames vars)) (map (
      name: toString vars.${name}
    ) (builtins.attrNames vars)) value;

  mkTmpNativesDir =
    natives:
    let
      copyScript = lib.concatMapStringsSep "\n" (native: ''
        cp -Rf ${native}/. "$NATIVES_DIR/"
      '') natives;
    in
    ''
      NATIVES_DIR="$(mktemp -d)"
      cleanup_natives() {
        rm -rf "$NATIVES_DIR"
      }
      trap cleanup_natives EXIT

      ${copyScript}
    '';
in
{
  inherit
    minecraftOsName
    minecraftArch
    minecraftOs
    allowedByRules
    substituteVars
    mkTmpNativesDir
    ;
}
