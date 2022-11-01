+++
title = "eglot と Go"
date = 2022-11-01T22:23:11+09:00
tags = ["golang", "emacs"]
+++

普段 Emacs を使っている。めちゃくちゃ init.el こだわって設定しているわけでもなく、そこまで elisp に詳しいわけでもないので、そのうちちゃんと中身勉強しようと思って早数年経つが未だ初心者レベル。

Emacs では [lsp-mode](https://github.com/emacs-lsp/lsp-mode/) と [eglot](https://github.com/joaotavora/eglot) という2つのパッケージが [LSP(Language Server Protocol)](https://microsoft.github.io/language-server-protocol/) をサポートしている。自分はあまり何も考えずに前者を使っていたが、先日 Emacs の master branch に eglot が標準添付される feature branch が[マージされた](https://git.savannah.gnu.org/cgit/emacs.git/commit/?id=83fbda715973f57dc49fe002d255ecaff8273154)。これを気に eglot に移行しようと思って作業したときのメモ。

## eglot 導入

自分はパッケージ設定に leaf を使っているので、以下のように eglot パッケージを使用するよう init.el に追記するだけ。

```elisp
(leaf eglot
  :ensure t
  :config
  (add-hook 'go-mode-hook 'eglot-ensure))
```

特定の言語のモードの hook に `eglot-ensure` を追加する。 Go を書くことが多いのでまずは Go で用いるようにした。 

## マルチ Go modules プロジェクト

複数の Go modules で構成されるプロジェクト内の Go ファイルを開くとなんとなく重いし以下のようなメッセージがミニバッファに出ることがある。

```
Error in menu-bar-update-hook (imenu-update-menubar): (jsonrpc-error "request id=2 failed:" (jsonrpc-error-message . "Timed out"))
```

eglot で使用している project.el はバックエンドに VCS をサポートしているので、 .git ディレクトリがある最も近い親ディレクトリがプロジェクトルートとして判定される。

プロジェクトがそこまで大きくない場合は問題にならないが、それなりに大きかったり複数の Go modules を含む場合は gopls との通信がタイムアウトして、開いた Go ファイルの imenu index が作成されない。バッファ内で宣言されてる変数や定義されてる関数の一覧を確認したりジャンプしたりができないのでちょっと不便。

これに対しては [gopls のドキュメントに記載されている設定](https://go.googlesource.com/tools/+/refs/heads/master/gopls/doc/emacs.md#configuring-for-go-modules-in)を追加すればよい。開いた Go ファイルのプロジェクトルートは go.mod があるディレクトリになればよいので、以下の設定を .emacs.d/init.el に追加する。

```elisp
(defun project-find-go-module (dir)
  (when-let ((root (locate-dominating-file dir "go.mod")))
    (cons 'go-module root)))
    
(cl-defmethod project-root ((project (head go-module)))
  (cdr project))
    
(add-hook 'project-find-functions #'project-find-go-module)
```

`(locate-dominating-file FILE NAME)` で、現在のバッファ位置 FILE から親方向にディレクトリをたどって NAME のファイルがあるかどうかを調べることができる。あればそこのディレクトリ名を返し、なければ nil になる。

`cl-defmethod` で `project-root` というジェネリック関数の実装を定義している。 `project-root` は project.el でプロジェクトのルートディレクトリを取得する処理で、 VCS 利用プロジェクトのルートディレクトリなんかは[ここらへん](https://github.com/emacs-mirror/emacs/blob/4cc32937c06f7dd66da025fdb98369f456f1af0a/lisp/progmodes/project.el#L478-L479)で取得している。

ここでは、上記で作成した関数 `project-find-go-module` が追加した変数 `go-module` からプロジェクトルートを取得する。 project.el でプロジェクトを判定するのに用いられる関数群 `project-find-functions` に、上記で作成した go.mod が含まれるディレクトリを探して変数 `go-module` に追加する関数 `project-find-go-module` を追加する。
