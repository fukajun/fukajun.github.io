---
title: "Rails & ReactでXSSになるケース"
date: 2021-11-03T12:27:32+09:00
lastmod: 2021-11-05
draft: true
tags: ["backend"]
---

## はじめに

RailsでXSS攻撃の対象になるパターンについて、調べてみたので少しまとめてみました。

## RailsでXSSになるケースは？

### `.html_safe`/`raw`を使っている

対象として、固定の文字列 `"&nbsp;".html_safe` のように固定の文字列を使っている場合は問題ないが、
ユーザーが投稿したに内容、ユーザーが変更できる余地のある値などに対して使っている場合は問題になる。
まずは`html_safe`,`raw`で検索して使っている箇所をチェックするとよい。

良いケース

```ruby
"&nbsp;".html_safe
```

悪いケース

```ruby
@post.content.html_safe
```

## React.jsでXSSになるケースは？

jsx中の式埋め込みでは、react.js側でエスケープを行ってくれるので、それのみ利用する場合は問題ない。
問題になるケースがいくつか存在するようなので、気をつけたい。

### `dangerouslySetInnerHTML`を使っている

reactで、どうしてもhtmlを

https://ja.reactjs.org/docs/dom-elements.html#dangerouslysetinnerhtml
