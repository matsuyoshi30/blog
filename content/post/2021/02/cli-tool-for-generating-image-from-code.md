+++
title = "ソースコード画像化ツールを作った"
date = 2021-02-28T13:18:29+09:00
tags = ["golang", "cli"]
draft = false
toc = true
+++

またまた CLI ツールネタだが、ソースコードから画像を作る [Carbon](https://github.com/carbon-app/carbon) や [Silicon](https://github.com/Aloxaf/silicon) のようなツールを Go で書いた。

![Sample](/images/2021/02/28/sample.png)

まだ上記2つのツールのような高機能ではないが、 Go 製のツールを使いたいと考えている人は是非使ってみてください。プルリク等ももちろん歓迎。

https://github.com/matsuyoshi30/germanium


## 矩形画像の描画

複数の矩形画像を重ね合わせることで、 Carbon や Silicon のように仮想のウインドウ中心に仮想のテキストエディタが表示されており、エディタがシンタックスハイライトがかかったソースコードを表示している、というイメージを作成する。具体的には、バックグラウンド画像の上にエディタ画像を重ね合わせ、エディタ画像の上にウインドウコントロール（閉じるボタンとかがある部分）、行数表示部分、ソースコード表示部分を重ね合わせていく。

![Rectangles](/images/2021/02/28/rectangles.png)

画像を重ね合わせる処理は、標準パッケージ `image/draw` の [Draw 関数](https://golang.org/pkg/image/draw/#Draw)を使う。今回は作成する矩形画像を表す `Rect` 構造体を用意して以下のようなメソッドを作成した。

```go
func (r *Rect) drawOver(img *image.RGBA) {
	draw.Draw(r.img, r.img.Bounds(), img, image.Point{0, 0}, draw.Over)
}
```

引数に指定された RGBA 構造体をベースの矩形画像の上に重ね合わせる。当初の想定ではいろいろな矩形画像が重ね合わさり合う（バックグラウンドの上にエディタ、エディタの上にウインドウコントロール…）みたいなのを考えていたが、結局ベースのバックグラウンドイメージに順番に重ね合わせていけばよかったので、結果としてあまりメソッド化の意味は無かった。


## 円の描画

Go の標準パッケージには矩形画像の描画についての構造体やメソッドは準備されているものの、円形の画像を描画するためのものは用意されていない。そのためユーザーが独自に円形画像を描画するアルゴリズムを実装する必要がある。

今回は要件としてウインドウコントロール部分も描画することも含んでおり、ウインドウコントロール内の閉じるボタンなどのボタンのために円形画像の描画が必要になった。

色々やり方は考えられると思う。ナイーブに実装するなら、中心となるピクセルポイント `(x, y)` と半径 `radius` を指定して、描画したい円がちょうど入る正方形内を対象として、各ピクセルと中心点の距離を計算してそれが半径以内かどうかを判定するやり方などが考えられる。

![DrawCircleImage](/images/2021/02/28/drawCircleImage.png)

上記でも目的は達成できるが、これだと円内に入らない部分の計算や、毎ピクセルポイントで `(tx-x)^2 + (ty-y)^2 = r^2` のような累乗計算が必要になるので、円の大きさによっては遅くなる。また、円周部分のピクセルポイントが分かればその中や外の計算は無駄なのでこれは採用したくない。今回は「ブレゼンハム( Bresenham )の中点分岐を用いた円描画」というアルゴリズムを知ったので、これを用いて実装してみた。

このアルゴリズムは円を8つに分割し、それぞれの分割円で描画のスタートピクセルから次に描画するピクセルの方向を計算して決めるというやり方だ。詳しい解説はソースコメントにリンクも記載した[この記事](http://dencha.ojaru.jp/programs_07/pg_graphic_09a1.html)を参照とするが、このアルゴリズムを採用することで必要なのは8分割された円周部分の計算のみになるので計算量が削減できる。円内の塗りつぶしについては y 座標が同じ線分上に色を設定していくので、結果的に円内部分の計算もしているが、明らかに円外の部分（円がすっぽりと入る正方形の周辺など）の計算はしていない。

```go
type Rect struct {
	img   *image.RGBA
	color color.RGBA
}

func (r *Rect) drawCircle(center image.Point, radius int, c color.RGBA) {
	var cx, cy, d, dh, dd int
	d = 1 - radius
	dh = 3
	dd = 5 - 2*radius
	cy = radius

	for cx = 0; cx <= cy; cx++ {
		if d < 0 {
			d += dh
			dh += 2
			dd += 2
		} else {
			d += dd
			dh += 2
			dd += 4
			cy--
		}

		r.img.Set(center.X+cy, center.Y+cx, c) // 0-45
		r.img.Set(center.X+cx, center.Y+cy, c) // 45-90
		r.img.Set(center.X-cx, center.Y+cy, c) // 90-135
		r.img.Set(center.X-cy, center.Y+cx, c) // 135-180
		r.img.Set(center.X-cy, center.Y-cx, c) // 180-225
		r.img.Set(center.X-cx, center.Y-cy, c) // 225-270
		r.img.Set(center.X+cx, center.Y-cy, c) // 270-315
		r.img.Set(center.X+cy, center.Y-cx, c) // 315-360

		// draw line same y position
		for x := center.X - cy; x <= center.X+cy; x++ {
			r.img.Set(x, center.Y+cx, c)
			r.img.Set(x, center.Y-cx, c)
		}
		for x := center.X - cx; x <= center.X+cx; x++ {
			r.img.Set(x, center.Y+cy, c)
			r.img.Set(x, center.Y-cy, c)
		}
	}
}
```


## 文字を画像に描画

画像の上に文字列を描画するときは、準標準パッケージの [golang.org/x/image/font](https://pkg.go.dev/golang.org/x/image/font) と外部パッケージの [freetype/truetype](https://pkg.go.dev/github.com/golang/freetype/truetype) を使う。前者は文字列を画像上に描画するためのインターフェースを提供していて、後者はフォントデータをラスター化するのに用いる。

文字列描画のインターフェースである `Drawer` は描画先の画像とフォントデータ、描画先のドットポイントを指定して `drawString()` メソッドを呼び出すことで、先に指定したドットポイントとフォントデータを用いて引数に指定された文字列を描画先に描画する。このとき、描画先のドットポイントは矩形画像処理で用いていたピクセル（ int 型）ではなく、 `fixed.Point26_6` という型で指定する。フォント種別及びフォントサイズによって描画するスタートとなるピクセル（左上）と終端となるピクセル（右下）が変動する。例えば、 1em が 10px のフォントを用いているときは `fixed.I(10)` で描画する文字の一文字あたりのドットポイントを調整する。（詳しくはパッケージのドキュメントを参照）

![DrawStringImage](/images/2021/02/28/drawStringImage.png)

今回は行数表示部分や行間のパディング調整に少し手間取った。また、ここらへん調整しつつこの数値が良さそうだな、というやり方で実装したので変更に弱い部分になっている。理解が不充分な部分だと自覚しているので、引き続きパッケージのコード読んだりして理解を深めていく。


### フォントデータを go:embed

準標準パッケージで提供されているフォントもあるが、個人的に気に入らなかったので、 Silicon で用いられている [Hack](https://sourcefoundry.org/hack/) というフォントを使うことにした。ここで、フォントを外部から読み込むような構成にすると、ユーザーがいちいちフォントデータを用意しないといけなくなる。

ここでは先日リリースされた Go 1.16 の目玉機能の一つである `go:embed` を使用してバイナリにフォントデータを同梱した。使い方は簡単で、 []byte な変数のコメントに `go:embed` アノテーションをつけて同梱したいファイルを指定するだけ。

```go
//go:embed assets/fonts/Hack-Regular.ttf
var font_hack []byte
```

これでビルド時に指定したファイルがバイナリに同梱される。今回はレギュラーの Hack フォントのみ同梱しているので、バイナリサイズはそこまで増大しなかった（といっても 300k 増加）が、今後オプションでフォントを指定できる機能などを追加したときはフォントごとに `go:embed` する必要があるので、結構でかくなるかも。

```sh
# 同梱前（特定のディレクトリ化のフォントを使用する構成）
-rwxr-xr-x  1 matsuyoshi  staff  11084976  2 28 16:18 germanium*
# 同梱後
-rwxr-xr-x  1 matsuyoshi  staff  11388112  2 28 16:18 germanium*
```


## Syntax Highlight

ソースコード画像化にあたり、単にテキスト形式で文字列を描画するのではなく、コードの言語によってシンタックスハイライトをかける必要がある。今回は [alecthomas/chroma](https://github.com/alecthomas/chroma) というパッケージを用いた。

ソースコードの構文解析とトークナイズ、テーマの適用はこのパッケージを使い、フォーマットは独自でメソッドを実装した。
とはいってもここでいうフォーマットとは、トークナイズされた文字列を一つずつ見ていき、トークンのスタイルは上記パッケージで解析されて適用されたカラーを取得して、一文字ずつ画像に描画するというだけ。パッケージの `formatters` ディレクトリに html のフォーマッタが実装されているので、それを参考にした。

ざっくり流れを書くと、ソースコードを構文解析器（ lexer ）にかける→シンタックスハイライトのスタイルを取得する→構文解析の結果をトークン列にする→独自で実装したフォーマッタにトークン列とスタイルを渡す→フォーマッタ内で各トークンにスタイルを当てて一文字ずつ描画する、といった感じ。簡単にシンタックスハイライトがかけられて便利。


## `go-flags` でフラグオプション管理

Go では標準パッケージで提供されている [flag](https://golang.org/pkg/flag/) を使うことで、コマンドラインのフラグ解析が簡単にできるが、標準パッケージではロングオプション（`--version` のようにダブルダッシュのもの）がサポートされていない。今回は Silicon にならい、フラグオプションとして「行数の非表示」「ウインドウコントロールの非表示」を想定しており、これらはロングオプションで提供したかったので、コマンドラインのフラグ解析に関して多くの機能を提供している [go-flags](https://github.com/jessevdk/go-flags) というパッケージを導入した。

使用方法は簡単で、フラグオプションとして提供したいものをグローバルな構造体にまとめてアノテーション付きで定義し、その構造体変数をパッケージが提供している関数に指定された方法で渡すだけ。これで構造体のフィールドに、コマンドラインのフラグに指定された値が格納される。あとは内部処理でフラグオプションを参照したいときは、グローバルのオプション構造体のフィールドを参照すれば良い。例がパッケージの README に書いてあるのでこれを見るだけで理解できると思う。

今回でいうと、先に述べたような非表示フラグや出力ファイルの指定をオプションとして提供したかったので、まずは以下のような構造体を定義して、その構造体型のグローバル変数を宣言する。

```go
type Options struct {
	Output            string `short:"o" long:"output" default:"output.png" description:"Write output image to specific filepath"`
	NoLineNum         bool   `long:"no-line-number" description:"Hide the line number"`
	NoWindowAccessBar bool   `long:"no-window-access-bar" description:"Hide the window access bar"`
}

var opts Options
```

そして、 main 関数の最初で `go-flags.NewParser` 関数を呼び出して、コマンドラインで指定されたフラグを解析して、グローバル変数として宣言した構造体の中にフラグの値を格納する。パーズの戻り値は解析後に残った文字列のスライス（コマンドライン引数）なので、これを後続の処理で使用する。

```go
int main() {
	args, err := flags.NewParser(&opts, flags.HelpFlag|flags.PassDoubleDash).Parse()
	if err != nil {
		if err, ok := err.(*flags.Error); ok {
			if err.Type != flags.ErrHelp {
				fmt.Fprintln(os.Stderr, err.Error())
			}
		}
		os.Exit(1)
	}

	if len(args) != 1 {
		fmt.Fprintln(os.Stderr, "File to read was not provided")
		os.Exit(1)
	}

    // do something with args
}
```

フラグオプションを参照したいときは、グローバル変数として宣言した構造体を参照する。例えば、今回出力ファイルを生成するときは、オプション構造体に定義した出力ファイル用のフィールドを参照する。

```go
file, err := os.Create(opts.Output) // here
if err != nil {
	return err
}

// do something with file
```


## おわりに

これで、ソースコードを画像化するツールがひとまずできた。まだまだ足りない機能がたくさんあるし、なおかつ決してキレイな実装ではないので改善の余地が多分にある。 [reddit](https://www.reddit.com/r/golang/comments/lqfyss/a_cli_tool_for_generating_image_from_source_code/) にあげたらぼちぼち反響あったのでまあ良かった。

また、このポストで用いている手書き風画像は https://excalidraw.com/ というサイトで作成した。これ非常に便利（画像が分かりにくいのは僕の画像力の無さ）。


## 参考情報

- https://github.com/carbon-app/carbon
- https://github.com/Aloxaf/silicon
- http://dencha.ojaru.jp/programs_07/pg_graphic_09a1.html
- https://pkg.go.dev/golang.org/x/image/font
- https://pkg.go.dev/github.com/golang/freetype/truetype
- https://github.com/alecthomas/chroma
- https://github.com/jessevdk/go-flags
