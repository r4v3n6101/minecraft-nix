{
  lib,
  utils,

  arguments ? null,
  minecraftArguments ? null,
  vars ? { },
  features ? { },
}:
let
  allowedByRules = utils.allowedByRules features;

  # Single arg or something like ["--width" "..."]
  normalizeValue = value: if builtins.isList value then value else [ value ];

  # Unify to list and filter by rules
  normalizeArg =
    item:
    if builtins.isString item then
      [ item ]
    else if allowedByRules (item.rules or [ ]) then
      normalizeValue item.value
    else
      [ ];
  substituteArg = utils.substituteVars vars;
  normalizeArgs = xs: map substituteArg (lib.flatten (map normalizeArg xs));

  gameArgs =
    if arguments != null && arguments ? game then
      normalizeArgs arguments.game
    else if minecraftArguments != null then
      map substituteArg (lib.splitString " " minecraftArguments)
    else
      [ ];

  jvmArgs = if arguments != null && arguments ? jvm then normalizeArgs arguments.jvm else [ ];
in
{
  inherit gameArgs jvmArgs;
}
