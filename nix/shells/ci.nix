{ pkgs, ... }: pkgs.mkShell {
  buildInputs = with pkgs; [ just sqitchSqlite openssl sass ];
}
