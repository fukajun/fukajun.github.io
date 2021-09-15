---
title: "Railsでハマルやつ"
date: 2021-07-19T03:50:43+09:00
draft: false
tags: ["backend"]
---

# Railsハマルやつ

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

ただし、本来はpublic/配下のstaticなファイルをrailsに配信させるのはあまりおすすめの設定ではないので、nginx等のwebサーバーやcdnから配信するように吸うほうが良い

Rails5以降だと上記の設定だけど、Rails4までだと `config.serve_static_files` という設定項目だった
