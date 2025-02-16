{ pkgs, version }: pkgs.buildNpmPackage {
  inherit version;
  pname = "builder";
  src = ../../assets/.;
  npmDepsHash = "sha256-FiUYmW1gyZn1nzHcpb9Gp42nvJWEaTVUWKZ0kK53gd0=";
}
