+++
title = "Hugo のテーマを自作した"
date = 2020-03-15T23:52:03+09:00
tags = [""]
draft = true
toc = true
+++

このブログは [Hugo](https://gohugo.io/) という静的サイトジェネレータを使用している。

Hugo は出来ることが多く、多機能なテーマもたくさんあるが、個人的にシンプルで簡素なテーマを使用したい。
当初は [lithium](https://themes.gohugo.io/hugo-lithium-theme/) というテーマを使っていたが、 
Hugo のテーマ自作のハードルはそこまで高くないことを知り、
これを機に HTML や CSS を勉強してみようということでテーマを作成してみた。

<!-- toc -->

## テーマ作成

基本的には、 Hugo の公式ドキュメントや、これまで Hugo のテーマを自作した方々の Tips がインターネットの海にあるので、それを参照した。

### はじめに

 Hugo から練習用リポジトリ [HugoBasicExample](https://github.com/gohugoio/hugoBasicExample) が提供されている。
まずはこのリポジトリをクローンし、そこでテーマの自作を進めていく。

ちなみに、 Hugo 公式サイトで他のテーマと同じように紹介してもらうためには、上記の練習用リポジトリで正しくテーマ適用されるか、変なエラーが出ていないかが前提事項にあるので、基本的にはこの作業から始めたほうが良い。

### テーマの雛形作成

 HugoBasicExample をクローンしてきたら、 `cd hugoBasicExample` して `hugo new theme <テーマの名前>` で新しいテーマの雛形を作成する。
新しいテーマの雛形は以下のような構成になっている。

```
hugoBasicExample/theme/<テーマの名前>
├── archetypes
│   └── default.md
├── layouts
│   ├── _default
│   ├── index.html
│   └── partials
├── static
│   ├── css
│   └── js
└── theme.toml
```

 `archetypes` は、テーマのユーザーが `hugo new <ファイル>` で新しく記事を作成するときのテンプレートになるもの。
 default 以外にもテンプレートを用意できるので、テーマに合わせて必要であれば作成する。

 `layouts` は html のテンプレートが置かれている。
サイトの基本レイアウトを `_default` 、部品レイアウトを `partials` 下で作成していく。

 `static` は css や js ファイル、画像ファイルを格納する。

細かいことは公式サイトを参照する。

### 機能を追加する

テーマを新規に作成し、 html のテンプレートや css をいじっていけばそれなりのサイトが出来上がってくるが、 Hugo がサポートしていてユーザーがほしそうな機能はテーマに追加しておいたほうが良い（自分の思想に合えばの話）。

#### SNS Share Button

今どきはどのブロクの記事も SNS 各種のシェアボタンがついているので、同様に設定したほうが便利。

ただ自分はシンプルかつ簡素で SNS 連携もなし！といった思想でテーマを作成し始めたので、この記事を書いている段階では設定していません。
（omo さんの信者なので [このブログ](https://anemone.dodgson.org/) みたいにしようかなと考えていたので、そのうち Author の SNS 情報ボタンだけは追加するかも）

#### GoogleAnalytics

 Hugo では `config.toml` に GoogleAnalytics の UserAgent をサクッと設定できる。

```
googleAnalytics = "UA-123-45"
```

ユーザーが `config.toml` に GoogleAnalytics を設定しているかどうかは、 `with` を用いて判定できる（2行目）。

```html
{{ if not .Site.IsServer }}
  {{ with .Site.GoogleAnalytics }}
  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id={{ . }}"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '{{ . }}');
  </script>
  {{ end }}
{{ end }}
```

1行目は、ローカルサーバで確認するとき（`hugo server -t <theme>`）には設定しないという条件。

#### hugo generator

 Hugo コミュニティのために、 meta タグに generator を設定する。
`{{ .Hugo.Generator }}` で展開される。楽。

#### Search

このブログは全然記事がないので今は全く必要ないが、全文検索機能がほしいユーザーを想定して検索機能を追加する。

[この記事](https://koirand.github.io/blog/2018/pulp-search/)に検索機能の追加、検索語句のハイライトなどがよくまとまっているので参照。
著者の方はこの記事を書いたあとに検索機能の強化をしているようなので、この部分についてはあまり記事を参照せず自分でやってみようかと考えている（JavaScript がむずかしい）。

#### 目次自動作成

いわゆる TOC (TableOfContents) というやつ。
`{{ .TableOfContents }}` だけで h2 以下のレベルから目次を作成してくれるので便利。

 TOC 用の html テンプレートを partials 以下に作成し、一定語句数以上の記事かつユーザーが明示的に TOC 作成をオンに設定のときのみ、 TOC を展開する、などの条件を追加することでより使いやすくする。

### テーマの公開

テーマの作成が一段落したら、 Hugo 公式サイトで紹介してもらうように色々整備する。

テーマ公開までの流れは、 Hugo のテーマコレクションリポジトリ [hugothemes](https://github.com/gohugoio/hugoThemes) に テーマを公開してください、という issue を立てるところから始まる。
すると数日後までには issue を Hugo の contributor が確認し、テーマのレビューまでしてくれるので、なにか指摘があれば修正してコメントを返す。
問題がなくなれば、 issue がクローズされ、テーマコレクションリポジトリに submodule として追加され、 [公式サイト](https://themes.gohugo.io/) や [Twitter](https://twitter.com/GoHugoIO) で紹介される。

必要な作業は、テーマコレクションリポジトリに記載されている。
`theme.toml` の作成やスクリーンショットの準備、上述した HugoBasicExample での確認、 README での充分な説明など。

それなりに記載をしておけば少なくとも一つはスターが付く。また、 issue にテーマの改善点や Feature Request が登録される。
僕はこれまで書いてきたコードをどこかで紹介してもらう経験が殆どなかったので、自分のリポジトリにスターが付いたり、 Feature Request が飛んできたときは嬉しかった。

テーマを定期的に更新すれば、 [公式サイト](https://themes.gohugo.io/) で上の方に表示され続ける（と思われる）ので、今後も改善や機能追加を実施したい。

## SSG
Hugo のような静的サイトジェネレータ（Static Site Generator）は他にも色々ある。
 [StaticGen](https://www.staticgen.com/) を見ると、やはり JavaScript 製が多い印象を受ける。

まだ Hugo しか使用したことがないが、 GitHub でのスター数が多い Next.js や Gatsby など、最近良く見る他のツールも多々あるので、いずれ触って勉強したい。

また、今回のテーマ自作を通じて Hugo や SSG 自体にも関心を持ち始めた。
 Hugo はいきなり contribute するには（自分にとっては）大きすぎるので、シンプルな SSG （というか markdown converter）を自作している。

[gom2h](https://github.com/matsuyoshi30/gom2h)

 StaticGen に挙げられているような多機能なものとは程遠いが、シンプルで見やすいページは作成できていると思う（github-markdown.css を使っているので）。
このブログはまだ Hugo を使う（せっかくツールも自作したので）が、このツール作成を通じて Hugo 自体に contribute できるよう理解を深めていく。
ブログではない何かの公開にこのツール使ってみようかな。

## 参考情報

- [Hugo (公式ドキュメント templates)](https://gohugo.io/templates/)
- [Hugoのテーマを何個か作ったので知見をまとめてみる](https://blog.unresolved.xyz/how-to-make-of-hugo-theme/)
- [Adding dark mode to a Hugo static website without learning CSS](https://radu-matei.com/blog/dark-mode/)
- [HUGOテーマ(pulp)に全文検索機能を付けた](https://koirand.github.io/blog/2018/pulp-search/)