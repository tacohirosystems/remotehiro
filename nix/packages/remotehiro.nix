{ self, pkgs, version, remotehiro, remotehiro-static }: pkgs.symlinkJoin {
  name = "remotehiro";
  paths = [ remotehiro remotehiro-static ];
  buildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/remotehiro \
      --set REMOTEHIRO_SERVER_STATIC_ASSETS_PATH "${remotehiro-static}/public" \
      --set REMOTEHIRO_SERVER_TEMPLATES_PATH "${remotehiro-static}/templates" \
      --set REMOTEHIRO_SERVER_NIX_PATH "${remotehiro}/bin/remotehiro" \
      --set REMOTEHIRO_SERVER_COMMIT_HASH "${self.shortRev or "\"dev\""}" \
      --set REMOTEHIRO_SERVER_VERSION "${version}"
  '';
}
