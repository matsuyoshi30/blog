+++
title = "Go の ReadFile を実装する + α"
date = 2021-10-16T23:44:01+09:00
tags = ["golang"]
draft = false
+++

以下の Tweet を見かけたので試しにやってみた。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">社内の勉強会で出した問題 <a href="https://t.co/LZy39Gd1WM">pic.twitter.com/LZy39Gd1WM</a></p>&mdash; (っ=﹏=c) .｡o○ (@itchyny) <a href="https://twitter.com/itchyny/status/1364884934142300160?ref_src=twsrc%5Etfw">February 25, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## まずは素直に実装

ぱっと書いてみたのがこれ。4096バイト分のバイト列を用意しておいてループでファイルを読み込む。

```go
func ReadFile(filepath string) ([]byte, error) {
	f, err := os.Open(filepath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	ret := make([]byte, 0)
	for {
		b := make([]byte, 4096)

		n, err := f.Read(b)
		if err != nil {
			if err == io.EOF {
				break
			} else {
				return nil, err
			}
		}

		ret = append(ret, b[:n]...)

		if n < len(b) {
			break
		}
	}

	return ret, nil
}
```

4096バイト以下の小さいファイルであればよいのだが、大きいファイルになるとリアロケーションが発生するのでこのままでは良くない。

```
goos: darwin
goarch: amd64
pkg: github.com/matsuyoshi30/til/golang/readfile
cpu: Intel(R) Core(TM) i5-5287U CPU @ 2.90GHz
BenchmarkReadFile_osReadFile-4       	   42889	     25145 ns/op	   24904 B/op	       5 allocs/op
BenchmarkReadFile_ReadFile-4         	   25940	     42072 ns/op	   71032 B/op	       8 allocs/op
```

## ファイルサイズを事前に取得しておく

ファイルを読み込む前に `(*File).Stat` を用いてファイル情報を取得しておき、それをもとにした長さのバイト列を準備する。これでリアロケーションが発生しない。

`(*File).Stat` で取得した `FileInfo` インターフェースのメソッド `Size` は int64 を返すが、 `(*File).Read` の引数は int なのでそこを考慮した処理も入れておく。

```go
func ReadFile(filepath string) ([]byte, error) {
	f, err := os.Open(filepath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	info, err := f.Stat()
	if err != nil {
		return nil, err
	}
	size64 := info.Size()

	var size int
	if int64(int(size64)) == size64 {
		size = int(size64)
	}

	ret := make([]byte, size)
	_, err = f.Read(ret)
	if err != nil {
		if err != io.EOF {
			return nil, err
		}
	}

	return ret, nil
}
```

ループも append も消えてリアロケーションなし。

```
goos: darwin
goarch: amd64
pkg: github.com/matsuyoshi30/til/golang/readfile
cpu: Intel(R) Core(TM) i5-5287U CPU @ 2.90GHz
BenchmarkReadFile_osReadFile-4   	   45243	     23691 ns/op	   24904 B/op	       5 allocs/op
BenchmarkReadFile_ReadFile-4     	   44989	     22228 ns/op	   24904 B/op	       5 allocs/op
```

## 答え合わせ

割とあっさりかけたところで、答え合わせとして `os.ReadFile` を見てみる。

```go
// ReadFile reads the named file and returns the contents.
// A successful call returns err == nil, not err == EOF.
// Because ReadFile reads the whole file, it does not treat an EOF from Read
// as an error to be reported.
func ReadFile(name string) ([]byte, error) {
	f, err := Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var size int
	if info, err := f.Stat(); err == nil {
		size64 := info.Size()
		if int64(int(size64)) == size64 {
			size = int(size64)
		}
	}
	size++ // one byte for final read at EOF

	// If a file claims a small size, read at least 512 bytes.
	// In particular, files in Linux's /proc claim size 0 but
	// then do not work right if read in small pieces,
	// so an initial read of 1 byte would not work correctly.
	if size < 512 {
		size = 512
	}

	data := make([]byte, 0, size)
	for {
		if len(data) >= cap(data) {
			d := append(data[:cap(data)], 0)
			data = d[:len(data)]
		}
		n, err := f.Read(data[len(data):cap(data)])
		data = data[:len(data)+n]
		if err != nil {
			if err == io.EOF {
				err = nil
			}
			return data, err
		}
	}
}
```
[os/file.go](https://github.com/golang/go/blob/680caf15355057ca84857a2a291b6f5c44e73329/src/os/file.go#L665-L708)

前半（ファイルオープンとサイズ取得）はこれ以外に書きようがないくらいなのでほぼ同じ。違うのは後半部分から。

まず、取得したファイルサイズが512バイト未満であれば、ファイルサイズをそのままバイト列の長さとして使うのではなくて、最低512バイト分は読み込むよう上書き処理を入れている。コメントにある通り、ファイルサイズを0バイトと取得してしまう proc ファイルなんかは、（直前の size インクリメントによりバイト列は1バイト分用意されるが）読み込み処理がうまくいなかいようだ。

また、事前に計算した長さのバイト列を用いて一回だけ `(*File).Read` 呼び出すのではなく、無限ループの中で `(*File).Read` を呼んでいる。ループ内のエラー制御ではエラーが発生してなければ次ループへいき、 io.EOF の場合はエラー無しで return する。一回目の `(*File).Read` はエラーが発生せず次ループへ遷移し、バイト列の len と cap を比較してバイト列を更新、その後二回目の `(*File).Read` 呼び出し後に io.EOF 発生で return という流れになる。

なぜループを使っているのかわからなかったが、 `(*File).Stat` で取得した `FileInfo` から得られるサイズが正しくないケースがあるらしく[^1]、仮に `FileInfo.Size()` が実ファイルサイズより小さい値を返した場合はファイル全体を読み込んだことにはならない。そのためちゃんとファイル末尾まで読み込んだことが確認できるよう io.EOF のチェックを入れているのだと思う。

## Go1.15 の `ioutil.ReadFile` と Go1.16 以降の `os.ReadFile`

答えとして `os.ReadFile` を見てきたが、 Go1.15 まではファイル読み込みは `ioutil.ReadFile` が用いられていた。ここではこれらがどう違うのか見てみる。

```go
// ReadFile reads the file named by filename and returns the contents.
// A successful call returns err == nil, not err == EOF. Because ReadFile
// reads the whole file, it does not treat an EOF from Read as an error
// to be reported.
func ReadFile(filename string) ([]byte, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	// It's a good but not certain bet that FileInfo will tell us exactly how much to
	// read, so let's try it but be prepared for the answer to be wrong.
	const minRead = 512
	var n int64 = minRead

	if fi, err := f.Stat(); err == nil {
		// As initial capacity for readAll, use Size + a little extra in case Size
		// is zero, and to avoid another allocation after Read has filled the
		// buffer. The readAll call will read into its allocated internal buffer
		// cheaply. If the size was wrong, we'll either waste some space off the end
		// or reallocate as needed, but in the overwhelmingly common case we'll get
		// it just right.
		if size := fi.Size() + minRead; size > n {
			n = size
		}
	}

	if int64(int(n)) != n {
		n = minRead
	}

	b := make([]byte, 0, n)
	for {
		if len(b) == cap(b) {
			// Add more capacity (let append pick how much).
			b = append(b, 0)[:len(b)]
		}
		n, err := f.Read(b[len(b):cap(b)])
		b = b[:len(b)+n]
		if err != nil {
			if err == io.EOF {
				err = nil
			}
			return b, err
		}
	}
}
```
[ioutil/ioutil.go (os.ReadFile 呼び出し修正前)](https://github.com/golang/go/blob/cb0a0f52e67f128c6ad69027c9a8c7a5caf58446/src/io/ioutil/ioutil.go#L25-L71)

`(*File).Read` を呼び出しているループ部分なんかは `os.ReadFile` と変わらない。 len と cap を比較してバイト列を更新する処理も一行で書いているだけ。 len と cap の比較が微妙に違うけど、スライスを更新した結果 len > cap になるケースってあるのだろうか。

違うのは前半部分で、読み込みに使うバイト列の長さのためにファイルサイズを取得したあとの処理。 `os.ReadFile` ではサイズが小さすぎないかチェックしていたが、 `ioutil.ReadFile` ではファイルサイズに加えて余分に512バイトを追加している。

ベンチもとってみた。大きいファイルでもやってみたけどあまりかわらない？

```
% go1.15.15 test -bench . -benchmem
goos: darwin
goarch: amd64
pkg: github.com/matsuyoshi30/til/golang/readfile
BenchmarkReadFile_ioutilReadFile-4   	   40023	     25672 ns/op	   24904 B/op	       5 allocs/op

% go test -bench . -benchmem
goos: darwin
goarch: amd64
pkg: github.com/matsuyoshi30/til/golang/readfile
cpu: Intel(R) Core(TM) i5-5287U CPU @ 2.90GHz
BenchmarkReadFile_osReadFile-4   	   51327	     23057 ns/op	   24904 B/op	       5 allocs/op
```

## Prometheus のテスト失敗

上記の通り、`ioutil.ReadFile` で返されるバイト列の capacity は512バイト余分に多かったが、 `os.ReadFile` で返されるバイト列にはそれがなくなった。[Prometheus で Go1.16 によりテストが落ちるようになった](https://github.com/prometheus/prometheus/issues/8403)のはこのためである。

テストでは、以下のようにファイル読み込みの結果次のチャンクのヘッダーはゼロ値でパディングされていることをチェックしていた。 Go1.16 でファイル読み込みの結果が実ファイルのサイズより大きかった `ioutil.ReadFile` から `os.ReadFile` に変更されたため、実ファイルのサイズ fileEnd より `MaxHeadChunkMetaSize` 分大きいバイト列を参照しようとしたところで `slice bounds out of range` が発生した。

```go
// Test for the next chunk header to be all 0s. That marks the end of the file.
for _, b := range actualBytes[fileEnd : fileEnd+MaxHeadChunkMetaSize] {
    require.Equal(t, byte(0), b)
}
```

テスト失敗のトレースログは以下の通り。

```
github.com/prometheus/prometheus/tsdb/chunks
--- FAIL: TestChunkDiskMapper_WriteChunk_Chunk_IterateChunks (0.01s)
panic: runtime error: slice bounds out of range [:104326] with capacity 104293 [recovered]
panic: runtime error: slice bounds out of range [:104326] with capacity 104293
```

`MaxHeadChunkMetaSize` は以下の通り34バイト。この分オーバーしたところを参照しようとしている。

```go
MaxHeadChunkMetaSize = SeriesRefSize + 2*MintMaxtSize + ChunksFormatVersionSize + MaxChunkLengthFieldSize + CRCSize
```
[tsdb/chunks/head_chunks.go](https://github.com/prometheus/prometheus/blob/0adfa7cbed/tsdb/chunks/head_chunks.go#L64)

```go
// head_chunks.go
SeriesRefSize = 8
MintMaxtSize = 8
CRCSize = 4

// chunks.go
ChunksFormatVersionSize  = 1
MaxChunkLengthFieldSize = binary.MaxVarintLen32 // 5
```

最終的にはこのチェックは不要ということで[削除された](https://github.com/prometheus/prometheus/pull/8538/files)。

## まとめ

Prometheus で発生した、 Go のバージョンアップによりテストが失敗するケース、こんなこともあるんだなと面白かった。標準ライブラリの修正や追加なんかはこういった違いが出てくるかもしれないから注意が必要になるかもなと勉強になった。

試してみたやつは [TIL](https://github.com/matsuyoshi30/til/tree/a8db937e28e709b1d5d578c3e400ccd63f43c6ec/golang/readfile) にあげている。

## 参考

- [`ioutil.ReadFile` が `os.ReadFile` 呼び出しになるパッチ](https://go-review.googlesource.com/c/go/+/266364)

[^1]: `ioutil.ReadFile` のコメントから判断した。 `FileInfo.Size()` が誤った値を返すことがあるという記事等があれば知りたい。
