---
title: "Shell Commands Cheet Sheet"
date: 2021-09-27T11:20:19+09:00
lastmod: 2021-12-07
draft: false
tags: ["infra"]
---

## du

普通にカレントディレクトリのファイル・ディレクトリのサイズを個々に調べる

```bash
$ du -hs *
```

↑のやり方では、隠しファイルを含めてサイズを表示することができない。
隠しファイルも含めて合計サイズを調べたい場合は、下記のようにする。

```bash
$ du -hs $(ls -A)
```

## find

2日以上前に変更のあったディレクトリ
- -mtime :
  - +2 2日以前の変更
  - -2 2日以降の変更
- -type
  - d : ディレクトリ
  - f : 通常ファイル

```bash
find ./ -mtime +2 -type d
```

## lsof

ロックされているファイルとプロセスを表示する

```bash
lsof / | sort -k7 -nr | head -5
```
