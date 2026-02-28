{ pkgs, version }: pkgs.stdenv.mkDerivation {
  inherit version;
  name = "remotehiro-migrator-source";
  srcs = [
    ../../.

    (pkgs.fetchgit {
      url = "https://forgejo.quoll-owl.ts.net/remotehiro/data-migrations";
      rev = "e81ad7f7e5f04361a4eb487334982e1739354ad3";
      sha256 = "sha256-XzYLyOYqQNuH2P7h2rWYcL5yjb6DG0OWOtM8L5CmpOM=";
      # sha256 = pkgs.lib.fakeSha256;
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
