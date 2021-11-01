---
title: "Shell Commands Cheet Sheet"
date: 2021-09-27T11:20:19+09:00
draft: false
tags: ["infra"]
---

## find

2日以上前に変更のあったディレクトリ
- -mtime :
  - +2 2日以前の変更
  - -2 2日以降の変更
- -type
  - d : ディレクトリ
  - f : 通常ファイル

```shell
find ./ -mtime +2 -type d
```

## lsof

ロックされているファイルとプロセスを表示する

```shell
lsof / | sort -k7 -nr | head -5
```
