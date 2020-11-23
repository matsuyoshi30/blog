+++
title = "自作の Hugo テーマに ESLint, Prettier を導入した"
date = 2020-11-22T23:21:51+09:00
tags = ["frontend"]
draft = false
toc = true
+++

このブログは [Hugo](https://gohugo.io) という静的ジェネレータを使用していて、ブログテーマは拙作の [harbor](https://github.com/matsuyoshi30/harbor) を使用している。

ありがたいことにそこそこスターを頂いていて、ポツポツと contribute してくれる人もいるので、継続してメンテや改善に取り組んでいきたいと思っているが、品質管理に SonarCloud というサービスを使うだけで、 linter や formatter の整備ができていなかった。ブログテーマで主に CSS や JavaScript を使用しているので、 ESLint や Prettier を導入してみた。

導入の手引きや細かいルールなどは公式ドキュメントを参照すればよい。ここでは [harbor](https://github.com/matsuyoshi30/harbor) への導入履歴のようなかたちで記す。

<!-- toc -->

## ESLint

[ESLint](https://eslint.org/) とは JavaScript の静的検証ツール。単純な構文チェックやコードスタイルの統一に使用できる。またユーザーが多くの検証ルールを追加することができるので、自分のプロジェクト独自のルールを設けることができる。

npm を利用してインストールする。

```
% npm install --save-dev eslint
```

`eslint`は別途作成する設定ファイルで定義された内容のルールで実行される。手入力で作成してもいいし、`eslint --init`というコマンドを用いると対話形式で定義内容を設定できる。

設定ファイルは`.eslintrc.*`という形式で作成する。`eslint`コマンドで作成する場合は、 JSON, YAML, JavaScript の形式から選択する。自分は JavaScript 形式で手入力で作成した。

```javascript
module.exports = {
  env: {
    browser: true
  },
  extends:'eslint:recommended',
  parser: '',
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  plugins: [],
  rules: {},
};
```

各設定項目の意味や何が設定できるのかは[ユーザーガイド](https://eslint.org/docs/user-guide/configuring)に書かれているのでそれを参照する。軽く書くと、

- `env`: 検証対象の前提条件や、どの環境で用いられるものかを設定する。ここではブログテーマで使う JS なので`browser`を設定。
- `extends`: 拡張ルールを設定する。ここでは`eslint`コマンドでも設定される`eslint:recommended`を指定。適用されるルールも公式ページに載っているので、これを確認して追加したいルールがある場合は別途設定するか、`eslint:all`を設定する。
- `parser`: パーザーを指定する。デフォルトでは [espree](https://github.com/eslint/espree) というパーザーが使用される。ここでは検証対象が JS のみなのでこれでよいが、今後は TS 移行も考えており、その場合はパーザーに`@typescript-eslint/parser`を指定する（別途`@typescript-eslint`の導入が必要）
- `parserOptions`: 適用する JS のバージョンなどを指定する。
- `plugins`: サードパーティー製の ESLint 用プラグインを設定できる。
- `rules`: ESLint や plugins で設定されるルールに対して独自にルールを上書きする。ルールIDに対して`off`、`warn`、`error`で設定。


## Prettier

[Prettier](https://prettier.io/) はソースコードを整形してくれるフォーマッター。 JavaScript だけでなく色々なファイル形式をサポートしている。業務では普段 Go を書いているので、言語がフォーマットをサポートしていることが当たり前だという感覚があったが、デフォルトでフォーマットをサポートしていない言語で OSS を作ってみるとそのありがたさが分かる。 harbor に時々もらう PR でコードスタイルが変だったり、そもそも結構バラバラであることに気づいた。

ESLint でもコードスタイルのチェックや整形は可能だが、「ちゃんとフォーマットしようと思うと設定項目が膨大になる」「`eslint --fix`を実行してルール違反を摘出する際、設定によってはコードが完全にフォーマットされない場合がある」など、微妙な点がある。 Prettier ではデフォルトの整形ルールが存在するため、よほどのこだわりがなければユーザーが多くの項目を設定する必要がないし、確実にソースコード全体を整形してくれる。

そこで、 format は prettier で、 lint は eslint で実行する、というように併用するのが便利（デファクトスタンダードっぽい）。

npm を利用してインストール。

```
% npm install --save-dev prettier
```

個別に設定したい項目がある場合は、`.prettierrc.*`の形式で設定ファイルを作成する。

```javascript
module.exports = {
  "trailingComma": "es5",
  "semi": false,
  "singleQuote": true
};
```

「よほどのこだわりがなければデフォルトで問題ない」が、設定ファイルも使ってみたかったので、ここでは軽く作成してみた。設定できるオプションは[公式ページ](https://prettier.io/docs/en/options.html)を参照する。

### go template も整形したい

Prettier 導入を検討し始めたのは、 HTML の <head> タグ内を修正する PR をもらったとき、 <script> タグ内のコードスタイルが気に入らなかったのがきっかけだった。 Prettier は HTML 形式もサポートしているが、 Hugo のテーマということで HTML 内には mustache 記法（`{{.}}`で書くテンプレートの記法）がたくさんあり、このまま Prettier を実行すると mustache 部分が普通の HTML タグ内文字列として改行なしで一行になってしまう。

`.prettierrc.js`で設定できるオプションでなんとかならないかと調べていたら、ある時期から Prettier のコア部分で新たにサポートする形式を増やすのではなく、[プラグインで対応する方針に変わった](https://github.com/prettier/prettier/issues/6034#issuecomment-647406368)ようで、 [go template 用のプラグイン](https://github.com/NiklasPor/prettier-plugin-go-template)があった。プラグインを導入して README に書かれている通りに`.prettierrc.js`に追記することで対応。

```javascript
module.exports = {
  ...
  "overrides": [
    {
      "files": ["*.html"],
      "options": {
        "parser": "go-template"
      }
    }
  ]
};
```

## ESLint と Prettier を併用する設定

[prettier-eslint](https://github.com/prettier/prettier-eslint) というツールを使う。これはまず Prettier でコードを整形したあとに、`eslint --fix`を実行して検証してくれるというもの。これにより ESLint と Prettier での整形ルールの競合を防ぐ（実行順序的に ESLint の設定が優先される）。前は [eslint-plugin-prettier](https://github.com/prettier/eslint-plugin-prettier) というプラグインが使用されていて、 ESLint のプラグインから prettier を呼び出すなど、設定が煩雑になっていたようだが、`prettier-eslint`ではその必要がない。

npm でインストール。

```
% npm install --save-dev prettier-eslint
```

`package.json`に以下のように script を定義する。`prettier-eslint`はコード整形用のツールのため、 ちゃんと Lint したい場合は`eslint`も実行する必要があるので注意。

```json
{
  ...
  "scripts": {
    "format": "prettier-eslint --write $PWD/'static/src/**/*.js' $PWD/'layouts/**/*.html'; eslint $PWD/'static/src/**/*.js'"
  },
  ...
}
```

一応内容をみてみると、

- `--write`オプションにより実行結果でファイルを上書き
- `'`(シングルクォート)で囲ったパスはディレクトリをトラバースして検証する
  - ここでは`static/src`以下のすべての JS ファイルと、`layouts`以下のすべての HTML ファイルを対象としている


## コミット時に自動で prettier-eslint を実施

一応、ここまでで、`npm run format`を実行することにより、は`static/src`以下のすべての JS ファイルと、`layouts`以下のすべての HTML ファイルに対して、コード整形（prettier）と Lint （ESLint）を実行することができるようになった。

だが、修正後にいちいち`npm run format`するのもめんどくさいし絶対に忘れる。なので次は`git commit`時に自動で実行されるように設定する。

### lint-staged

コミット時に毎回すべてのファイルに対して Prettier や ESLint を適用する必要はない。 [lint-staged](https://github.com/okonet/lint-staged) を使用することで、`git add`でステージングされたファイルについて特定のスクリプトを実行する。

npm でインストール。

```
% npm install --save-dev lint-staged
```

`package.json`に以下を追記。

```json
{
  ...
  "lint-staged": {
    "*": [
      "prettier-eslint --write $PWD/'static/src/**/*.js $PWD/'layouts/**/*.html'; eslint $PWD/'static/src/**/*.js'"
    ]
  },
  ...
}
```

### husky

やりたいことは Git hooks を作成することで Git コマンドに対して特定のスクリプトを実行、だがいちいちシェルスクリプトを作って`.git/hooks`以下において…とやるのはめんどう。設定を書くだけで Git hooks をよしなに準備してくれる [husky](https://github.com/typicode/husky) を使う。

npm でインストール。

```
% npm install --save-dev husky
```

`package.json`に以下を追記。

```json
{
  ...
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  ...
}
```

`pre-commit`（コミット前）に`lint-staged`を実行する。`lint-staged`はこの前に設定した内容。

#### `git commit`したのになんか動かない

パッと導入してさて試そうと思ったのだが、なんかそのままコミットされてしまう。`.git/hooks`を削除して`husky`を再インストールしたり色々試してみたがわからず…なんでや…と思っていたら、 [npm のバージョンが原因](https://github.com/typicode/husky/issues/788#issuecomment-731698581)だった。

npm のバージョンを v7 から v6 にしてはじめから。そしたらうまくいきました。


## 参考情報

以下の参考情報をみながら試行錯誤して設定した。多分いらない設定とかもっとこうしたほうが良いというものもあると思う。

- [ESLint 最初の一歩](https://qiita.com/mysticatea/items/f523dab04a25f617c87d)
- [Prettier 入門 ～ESLintとの違いを理解して併用する～](https://qiita.com/soarflat/items/06377f3b96964964a65d)
- [Prettier と ESLint の組み合わせの公式推奨が変わり plugin が不要になった](https://blog.ojisan.io/prettier-eslint-cli)
- [ぼくの husky で設定した pre-commit が動かない。。。](https://serip39.hatenablog.com/entry/2020/07/28/073000)

あと、 Hugo 使ってる人は [harbor](https://github.com/matsuyoshi30/harbor) の導入、ご検討ください。
