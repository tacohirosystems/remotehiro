{ pkgs }: pkgs.stdenv.mkDerivation {
  pname = "some-sass-language-server";
  version = "2.3.8";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/some-sass-language-server/-/some-sass-language-server-2.3.8.tgz";
    hash = "sha256-dTNM1MBb5RLwySTMZZWvHtwlpoSdlRQnG6hzaYpVXaw=";
  };

  nativeBuildInputs = with pkgs; [ makeWrapper ];
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/lib/node_modules/some-sass-language-server $out/bin
    cp -r . $out/lib/node_modules/some-sass-language-server/
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/some-sass-language-server \
      --add-flags $out/lib/node_modules/some-sass-language-server/bin/some-sass-language-server
  '';
}
