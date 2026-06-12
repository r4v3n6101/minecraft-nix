{
  lib,
  fetchurl,
  linkFarm,

  id,
  url,
  sha1,
  resourcesUrl ? "https://resources.download.minecraft.net",
}:
let
  assetIndexFile = fetchurl {
    inherit url sha1;
  };
  index = builtins.fromJSON (builtins.readFile assetIndexFile);
  mapToResources = index.map_to_resources or false;

  mkAsset =
    originalPath: obj:
    let
      hash = obj.hash;
      prefix = builtins.substring 0 2 hash;

      drv = fetchurl {
        url = "${resourcesUrl}/${prefix}/${hash}";
        sha1 = hash;
      };
    in
    {
      name = if mapToResources then "legacy/${originalPath}" else "objects/${prefix}/${hash}";
      path = drv;
    };
in
linkFarm "minecraft-assets" (
  [
    {
      name = "indexes/${id}.json";
      path = assetIndexFile;
    }
  ]
  ++ lib.mapAttrsToList mkAsset index.objects
)
