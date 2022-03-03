+++
title = "自作の Hugo Theme のダークモードをちょっと変えた"
date = 2022-03-03T22:16:13+09:00
tags = ["frontend"]
+++

このブログでも使用している拙作の Hugo Theme である Harbor に、 Dark Mode を有効化すると backtotop ボタンがページ下部に固定されてしまい、本来はスクロールされても右下に表示が残るのに残らなくなってしまうという [issue](https://github.com/matsuyoshi30/harbor/issues/130) が起票されていた。

対応にあたり backtotop ボタンと Dark Mode についてまずは整理する。

## backtotop ボタン

backtotop ボタンは記事の途中でページトップまで一気に移動するボタン。これを使うことで長い記事を読んでいるときにスクロールせずにページの最上部まで移動することができる。

[記事が400語以上かつページの frontmatter で backtotop が有効になっている場合](https://github.com/matsuyoshi30/harbor/blob/master/layouts/_default/single.html#L17-L22)にボタンを表示するようになっている。

[backtotop.html](https://github.com/matsuyoshi30/harbor/blob/master/layouts/partials/backtotop.html) には何が書かれているかというと、ボタン表示の調整と実際にボタンが謳歌されたときにトップに移動する処理(topFunction)が記述されている。

```html
<script>
  document.addEventListener('scroll', function () {
    if (
      document.body.scrollTop > 50 ||
      document.documentElement.scrollTop > 50
    ) {
      document.getElementById('backtotopButton').style.opacity = '1'
      document.getElementById('backtotopButton').style.transition = '0.5s'
    } else {
      document.getElementById('backtotopButton').style.opacity = '0'
      document.getElementById('backtotopButton').style.transition = '0.5s'
    }
  })
    
  function topFunction() {
    document.body.scrollTop = 0 // For Safari
    document.documentElement.scrollTop = 0 // For Chrome, Firefox, IE and Opera
  }
</script>
```

[scrollTop](https://developer.mozilla.org/ja/docs/Web/API/Element/scrollTop) は、ページがどれだけ垂直方向に移動したか（するか）をピクセル単位で表すもので、記述の通り 50px よりも下にスクロールされるとボタンの CSS を上書きして表示するようになっている。

また、ボタン押下時に実行される topFunction はこの scrollTop を 0px つまりページ最上部に上書きしている。

## Dark Mode

harbor では Dark Mode を CSS Filter で実現している。以下は [dark.css](https://github.com/matsuyoshi30/harbor/blob/master/assets/css/dark.css) からの引用。

```css
body {
    filter: invert(100%) hue-rotate(180deg) brightness(105%) contrast(85%);
    -webkit-filter: invert(100%) hue-rotate(180deg) brightness(105%) contrast(85%);
}
img, video, iframe, body * [style*="background-image"] {
    filter: hue-rotate(180deg) contrast(100%) invert(100%);
    -webkit-filter: hue-rotate(180deg) contrast(100%) invert(100%);
}
```

[invert](https://developer.mozilla.org/en-US/docs/Web/CSS/filter-function/invert()) で色、 [hue-rotate](https://developer.mozilla.org/ja/docs/Web/CSS/filter-function/hue-rotate()) で色相環を反転し、 [brightness](https://developer.mozilla.org/ja/docs/Web/CSS/filter-function/brightness()) で明度、 [contrast](https://developer.mozilla.org/ja/docs/Web/CSS/filter-function/contrast()) でコントラストを調整している。

## 問題

今回の issue は、 CSS Filter で変更した要素の中のものは固定された要素(position: fixed)であってもフィルタ適用によって相対的な要素に変わってしまったことが原因で発生していた。[仕様](https://drafts.fxtf.org/filter-effects/#FilterProperty)でも以下の通り述べられている。

> A value other than none for the filter property results in the creation of a containing block for absolute and fixed positioned descendants unless the element it applies to is a document root element in the current browsing context.

> filter 属性に none 以外の値を指定すると、absolute および fixed position の子孫要素に対して、それが現在のブラウジングコンテキストにおけるドキュメントルート要素でない限り、包含ブロックが生成されることになる。

挙動を見たい場合は issue に gif のリンクが貼られているのでそちらを参照。

## 対応

issue 起票者が [PR](https://github.com/matsuyoshi30/harbor/pull/131) まで出してくれたのでそれで完結。内容は、 CSS Filter で Dark Mode を実現していたのを止めて、 Dark Mode が有効のときは document.body に data-dark-mode の data attribute を付与し、それらの CSS を個別に定義するようになった。

## 参考

- [CSS Filter を適用したときの要素に関する stackoverflow の回答](https://stackoverflow.com/questions/52937708/why-does-applying-a-css-filter-on-the-parent-break-the-child-positioning/52937920#52937920)
