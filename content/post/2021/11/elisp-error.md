+++
title = "はじめて Emacs Package かいた & MELPA に登録した"
date = 2021-11-01T23:04:35+09:00
tags = ["emacs"]
draft = false
+++

ちょっと前の出来事だったけど今更かく。

## Writing Emacs Pacakge

[ここ](https://blog.matsuyoshi30.net/posts/2021/02/28/cli-tool-for-generating-image-from-code/)でも書いた[ソースコード画像化ツール](https://github.com/matsuyoshi30/germanium)について、 [Vim のプラグイン](https://github.com/skanehira/denops-germanium.vim)を書いてくださった方がいた。 Vim あるなら Emacs もあったほうがいいよな、ということで Emacs 用のパッケージを自作した。

作成したツールは Go 製で、コマンドラインで使用するツールなので、 Emacs 上でコマンドを実行するようなパッケージになる。そのような処理を elisp でどう書くかは色々やり方があるようなのだが、ちょうどガイドとしてぴったりな記事が [Qiita](https://qiita.com/tadsan/items/17d32514b81f1e8f208a) にあったのでこれを参考に shell-command を利用した。コマンドライン引数やオプションを含めて実行したいコマンド文字列を組み立てる関数と実際に shell-command で実行する関数を分けて実装した。

また、コマンドラインで実行するツール本体が無いユーザーに対応するために、別途ツールをインストールする用の関数も作った。 `go install` でインストールするようになっており Go 自体も必要で、ここは他の方法もサポートした方が良さそうだ。

## Publising Emacs Package

せっかくパッケージを自作したので、 Emacs の非公式パッケージレポジトリである MELPA にこれを追加しようと思いついた。 MELPA は GitHub のレポジトリに PR を送ってそれがマージされることでパッケージを登録することができる。 MELPA に登録されることで、パッケージレポジトリに MELPA を使ってるユーザーなら `package-install germanium` でインストールできるので便利。

PR はテンプレートが準備されており、そこに書かれたこと（コントリビューションドキュメント読んだかとか、ちゃんとパッケージはバイトコンパイルできるかとか）をクリアすると MELPA のメンテナがパッケージをレビューしてくれる。このレビューを通ってマージされれば MELPA にパッケージが登録される。

今回は[いくつかの指摘](https://github.com/melpa/melpa/pull/7696#issuecomment-907852550)をもらった。例えばエラー通知について。

elisp でユーザーにエラーを通知する方法はいくつかあるが、これは通知すべきエラーの種類によって使い分けるようマニュアルに記載されている。エラーというよりユーザーになんかしらの情報を伝えるのは `message` 、ユーザーの不適切な操作により通知すべきエラー（履歴がないのに履歴を遡るコマンドを実行するなど）は `user-error` を用いる。その他一般的なエラー通知の場合 `error` を使用する。

指摘はもらったものの、ブロッカー足り得るものはなかったという判断がされ、するっとマージされた。エラーについての指摘はすぐ直したけどそれ以外の指摘の対応を忘れてて、これ書いてるときに気づいて対応した。

## 余談

Vim プラグイン、 Emacs パッケージときたので VSCode の Extension も作りたいんだが、どうも別プロセスとしてコマンドを実行したりそれがファイルを出力するようなやつだったりするのがどう作ればいいんだがよく分からない。 [Extension 作成の丁寧なガイド](https://code.visualstudio.com/api/get-started/your-first-extension) もあるのですんなりできるかなとか妄想してたらドカンと躓いたので作業を止めてしまった。

VSCode よく知らないけどブラウザでも同じようなのが動くみたいだし、ここらへんセキュリティ的に防いでたりするのかな？ 


## 参考

- [Emacsからの安全なシェルコマンド実行](https://qiita.com/tadsan/items/17d32514b81f1e8f208a)
- [How to Signal an Error](https://www.gnu.org/software/emacs/manual/html_node/elisp/Signaling-Errors.html)

