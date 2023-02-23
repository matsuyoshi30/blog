+++
title = "Queen Puzzle in Scheme"
date = 2023-02-23T22:36:11+09:00
tags = ["scheme"]
draft = false
+++

最近 SICP 読んでる。練習問題2.42の「8クイーンパズル」についてメモ。

クイーンパズルは、チェスのクイーン8個をある条件を満たす形で盤面に置くパターンを考えるもの。クイーンは縦横斜めに移動できるコマで、条件とは各クイーンが互いに同じ行・列・対角線上にいないように配置すること。例えば * を空きマス、q をクイーン配置マスとすると以下のようなもの。

```txt
*****q**
**q*****
q*******
******q*
****q***
*******q
*q******
***q****
```

任意のサイズの盤面に対して条件を満たしてクイーンを配置できるパターンを列挙する手続きが以下のように与えられている。練習問題は、未知のシンボルである `adjoin-position`, `safe?`, `empty-board` を定義すること。

```scm
(define (queens board-size)
  (define (queen-cols k)
    (if (= k 0)
        (list empty-board)
        (filter
         (lambda (positions) (safe? k positions))
         (flatmap
          (lambda (rest-of-queens)
            (map (lambda (new-row)
                   (adjoin-position
                    new-row k rest-of-queens))
                 (enumerate-interval 1 board-size)
                 ))
          (queen-cols (- k 1)))
         )))
  (queen-cols board-size))
```

答えがわからなかったので、参考資料を見つつ考えた。

まず、盤上の位置集合は `enumerate-interval` を使っているので、以下の通り行列の番号で表現される。

```txt
 |1 2 3 4
-+-------
1|    x
2|x
3|      x
4|  x
```

上記の盤面は `((2 1) (4 2) (1 3) (3 4))` 行番号と列番号のペアのリストとして表される。

`adjoin-position` に渡される `rest-of-queens` は、k 列目にクイーンを置く前に、k-1 列に k-1 個のクイーンを置くパターン列（の要素）である。たとえば、上記の 4*4 の場合、k=4 のときは `rest-of-queens` は k=3 までに3個のクイーンをおいたパターン列 `(((2 1) (4 2) (1 3)) (...) (...))`。 

このとき、k=4 で `new-row` は `enumerate-interval` により生成される行データなので、`(1 2 3 4)`。

`adjoin-position` は `(queen-cols (- k 1))` である `(((2 1) (4 2) (1 3)) (...) (...))` の要素の `rest-of-queens` （例：`((2 1) (4 2) (1 3))`）に対して、取りうる`(行番号 列番号)` のペアを追加する処理。取りうる行番号は `enumerate-interval` で生成した行データに対して map することで得られる要素 `new-row` で、列番号はこれから追加する列である k。

```scm
;; 盤上の位置集合に対する表現方法と、位置集合に新しい行・列の位置を追加
(define (adjoin-position row k rest)
  (cons (list row k) rest))
```

位置の空集合は空リスト。

```scm
(define empty-board '())
```

ここで、与えられた手続き `queens` の処理についてコメントを追記する。 

```scm
(define (queens board-size)
  (define (queen-cols k)
    (if (= k 0)
        (list empty-board)
        (filter
         (lambda (positions) (safe? k positions))
         (flatmap
          (lambda (rest-of-queens) ;; k-1 列に k-1 個のクイーンを置くパターン列の要素
            (map (lambda (new-row) ;; k 列目のクイーンを置く候補となる行
                   (adjoin-position
                   new-row k rest-of-queens))
                 ;; 新しい列用の、1 から board-dize までの行データ
                 (enumerate-interval 1 board-size) 
                 ))
          (queen-cols (- k 1))) ;; k-1 列に k-1 個のクイーンを置くパターン列
         )))
  (queen-cols board-size))
```

`(queen-cols (- k 1))` に対して単なる map を行うと、以下のようにリストがネストされた状態の結果になる。

```scm
(
 (
  ((2 1) (4 2) (1 3) (1 4))
  ((2 1) (4 2) (1 3) (2 4))
  ((2 1) (4 2) (1 3) (3 4))
  ((2 1) (4 2) (1 3) (4 4))
 )
 (...)
 (...)
)
```

これは `flatmap` によって均すことで、取りうるパターンの列にできる。

```scm
(
 ((2 1) (4 2) (1 3) (1 4)) ;; パターン1
 ((2 1) (4 2) (1 3) (2 4)) ;; パターン2
 ((2 1) (4 2) (1 3) (3 4)) ;; パターン3
 ((2 1) (4 2) (1 3) (4 4)) ;; パターン4
 (...)
 (...)
)
```

`flatmap` は、テキストにて説明されているが、リストに対して map して append で集積する手続き。 

```scm
(define (flatmap proc seq)
  (accumulate append '() (map proc seq)))
```

`adjoin-position` と `flatmap` によって k 列目の各行番号にクイーンをおいたパターンが生成されるが、その中には当然クイーンパズルの条件に合致しないパターンも含まれる。これを `filter` によって除外する。

`safe?` では、新しく追加した列 k のところだけを検証すればよい（k-1 列目までは検証済みと考えて良い）ので引数にも k を受け取る。`positions` は `adjoin-position` と `flatmap` によってえたパターンの列。

上記 k=4 の例を用いると `safe?` は以下の手続き適用になる。

```scm
(safe? 4 (
          ((2 1) (4 2) (1 3) (1 4)) ;; パターン1
          ((2 1) (4 2) (1 3) (2 4)) ;; パターン2
          ((2 1) (4 2) (1 3) (3 4)) ;; パターン3
          ((2 1) (4 2) (1 3) (4 4)) ;; パターン4
          (...)
          (...)
          )
       )
```

`safe?` で検証すべきは追加された k 列目のクイーンが他の k-1 個のクイーンに効いていないかどうか。例えばパターン1については4列目1行目を表す (1 4) が k-1 個のクイーンが置かれたことを表す `((2 1) (4 2) (1 3))` に効いていないかを考える。

`safe?` の引数である `positions` について、パターンの k 番目の位置情報を取得したいので、それ用の手続きを定義する。

```scm
;; 例: ((2 1) (4 2) (1 3) (1 4)) について、4番目の (1 4) を取得する
(define (nth n lst)
  (if (= n 1)
      (car lst)
      (nth (- n 1) (cdr lst))))
```

チェックしたいのは k 個目のクイーンと k-1 個分のクイーンの干渉有無なので、おなじようにパターンから k 番目の情報を除いた列も取得できるようにする。

```scm
(define (remove k pos)
  (filter (lambda (x) (not (= (cadr x) k))) pos))
```

と思ったけど `adjoin-positions` が cons セルの一個目に新しい行列の位置を追加しているから、nth も remove もいらなかったー。car と cdr でできます。

パターンの例も誤っている。たとえば、`flatmap` は以下のようになるし。

```scm
(
 ((1 4) (1 3) (4 2) (2 1)) ;; パターン1
 ((2 4) (1 3) (4 2) (2 1)) ;; パターン2
 ((3 4) (1 3) (4 2) (2 1)) ;; パターン3
 ((4 4) (1 3) (4 2) (2 1)) ;; パターン4
 (...)
 (...)
)
```

`safe?` に渡されるのは、正しくは以下。

```scm
(safe? 4 (
          ((1 4) (1 3) (4 2) (2 1)) ;; パターン1
          ((2 4) (1 3) (4 2) (2 1)) ;; パターン2
          ((3 4) (1 3) (4 2) (2 1)) ;; パターン3
          ((4 4) (1 3) (4 2) (2 1)) ;; パターン4
          (...)
          (...)
          )
       )
```

リストの頭のほうが k 列目の情報。

クイーンが置けるのは、それまでおいてあるクイーンと行列番号が異なる、対角線上でもないところ。列番号が異なるのは手続きの内部実装上から分かるので、行番号がかぶっていないかをチェックする。

`positions` の行番号は car を map すれば取得できる。対角線上にあるかどうかは、位置情報の行列の差分が同じかどうかでチェックできる（ここ答え見て気づきました）。たとえば (1 1) と (3 3) は対角線上にあるが、これは行列の差分が同じ2というところで確認が可能。

行と列の差分をそれぞれリスト化して、同じ長さのリストに対して特定の番目の要素が一致していないかどうかをチェックする。

```scm
(define (diag-check lst1 lst2)
  ;; lst1 と lst2 の長さは同じ事が前提
  (if (null? lst1)
      #t
      (and (not (= (car lst1) (car lst2)))
           (diag-check (cdr lst1) (cdr lst2)))))
```

位置集合に対して k 列目のクイーンが他のクイーンに効いていないか。

```scm
(define (safe? k pos)
  (let (
        ;; (kpos (nth k pos))
        ;; (rest (remove k pos))
        (kpos (car pos))
        (rest (cdr pos))
        )
    (if (null? rest) #t
        (and (= (length (filter (lambda (x) (= (car kpos) x)) (map car rest))) 0) ;; 同じ行にないかのチェック
             (diag-check ;; 対角線上にないかチェック
              (map (lambda (x) (abs (- x (car kpos)))) (map car rest))
              (map (lambda (x) (abs (- x (cadr kpos)))) (map cadr rest))
              )))))
```

結果をテスト。

```sh
gosh$ (queens 4)
(((3 4) (1 3) (4 2) (2 1)) ((2 4) (4 3) (1 2) (3 1)))
gosh$ (length (queens 8))
92
gosh$ (length (queens 11))
2680
```

[解答例](http://community.schemewiki.org/?sicp-ex-2.42)。正しそう。

`safe?` はより効率的な手続きとして実装できそうな気もするので、ある程度時間がたったら改めて解いてみよう。
