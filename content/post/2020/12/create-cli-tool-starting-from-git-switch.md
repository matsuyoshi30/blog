+++
title = "git switch からはじめる CLI ツール作成"
date = 2020-12-06T00:00:00+09:00
tags = ["cli", "golang"]
draft = false
toc = true
+++

この記事は「[弁護士ドットコム Advent Calendar 2020](https://qiita.com/advent-calendar/2020/bengo4com)」の 6 日目の記事です。昨日は [@euxn23](https://qiita.com/euxn23) さんの「[babel 環境における Polyfill のビルド最適化と async-await の扱い](https://blog.euxn.me/xsymsnvwjbkaaaaaaacrrg)」でした &#x1f389;。

軽く自己紹介を。私は弁護士ドットコムという会社で[クラウドサイン](https://www.cloudsign.jp/)という電子契約サービスのバックエンドエンジニアをやっています。今年の9月末に前職の SIer を退職して10月に入社しました。前職ではあまりコードを書いていませんでしたが、去年の5月頃に [Gopher Dojo](https://gopherdojo.org/) という勉強会に参加したり、 Go をプライベートで書いたりしていたらいつの間にか転職していました。

今回は `git switch` というコマンドについて少し見てから、 CLI ツール兼 git のオレオレサブコマンドを Go で作って配布するという二部構成で話をします。

<!-- toc -->

## git switch

Git 2.23 (リリースされたのは一年以上前)で `git switch` と `git restore` が導入されました。リリース時に公開された [GitHub のブログポスト](https://github.blog/2019-08-16-highlights-from-git-2-23/)では、「 `git checkout` でいろんな事ができるため、機能を『ブランチに対する操作』と『ファイルに対する操作』で分けることを目的として導入された」とあります。


### 使い方

前述の通り `git checkout` の代替として導入されたので、 `git checkout` と比較しながら見てみます。

基本的にできることは変わりません。

```sh
% # ブランチの切り替え
% git switch <branch>
% git checkout <branch>

% # ブランチの新規作成
% git switch -c <branch>
% git checkout -b <branch>

% # 切り替え前のブランチに戻る
% git switch -
% git checkout -


% # ファイルの変更を取り消す
% git restore <file>
% git checkout -- <file>

% # ファイルの状態を特定のコミット時に戻す
% git restore --source -- <commithash> <file>
% git checkout <commithash> -- <file>
```

### 周辺調査

一年以上前の情報にいまさら気づいて、普段 `git checkout` としているところを `git switch` 、 `git restore` に移行してみようと思ったのですが、 switch は手癖でついつい checkout と打ってしまいます（ restore はメッセージで出てくるのでついつい使ってしまい、いつの間にか覚えました）。そもそも `git switch` を使ってるひとってどれだけいるのかなと思い、社内で軽くアンケートを取ってみたところ、以下の結果が得られました。

- svn から git に移行して久しいので checkout に慣れてしまった
- alias で `git co` とか `g co` で checkout
- コマンドなんか打たずに履歴から `^R git ^R^R ^W`
- sw がどっちも左薬指なのがいくない
- GUI派、 [lazygit](https://github.com/jesseduffield/lazygit) 、 [tig](https://github.com/jonas/tig) などのツールを使っている
- etc...

案の定 switch を使っている人はあまりいませんでしたが、最近 switch に移行し始めたという方も（わずかながら）いました。

ドキュメントやマニュアルにもある通り、 switch や restore は実験的で挙動が変わる可能性があります ( `THIS COMMAND IS EXPERIMENTAL. THE BEHAVIOR MAY CHANGE.` ) が、これから git を使い始める人にとっては checkout でブランチもファイルも操作するより、ブランチは switch で、ファイルは restore で操作するほうが直感的で分かりやすそうです。そのうち後輩に「まだ `git checkout` なんて UNIX 哲学[^1]に反するもの使ってるんですか？」と煽られないためにも、今のうちに `git switch` に慣れておきたいところです。


### 矯正の道

手癖で checkout と打って Enter を押してしまうのはどうしようもないので、人間が頑張るのではなくそのまま実行されずに機械側で矯正してくれる仕組みを検討してみます。作業端末は MacBook Pro 13-inch 2020、 OS は macOS Catalina version 10.15.7 です。


#### alias を設定する

`git checkout` としたら警告を出すような alias を設定したいところですが、 `alias git checkout='...'` のように alias として設定する文字列に空白を含めることはできません。サブコマンドを含めた alias を設定したい場合は、コマンドと同じ関数を用意して、関数内で引数を判別して処理することが必要です。

今回の場合は git コマンドに相当する関数を定義すればよいのですが、単純に zshrc ファイルに git 関数を定義すると zshrc を読み込むときにプロセスが終了して zsh が正しく起動しません[^2]。なので、別名で関数を定義してそれを alias として設定します。

```sh
gat () {
    if [ "$1" = "checkout" ]; then
        echo "Use switch for operating branch"
    else
        git "${@}"
    fi
}
alias git='gat'
```

これで `git checkout ...` と打つと機械がメッセージを出して矯正を促してくれるようになりました。ただ、変な関数を定義してそれを alias で設定して、というのはそんなにキレイなやり方ではない気がします。


#### 養成ギプスを使う

[git-switch-trainer](https://github.com/sonatard/git-switch-trainer) という Go 製のツールがあります。これは上と同じような考え方で、サブコマンドが checkout のときは switch か restore を使用するようメッセージを出力して処理を実施せず、それ以外の場合はそのまま処理してくれます。 git config に設定されている alias まで確認してくれるので、例えば `alias.co=checkout` のような alias が設定されていても、 `git co ...` と打つとメッセージが出力されます。

ただ、これも別途 alias の設定が必要です。こちらは上のように変な関数を定義する必要はなく、 git が上記のツール経由で行われれば良いので、インストール後に `alias git='git-switch-trainer'` とするだけで完了です。


#### パッチを当てる

そもそもいまだに git が checkout を用意しているから矯正が難しいのであって、 checkout がなくなれば switch を使わざるを得ず自然と矯正できます。実際のソースコードに手を入れて checkout を受け付けないようにしましょう。

まずは git をクローンします。

```sh
% git clone https://github.com/git/git
```

autoconf がないとビルドできないので、 homebrew でインストールします。

```sh
% brew install autoconf
```

configure を作ってビルド、簡単ですね。

```sh
% make configure
% make
```

ビルドできることを確認できたら実際のソースコードに手を入れます。といっても checkout を受け付けないようにするだけなのでエントリポイント周辺をたどればすぐに終わります。

git はビルトインされているサブコマンド群を commands という配列に定義しており、サブコマンドを判別して処理を実行する際は commands から該当のサブコマンドを取得して処理しています。つまり、この配列から checkout を消してしまえばよいわけです。

該当の箇所は[ここ](https://github.com/git/git/blob/3a0b884caba2752da0af626fb2de7d597c844e8b/git.c#L489)なので、これだけ行削除して再ビルドします。

```sh
% make
...
% ./git checkout -b ttt
git: 'checkout' is not a git command. See 'git --help'.
```

これで alias の設定などせずに checkout の使用を封じることができました！


#### 道の終わり

矯正の道、色々見てきましたが、個人的にいいなと思うのは2番目の養成ギプスです。1番目は方法として何となくダサいし、3番目は無いですね。一応やる人は自己責任でお願いします（いないと思いますが）。他に良い方法をご存知の方はぜひ教えて下さい。

まあ、 checkout がなくなるわけでもないし、無理に switch にして作業効率が落ちるくらいなら、変えずにそのまま checkout で続けた方が絶対に良いと思います（ﾃﾉﾋﾗｸﾙｰ）。


## git のサブコマンド

ここまで `git switch` について見てきましたが、 git には他にもたくさんサブコマンドが用意されています。私の環境は139個もありました。みなさんはどれくらい駆使してますか？私は10個にも満たないと思います。

```sh
$ git help -a | grep -E '^\s' | wc -l
139
```

また、「私の環境は」と述べたように、 git はビルトインされているコマンドとは別に、オリジナルのサブコマンドを作って `git <subcommand>` と使うことができるようになっています。みなさんもサブコマンドを作ったりインストールしているかもしれませんが、その場合は上のコマンドだとより大きい数字が出ていると思います。

オリジナルのサブコマンドがどうやって実行されるかですが、 git は続くコマンドを実行するとき、以下の順序で該当のコマンドを探します[^3]。

- `git --exec-path`
- 環境変数`GIT_EXEC_PATH`で設定されている先
- ビルド時に Makefile で指定された $(gitexecdir)
- 環境変数`PATH`で設定されている先

順序の最後にあげた通り、実行パスの通っているディレクトリ以下に `git-<subcommand>` という実行ファイルを置くことで、独自の git サブコマンドを実行することができます。ビルトインされているコマンドは優先順位の高いパスにあり、同名で定義してもビルトインのほうが実行されるので、サブコマンドは違う名前にしなくてはいけません。

さて、前半では `git switch` について見てきましたが、ブランチだけではなくて他にもスイッチできそうなものがあります。そう、それは**ユーザー**ですね。タイトルの「 `git switch` から始める」とはブランチではなくユーザーのことでした。

 git では以下のコマンドを実行することでユーザーを変更できますが、いちいちこんなコマンド打つのはめんどくさいです。ブランチの切り替えのようにサブコマンドで簡単にユーザーを切り替えることができれば、このめんどくささから解放されます。

```sh
% git config [--global] user.name <username>
% git config [--global] user.email <useremail>
```

「ユーザー切り替えたいなあ」なんて思うことはほぼ無いのですが、せっかくブランチの他にスイッチできそうなものがありますし、 git の独自サブコマンドを作って実行する方法も知ることができたので、ユーザースイッチのサブコマンドを作ってみましょう。


### Go

今回は Go を採用します。単純な shellscript で作ってもよい（ git 本体でも shellscript でサブコマンドを作っているものがある）のですが、業務で Go を書いたり簡単な CLI ツールを作るのに Go をよく使っているという個人的な理由から、ここでは Go で書きます。

Go はコンパイルがサクッとできて型もあるので安心感があります。また最近は Go 製の CLI ツールがたくさんあり、お手本にできる参考情報も多いです。バイナリの配布も簡単なので、いざ OSS として作り始めるときには選びやすいと思います。


### フレームワーク

上述の通り、最近は Go 製の CLI ツールが多いと感じますが、それを支える要因の一つとして CLI ツールを作る際に便利なフレームワーク、ライブラリが充実していることがあります。ここでは便利で有名なものをさらっと見てみます。

#### [spf13/cobra](https://github.com/spf13/cobra)

kubernetes や GitHub CLI にも採用されている最も有名なフレームワークです。コマンドを rootCmd で定義してサブコマンドを rootCmd に追加する方法なので、サブコマンドごとにファイルを分けて実装しやすいです。単体の CLI ツールで多くのサブコマンドを用意したい場合にはこれを選ぶと間違いないと思います。

cobra は機能が豊富という点が一つの魅力ですが、作りたいツールから見ると多すぎるという場合もあります。

#### [urfave/cli](https://github.com/urfave/cli)

README にある通り、軽量かつシンプルな CLI フレームワークです。サブコマンドが少ないなど簡単な CLI ツールをサクッと作りたいときにはこれを選ぶと良いと思います。

個人的には kubernetes や GitHub CLI くらい大きいものを作ることがないので、大体これを選んでいます。

#### [manifoldco/promptui](https://github.com/manifoldco/promptui)

上の2つと毛色が異なり、インタラクティブな CLI ツールを作るときに選びます。 README にもありますが、フレームワークというよりもライブラリで、上の2つのような CLI フレームワークと同時に利用することができます。

簡単な入力インターフェースを定義することができ、かつ入力のバリデーションを同期的に行うことができます。インターフェイスは実際にユーザーに入力させるものと選択させるものの2つを利用できます。弊社でも業務で使用する簡単なツールの一部にこれを利用しています。


今回作成するのは `git config user.name ...` を代替する簡単な CLI ツールです。フラグオプションは --global かどうかのみ、かついちいちユーザー名やメールアドレスを入力するのがめんどくさいという動機から作成するものなので、 CLI フレームワークは用いずにオプションは標準の flag を使用、ライブラリとして promptui を採用しました。


### 実装

簡単な CLI ツールなので実装において特筆する箇所はほとんどありません。今回作成するツールは git のユーザー切り替えを簡単にするものなので、ツール側で切り替える git のユーザー情報を保持しておく必要があります。今回は JSON 形式の config ファイルを作成して、必要に応じてファイルを読み書きするようにしました。 Go は実行時の OS を `runtime.GOOS` で判別できるので、以下のように OS ごとに config ファイル生成先を制御します。

```go
configDirName := "gitsu-go"

switch runtime.GOOS {
case "darwin":
	return filepath.Join(os.Getenv("HOME"), "/Library/Preferences", configDirName)
case "windows":
	return filepath.Join(os.Getenv("APPDATA"), "gitsu-go")
default:
	if os.Getenv("XDG_CONFIG_HOME") != "" {
		return filepath.Join(os.Getenv("XDG_CONFIG_HOME"), configDirName)
	}
	return filepath.Join(os.Getenv("HOME"), "/.config", configDirName)
}
```

[2020.12.07 追記ここから]

Go 1.13 で導入された [`os.UserConfigDir()`](https://golang.org/pkg/os/#UserConfigDir) というメソッドで上記の分岐をいちいち書かなくても、ユーザー個別の configuration directory を取得できるので、こちらを使用すべきです。

[2020.12.07 追記ここまで]

ツールの使い方としては、「新しい git ユーザーの追加」「 git ユーザーの切り替え」「 git ユーザーの削除」が想定できます。追加の際は情報をユーザーに入力してもらう必要があるので promptui の Prompt を使用し、切り替えや削除は config ファイルの内容から生成した git ユーザー一覧からそれぞれ選択されればよいので promptui の Select を使用します。

まずはどういう操作をするのか選択させます。

```go
sel := "Select git user"
add := "Add new git user"
del := "Delete git user"

action := promptui.Select{
	Label: "Select action",
	Items: []string{sel, add, del},
}

_, actionType, err := action.Run()
if err != nil {
    return err
}
```

promptui の Select で選択されたものは Run() の2番目の戻り値にあります（1個目には Select の Items のインデックス）。それを確認して追加、切り替え、削除の処理を実行します。

```go
switch actionType {
case sel:
	if err := selectUser(); err != nil {
		return err
	}
case add:
	if err := addUser(); err != nil {
		return err
	}
case del:
	if err := deleteUser(); err != nil {
		return err
	}
default:
    return errors.New("Unknown action type")
}
```

あとはそれぞれ実装すればよいです。選択は config を読んで promptui の Select を使うだけ。追加は promptui の Prompt で名前とメールアドレスを入力してもらい、その情報を config に追記するだけ。削除は config を読んで promptui の Select を使い、選択されたユーザーを config から消すだけです。以下デモ GIF です。

![Demo](/images/2020/12/06/demo.gif)

これくらい簡単な CLI ツールであればそこまで時間かからずに実装できますので、あまり Go を書いたことのない人でも比較的取り組みやすいと思います。

    
### 配布

Go を採用する理由でも述べましたが、 Go はコンパイル後シングルバイナリを生成するので配布が用意です。今回は簡単なオレオレコマンドですが、せっかく Go を採用したのでバイナリの配布までやってみます。

#### [goreleaser](https://github.com/goreleaser/goreleaser/)

Go のバイナリ配布をより楽にしてくれるツールです。プロジェクトルートに設定ファイルを置くことでビルド、リリース過程を自動化してくれます。設定ファイルでは様々なオプションが用意されており、クロスコンパイルも必要な OS やアーキテクチャを書くだけでサクッとやってくれます。また、ソースコード内に特定の変数を用意することでツールのバージョンやビルド時のコミットハッシュをツール内に自動で埋め込んでくれます。インストール、設定ファイルの作成が完了したら、 tag を打ってコマンドラインで goreleaser を実行することで手元から GitHub Releases や GitLab Releases にリリースすることができます。

今回は git のサブコマンドを提供したいので、実行ファイルは `git-<subcommand>` という名前で作成しました。設定できるオプションは[公式のドキュメント](https://goreleaser.com/)に詳細が書かれているので、こちらを参照ください。


#### GitHub Actions

 goreleaser のドキュメントにもありますが、 goreleaser は [GoReleaser Action](https://github.com/goreleaser/goreleaser-action) という GitHub Action を提供しているので、これを GitHub Workflow で利用することでリリースの自動化をさらに進めることができます。 [goreleaser のドキュメント](https://goreleaser.com/ci/actions/)にサンプルの `.github/workflows/release.yml` があるので、これをコピペしてリモートリポジトリに置くだけで実現できます。

今回はドキュメントの例をコピペしてから、 Semantic Versioning で tag をプッシュしたときに新しいバイナリがリリースされるように設定しました。


#### Homebrew

goreleaser + GitHub Actions により GitHub Releases へバイナリをリリースすることはできましたが、実際にユーザーがインストールしやすい環境を整えてあげるとより良いです。 Go は `go get` というコマンドでプロジェクトを指定すれば実行ファイルもインストールすることが可能です[^4]が、今回はプロジェクト名を `git-<subcommand>` としなかったため、 `go get` されるとプロジェクト名の CLI ツールはインストールできますが、 git のサブコマンドとして配布するという目的が実現できません。

今回は Mac ユーザー向けに Homebrew で `git-<subcommand>` という名前でインストールできるようにしました。他 OS のユーザーにも準備したかったのですが、時間がなかったので追々やっていきます。

[Homebrew/homebrew-core](https://github.com/Homebrew/homebrew-core) に PR を出して取り込まれれば、 `brew install <name>` でインストールが可能ですが、なかなかハードルが高い感じがありますし今回のようなちっちゃいツールであればなおさら出しづらいです。 Homebrew は自分でリポジトリを作ってそこに Formula を置くことで、 `brew install <user>/<name>/<name>` というコマンドで同じようにインストールすることができるので、今回はこのやり方を採用しました。

長くなってきたので簡単に手順を書くと、

- GitHub に Homebrew 用のリポジトリを作成。 `<user>/homebrew-<name>` というようにリポジトリ名は homebrew- というプレフィックスが必要
- tap を作成。ローカル環境に先程つくったリモートリポジトリをクローンしてくれる
  - `brew tap <user>/homebrew-<name>`
- 作成したローカル環境下で Formula を作成。以下のコマンドで作成できる
  - `brew create <path/to/tarballlocation>`
- 作成された Formula をいい感じに編集。[公式の Cookbook](https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md) を参照
- 編集が完了したらリモートリポジトリにプッシュして完了

これで `brew install <user>/<name>/<name>` でインストールできるようになりました。しかし、ツールのアップデートと併せていちいち Formula を編集してプッシュするのは非常に面倒という問題があります。

実は、前で述べた goreleaser で Homebrew の Formula を自動で更新してくれるオプションがあるので、これを利用します。設定項目は GitHub の情報や Formula を更新して Homebrew 用のリポジトリにコミットするユーザー情報（ドキュメントでは bot ）、インストールコマンドなどです。他、詳しくは[公式のドキュメント](https://goreleaser.com/customization/homebrew/)を参照ください。


### 完成

これで git のオレオレサブコマンドを Go で作成し、ビルド、リリース過程を自動化し、 Homebrew でインストールしやすいようになりました！みなさんも是非こんなものがあったらいいなという CLI ツールを同様の手順で作成、公開して、 GitHub Star 5000兆個を目指してください。

今回作成したツールは以下になります。ニーズはほぼ無いと思うのですが、試しに使ってみたりしてください。

https://github.com/matsuyoshi30/gitsu


## おわりに

今回人生で初めて Advent Calendar というものに参加してみました。業務に関わるネタでなくて少し残念な気持ちもありますが、来年もぜひ参加したいと思いますし、その際はもっと業務と絡めて興味深い話ができるよう頑張ります。

明日は [@shotanue](https://qiita.com/shotanue) さんです &#x1f449;。



[^1]: [Do One Thing and Do It Well](https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well)
[^2]: 原因をよく理解していないので、説明できる方教えて下さい。
[^3]: [コメント](https://github.com/git/git/blob/3a0b884caba2752da0af626fb2de7d597c844e8b/git.c#L890-L895)を参照
[^4]: Go 1.17 から go get が無効になるという話もあります（[mattn さんのツイート](https://twitter.com/mattn_jp/status/1331394028651257858)参照）。
