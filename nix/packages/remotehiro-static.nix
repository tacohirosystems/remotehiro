{ self, pkgs, asset-builder, version }:
let
  rev = self.shortRev or "dev";
in pkgs.stdenv.mkDerivation {
  inherit version;
  name = "remotehiro-static";
  src = ../../.;

  nativeBuildInputs = with pkgs; [ minhtml ];

  installPhase = ''
    mkdir $out

    # Static assets
    ${asset-builder}/bin/builder
    cp -r public/ $out

    # HTML templates
    minhtml \
      --preserve-brace-template-syntax \
      --minify-css \
      --minify-js \
      templates/**/*.html

    cp -r templates $out
  '';
}
