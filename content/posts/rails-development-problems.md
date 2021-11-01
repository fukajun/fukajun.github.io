---
title: "Railsでハマルやつ"
date: 2021-07-19T03:50:43+09:00
draft: false
tags: ["backend"]
---

## secret_key_base設定漏れで謎のエラー

### エラー

- `An unhandled lowlevel error occurred. The application logs may have details.`

### 対応

`secret_key_base` が設定されていないことが原因、ちゃんと値が設定されているかを確認する  
値は、`bundle exec rake secret` で作ることができる。  
生成された値を設定ファイル等に設定しておく




## assetsの配信設定
### 症状

- Railsをproductionで起動したとき、css, jsが読み込めない

### 対応

`config/environments/production.rb` の `config.public_file_server.enabled` を `true` に設定する 

ただし、本来はpublic/配下のstaticなファイルをrailsに配信させるのはあまりおすすめの設定ではないので、nginx等のwebサーバーやcdnから配信するほうが良い

Rails5以降だと上記の設定だけど、Rails4までだと `config.serve_static_files` という設定項目だった

## Rails serverコマンド強制停止させる

### 症状

- 重たいクエリーや重たい処理をやっていて `rails s` の応答がなくなった。
- 処理は行っていそうだけど、長時間待たされる可能性がある


### 対応

プロセス番号を調べてから `kill` コマンドで停止させるというのが一般的だけど、もう少し簡単に行う方法です。
一度サスペンドさせてから、バックグランドで動かして、killコマンドで強制停止させると簡単です。
くれぐれも、`-9` は乱用しないようにしましょう。

```
# Ctrl + z
# サスペンドされる
 % bg
[1]  + continued  bundle exec rails s
 % kill -9 %1
[1]  + killed     bundle exec rails s
```
