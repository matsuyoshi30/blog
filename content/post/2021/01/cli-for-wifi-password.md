+++
title = "Mac で接続中の Wi-Fi のパスワードを確認する"
date = 2021-01-31T20:58:29+09:00
tags = ["golang", "cli"]
draft = false
+++

ネットワークに接続する系の電子機器を買ったとき、うちでは毎回毎回テレビの裏に置いてあるルーターを手にとってパスワードを確認している。こういうとき手元の MBP でさくっとパスワードが確認できるとはやくて便利なんだけどなーと思っていたのだが、この前簡単に確認できることを知ったのでメモ。

## SSID 確認

macOS に標準で入っている `airport` というコマンドを使用する。 Apple では Wi-Fi 関連のプロダクトに AirPort という呼称を使用[^1]しており、このコマンドは AirPort 管理のインターフェースとして使うことができる。コマンドは以下のパスにあり、普通はパスが通っていないので、フルパスで指定するかリンクを作るかディレクトリにパスを通して使う。

```
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
```

使用方法は `--help` で確認できるがそこまでオプションは多くない。今回は利用している Wi−Fi のパスワードが知りたいので、 MBP がつないでいる SSID などの情報を取得する `-I` オプションを使う。

```sh
% /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
     agrCtlRSSI: -49
     agrExtRSSI: 0
    agrCtlNoise: -95
    agrExtNoise: 0
          state: running
        op mode: station
     lastTxRate: 540
        maxRate: 600
lastAssocStatus: 0
    802.11 auth: open
      link auth: wpa2-psk
          BSSID: ************
           SSID: ************
            MCS: 9
        channel: 136,-1
```

まあ SSID はメニューバー（画面上部）から Wi−Fi アイコンをクリックすれば確認できるので、こんなパスも通っていない深い階層にあるコマンドを使わなくてもよい。

## パスワード確認

先のコマンドで利用している SSID が確認できた。今度は `security` コマンドを使用してこの SSID のパスワードを確認する。

`security` コマンドには多くのサブコマンドがあるが、今回はキーチェーンに保存されているパスワードを平分で取得する `find-generic-password` を使用する。 `-l` オプションで SSID を指定し、 `-w` オプションでパスワードのみ出力する。

```
security find-generic-password -l <SSID> -w
```

`security` コマンドが認証情報にアクセスしてよいかという確認ダイアログが出るので、ユーザー名とパスワードを入力して許可もしくは常に許可を指定する。

## CLI 化

これらの情報は、 Python で Wi-Fi のパスワードを確認するスクリプトを作ったレポジトリを見つけて知った。これは Linux でも Windows でも確認できるようになっていて便利そう。

https://github.com/sdushantha/wifi-password

そこまで大きいプロジェクトでもないし、やっていることは実行環境がどの OS なのか判断して外部コマンドを実行しているだけなので、 Go で同じように書いてみた。まだ macOS のみ対応なので、そのうち気が向いたら他の OS も追加する。

https://github.com/matsuyoshi30/go-wifi-password


## 参考情報

- https://ss64.com/osx/airport.html


[^1]: 日本では先に別の会社が AirPort を商標登録していたため AirMac という名称を使用しているという話を知った。[wikipedia](https://en.wikipedia.org/wiki/AirPort)
