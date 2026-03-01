{ pkgs, version }: pkgs.stdenv.mkDerivation {
  inherit version;
  name = "remotehiro-migrator-source";
  srcs = [
    ../../.

    (pkgs.fetchgit {
      url = "https://forgejo.quoll-owl.ts.net/remotehiro/data-migrations";
      rev = "151553928751b7bff66baf9695d4020aa6102fbe";
      # sha256 = pkgs.lib.fakeSha256;
      sha256 = "sha256-3+pOaxW8lXXbEX50y7EoyeGtatRe0JqauI0dILGRX5A=";
      name = "data-migrations";
     })
  ];

  sourceRoot = ".";
  nativeBuildInputs = with pkgs; [ sqitchSqlite ];

  buildPhase = ''
    mv $(find . -name "*-source")/* .
    mv data-migrations sql/data_migrations/

    export SQITCH_CONFIG=sqitch.conf
    sqitch config --unset target.remotehiro.top_dir
    sqitch config --add target.remotehiro.top_dir $out/sql/migrations

    sqitch config --unset target.remotehiro-data.top_dir
    sqitch config --add target.remotehiro-data.top_dir $out/sql/data_migrations

    sqitch config --unset target.remotehiro-warehouse.top_dir
    sqitch config --add target.remotehiro-warehouse.top_dir $out/sql/warehouse_migrations
  '';

  installPhase = ''
    mkdir -p $out/bin

    cat sqitch.conf
    cp sqitch.conf $out/sqitch.conf
    cp -R sql $out/sql
  '';
}
