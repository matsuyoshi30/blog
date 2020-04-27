+++
title = "「Goならわかるシステムプログラミング」を読んだ"
date = 2020-04-28T00:52:49+09:00
tags = ["reading"]
draft = false
toc = false
backtotop = false
+++

熱いうちになかなか鉄が打てないタイプの人間です。

[「Goならわかるシステムプログラミング」](https://www.lambdanote.com/products/go)を読破した。購入したのはだいぶ前だが、途中まで読み進めて放置していたので、改めて最初から読み直し＆勉強し直してみた。

購入したときは Go を知ってすぐだったような気がする。放置していたのも、そのときの Go の知識レベルが追いついていなかったために、読み進めるのがつらくなったからだろう。
現在も業務では Go を触っているわけではない。だが、昨年は Gophere Dojo に参加して Go の基本的な知識を習得し、個人的にいくつか小さいツールを Go で書き、最近は Go で書かれた小規模の OSS に PR 送ったりした。それなりに知識は習得できていると思う。案の定、前回読んだときよりも今回はスムーズに読み進めることができた。

この本は、システムプログラミングのハードコアなところからいきなり始めるのではなく、 interface や goroutine や channel など Go 自体の紹介も兼ねられているのが良いところの一つだ。
例えば第2章、第3章はそれぞれ io.Writer、 io.Reader の紹介から入り、 OS が担う抽象化の役割を説明しつつ前段階で紹介した interface との関連性を明らかにしていく。第4章は goroutine、 channel の紹介で、最小限の goroutine パターンを挙げながら説明している。第5章以降は、それまで説明した Go の機能を用いつつ、システムコールやネットワーク、ファイルシステム、プロセス、シグナル、メモリなどを解説し、最終的にはコンテナまで対象に含んでいる。
Go 自体を紹介する章では章末に問題が用意されているのも良い。解説された Go の機能に対する理解をすぐ確認できるし、それが確認できれば後半のシステムプログラミングの解説もスムーズに入ってくる。

もともとは[ASCII で連載していた記事](https://ascii.jp/serialarticles/1235262/)を書籍にまとめたものなので、購入前に記事を流し読みして確認しておくと良い。

システムプログラミングはある種泥臭い領域だと思う。少しずつステップを踏めばそこまで難しいことをやっているところは多くない印象で、地道さが要求されると感じる。（システムプログラミングの90%も知らないで言っています）
進歩のペースが速いこの業界でも、数十年前との差が比較的広がっていない領域で、今後もそこまで広がらないだろう。今のうちにこの部分の知識をつけておくとのちのち役に立つかも、という思いで読破したが、内容も面白いしもっと詳細な部分を知りたい！という気持ちになってくる。
今は[Rui さんのコンパイラ本](https://www.sigbus.info/compilerbook)を読んで C Compiler を自作しているので、それが終わったら「30日OS本」にもチャレンジしたい。

Go も引き続き書き続けたい。同じ著者の[Real World HTTP の第2版](https://www.amazon.co.jp/Real-World-HTTP-%E7%AC%AC2%E7%89%88-%E2%80%95%E6%AD%B4%E5%8F%B2%E3%81%A8%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AB%E5%AD%A6%E3%81%B6%E3%82%A4%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%8D%E3%83%83%E3%83%88%E3%81%A8%E3%82%A6%E3%82%A7%E3%83%96%E6%8A%80%E8%A1%93/dp/4873119030)が最近出たので読んでみたい。
読みたい本がどんどん溜まって大変だ。

メモや問題の回答、勉強中に書いたコードは以下のリポジトリに置いている。

[勉強用リポジトリ](https://github.com/matsuyoshi30/go-systems)