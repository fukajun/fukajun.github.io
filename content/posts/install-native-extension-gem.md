---
title: "gemのインストールに失敗したときにやること"
date: 2021-09-03T01:31:55+09:00
draft: false
---

## 概要

gemのインストールで失敗のほとんどは、native extensionありのgemじゃないかと思う  
今回は mysql2 gem のインストール時のハマったときのことを参考に失敗したときにやることについて書いてみた  
ちなみに、このままやればできるという内容ではないです


## インストールできたコマンド

まずはインストールすることができたコマンドについて

```
gem install mysql2 -v '0.5.3' -- --with-ldflags=-L/opt/brew/opt/openssl/lib/ --with-opt-lib=/opt/brew/lib/ --with-cppflags=-I/usr/local/opt/openssl/include
```

環境について

- OS: macOS Catalina
- バージョン: 10.15.7

## やること

### gem installを利用する

bundle installで試行錯誤していると時間がかかるので、gem install + バージョンを
使って試すほうがシンプルで早い

```
gem install xxx -v 'バージョン'
```

### オプションを指定する

gem install にnative extensionのコンパイルオプションを指定してみる、今回使ったものは下記の3つだった

- `--with-ldflags` : linker用のオプションを指定する `-L` はリンカーにライブラリの検索パスを追加する
- `--with-opt-lib` : ライブラリファイルを探索するディレクトリ DIR を追加する
- `--with-cppflags` : cプリプロセッサに指定するオプションを追加する `-I` はインクルードファイルを検索するときのパスを追加する 

### ディレクトリを確認する

gemをインストールできなかったときの解決記事は結構転がってるが、環境の違いなどでそのままではうまくいかないことも多い、
そういうときはインストールオプションの値が正しいかを確認する

インストールオプションに指定しているパスについて

- 指定しているパスが存在しているか？
- 存在していたときに、必要なライブラリやファイルが存在しているか？

### エラーログを確認する

gem installコマンドを叩いたときに表示されるエラーメッセージを確認する。
`$HOME/.rbenv/versions/2.4.2/lib/ruby/gems/2.4.0/extensions/x86_64-darwin-18/2.4.0/mysql2-0.5.2/mkmf.log` のようなログファイルが出力されているので
なかみをみて、`not found` みたいなメッセージが表示されていないかを確認する。


## 参考情報
- [library mkmf (Ruby 3.0.0 リファレンスマニュアル)](https://docs.ruby-lang.org/ja/latest/library/mkmf.html)
- [cc コンパイラオプション](https://docs.oracle.com/cd/E19957-01/806-4836/ccOptions.html)
- [CXXFLAGSとCPPFLAGSの違い – かひわし4v1.memo](https://blog.ef67daisuki.club/2017/05/cxxflags%E3%81%A8cppflags%E3%81%AE%E9%81%95%E3%81%84/)
