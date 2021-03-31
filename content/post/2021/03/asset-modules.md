+++
title = "自作の Hugo テーマに webpack の Asset Modules 使ってみた"
date = 2021-03-31T21:12:02+09:00
tags = ["frontend"]
draft = false
toc = false
backtotop = false
+++

[自作の Hugo テーマ](https://github.com/matsuyoshi30/harbor)で起こっていた問題について対応した軽いメモ書き

## 認識

自作 Hugo テーマ（Harbor）にある [issue](https://github.com/matsuyoshi30/harbor/issues/94) が起票されていた。内容は、「個別の記事を開いたとき、コンソールに『フォントデータが見つからない』というエラーが出る。 index ページだと出ない」というもの。

## 原因

Harbor では、 CSS の [@font-face 規則](https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face)を用いて、 `/static/fonts/` 以下にあるフォントデータからフォントを読み込んでいる。そして CSS ファイルは JS ファイルと合わせて webpack によって一つの JS ファイルにバンドルし、全てのページでバンドルした JS ファイルを読み込むという構成になっていた。

```css
/* noto-sans-jp-regular - japanese_latin */
@font-face {
  font-family: 'Noto Sans JP';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: local('Noto Sans Japanese Regular'), local('NotoSansJapanese-Regular'),
       url('../fonts/noto-sans-jp-v25-japanese_latin-regular.woff2') format('woff2'), /* Super Modern Browsers */
       url('../fonts/noto-sans-jp-v25-japanese_latin-regular.woff') format('woff'); /* Modern Browsers */
}

/* roboto-regular - latin */
@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: local('Roboto'), local('Roboto-Regular'),
       url('../fonts/roboto-v20-latin-regular.woff2') format('woff2'), /* Super Modern Browsers */
       url('../fonts/roboto-v20-latin-regular.woff') format('woff'); /* Modern Browsers */
}
```

上記の通り、 @font-face 規則でドメイン直下の `fonts` ディレクトリに格納されたフォントデータのソースを相対パスで参照していたことにより、 index ページ（例: `https://example.com`）からは該当のパスが参照できてフォントデータが取得できる一方、他のページ（例: `https://example.com/post/something`）からは参照できない状態になっていた。

だいぶ初期から出てたエラーのはずなのに。今まで気にしなかったのか。

## 対応

webpack v5 で導入された [Asset Modules](https://webpack.js.org/blog/2020-10-10-webpack-5-release/#asset-modules)という機能を使う。

これは jpeg や png などの画像やフォント、 JSON データを JS にバンドルさせる、もしくは JS 内に適切な外部参照の URI を注入するというもの。 v5 が出るまでは [url-loader](https://webpack.js.org/loaders/url-loader/) とか [file-loader](https://webpack.js.org/loaders/file-loader/) が用いられていたが、 v5 では webpack ネイティブで対応されるようになった。

使い方は[公式ガイド](https://webpack.js.org/guides/asset-management/#loading-fonts)の通り、 module.rules に対応させたいファイルタイプの拡張子と asset のタイプを指定するだけ。指定できる asset のタイプは `asset/resource` （バンドルしたいファイルは個別に出力して、JS内では外部参照という形にする）や `asset/inline` （JS内にエンコードしたファイルデータをまるっと注入する）など複数あるが、 `asset` としていすることで webpack が外部参照か JS 内にエンコードデータを入れ込むかを判断してくれるので便利。

 ```js
module.exports = {
  // ...
  module: {
    rules: [
      {
        test: /\.(woff|woff2)$/,
        type: 'asset',
      },
    ]
  }
};
```

公式ガイドの通りやってもうまくいかんなーとか思ってたら css-loader の options で `url: false` を指定していた。

webpack v5 は去年10月にリリースされていてもう半年たつのに全然内容知らなかった。フロントエンドはフレームワークの発展スピードもさることながら、ツールチェインまわりの進化も追わないといけなくて大変そう。

## 参考

- [Asset Modules](https://webpack.js.org/guides/asset-modules/)
- [最新版で学ぶwebpack 5入門 スタイルシート(CSS/Sass)を取り込む方法](https://ics.media/entry/17376/)
- [webpack@5の主な変更点まとめ](https://blog.hiroppy.me/entry/webpack5)
