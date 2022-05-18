
---
title: "Rustチマチマノート"
date: 2022-05-18T03:50:43+09:00
lastMod: 2022-05-18
draft: false
tags: ["backend"]
---

## Rustをチマチマやるノート

### strとString

関数で文字列を返したいとき、strだとスコープを抜けるので、Stringだと返却できるよって書いてあって。よくわからんかったけど動いた

- [rustの関数で値を返す](https://teratail.com/questions/130050)


まったくもってこの2つの違いがわからないので調べたい

> Rustは文字列を表す型として &str と String がある
> これが、結構ややこしくて、どういうときにどっちを使うべきなのかがよくわからない

[[Rust] &strとStringを理解しようと思ったらsliceやmutを理解できてないことに気づいた話 - Qiita](https://qiita.com/yagince/items/e7474839246ced595f7a)

