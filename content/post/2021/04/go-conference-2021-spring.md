+++
title = "Go Conference 2021 Spring の LT で喋った"
date = 2021-04-24T21:42:40+09:00
tags = ["golang"]
+++

タイトルの通り、4/24(土)に開催された Go Conference 2021 Spring に参加して LT 大会で喋った。

Gopher 道場の卒業大会で初めて LT というものをやってみて、そこから全く登壇とかしてなかったので少し緊張した。今回の Go Conference はオンライン開催で、当日は PC に向かってしゃべればよかったので助かったかも。これが大きなホールでたくさんの人々を前にマイクを握ってしゃべるとかだったら、緊張して当日お腹痛くなってたと思う。そもそも他の勉強会とか社内でもっと登壇経験積んでおけという話なのだが。

提出しておきながら言うのもおかしなことだが、 CfP は通ると思ってなかったので、通過連絡が来たときは結構びっくりした。 Go Conference の CfP について締切当日に気付き、最近作った CLI ツールの話が LT にちょうどいいかなと思ってあまり内容を推敲することなく提出した。（以下 CfP の内容）

```
Go言語には、画像処理のための標準パッケージ、フォント周りの準標準パッケージが提供されています。これらのパッケージを用いて、JS製のCarbonやRust製のSiliconのようなソースコード画像化ツールを作成しました。本セッションでは画像処理やフォント周りのパッケージの使用方法、簡易的なCLIツールの作成方法を紹介します。
```

なんでこの CfP で通ったのか不思議なのだが、多分同じようなテーマで CfP 出した人が他に少なかったのだと思う。他の方々のセッション内容説明文を読んでみてもみんな結構詳しく書いていて、自分の内容の薄さを痛感した。

過去の Go Conference でも画像処理についてのセッションは何回かあったらしく、それには CfP を出したあとに気付いた。なるべくかぶらない内容にしようにスライドを作ったつもりだが、あとから見直せばもっと後半の内容を話したり実際作ったツールの実装とか話せばよかったなと反省した。

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRcCM0PB1Zvy6TUbaH4dZkXVpiR6nEgDCNrQ4w_bZ32dVarv4gaJDJAara4Rn0hUQsHpeg89DWgOsBn/embed?start=false&loop=false&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true" style="width:100%"></iframe>

登壇は緊張はしたけどめちゃくちゃ楽しかった。個人的には聞き手として参加するよりも充実感があったし、次も登壇したいというアウトプットに対するモチベーションが高まってきた。まずは緊張してて当日他のセッションあまり聞けなかったので、アーカイブみて勉強しよう。

- [GoCon Webpage](https://gocon.jp/)
- [Go Conference 2021 Sprint リンク集](https://blog.golang.jp/2021/04/go-conference-2021-spring.html)
- [Go Conference 2021 Spring & ハンズオン × 懇親会 togetter まとめ](https://togetter.com/li/1703869)
