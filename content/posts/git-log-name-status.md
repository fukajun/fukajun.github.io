---
title: "git logで変更の種別(変更/削除/追加)を表示する"
date: 2021-08-15T14:19:27+09:00
draft: false
tags: ["tools"]
---

## 概要

ファイル生成コマンドが行った変更を取り消したい。
そのために、gitの履歴で `git status` ライクにファイル毎の変更種別を方法を調べた。
具体的には、A:追加 M:変更 D:削除のように表示してほしい。

## やり方

`git log --name-status` を使う。  
同様に `git show --name-status <commit hash>` で特定の変更のみをみることもできる

### 表示例

```
commit b2931fae2dc118ad34d19fe28f2bb0f6ef2244a6
Author: fukajun <xxxxxx>
Date:   Sat Sep 22 14:48:04 2018 +0900

    Setup webpacker

A       .babelrc
M       .gitignore
A       .postcssrc.yml
M       Gemfile
M       Gemfile.lock
A       app/javascript/packs/application.js
A       bin/webpack
A       bin/webpack-dev-server
M       config/environments/development.rb
M       config/environments/production.rb
A       config/webpack/development.js
A       config/webpack/environment.js
A       config/webpack/production.js
A       config/webpack/test.js
A       config/webpacker.yml
M       package.json
A       yarn.lock
```

こんな感じで、それぞれファイルをどう変更したのかがわかるようになる。

- A Add 追加
- M Modify 変更
- D Delete 削除

過去に振り返って、手作業で変更を取り消すときなどに便利

## 参考情報
- [git - Know which files were created, modified or deleted in a commit - Stack Overflow](https://stackoverflow.com/questions/55198336/know-which-files-were-created-modified-or-deleted-in-a-commit)
