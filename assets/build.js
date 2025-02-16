import * as esbuild from 'esbuild'
import { sassPlugin } from 'esbuild-sass-plugin'
import { compressPlugin } from "@liber-ufpe/esbuild-plugin-compress"

let result = await esbuild.build({
  metafile: true,
  entryPoints: [
    "assets/css/**/*.scss",
    "assets/images/**/*.jpg",
    "assets/css/**/*.css",
    "assets/css/**/*.css.gz",
    "assets/css/**/*.css.br",
    "assets/script/**/*.js",
    "assets/script/**/*.js.gz",
    "assets/script/**/*.js.br",
    "assets/favicon/*",
  ],
  loader: {
    '.br': 'copy',
    '.gz': 'copy',
    '.min.js': 'copy',
    '.png': 'copy',
    '.jpg': 'copy',
    '.ico': 'copy',
    '.webmanifest': 'copy',
    '.svg': 'copy',
    '.webp': 'copy',
  },
  outdir: "public",
  minify: true,
  treeShaking: true,
  plugins: [
    sassPlugin(),
    compressPlugin({
      gzip: true,
      zstd: true,
      brotli: true,
      excludes: ["**/*.{avif,jpg,png}"]
    })
  ],
})
