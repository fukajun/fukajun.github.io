---
title: "Railsとelasticache(memcached)について"
date: 2021-10-29T12:27:32+09:00
lastmod: 2021-11-02
draft: false
tags: ["infra", "backend"]
---

## はじめに

Railsで、elasticache(memcached)を使ったときに調べたことについて書いてみた

## Railsでelasticacheを使うには？

[dalli-elasticache](https://github.com/ktheory/dalli-elasticache)がある。4年位更新されてないけど、依存しているgemがdalliだけで、elasticache自体の仕様も殆ど変わっていないので未だに使える。  
役割自体も、設定エンドポイントからクラスターに所属するホストの一覧を取得して、dalliに渡していい感じに初期化しているだけなのでシンプル。

## 設定エンドポイントとは？

elasticache memcachedクラスターの代表となるエンドポイント

## どうやってノードを取得しているか？

ノードの取得方法は、dalli-elasticacheが設定エンドポイントに対して、専用のコマンドを投げることによってノードの一覧を取得している。下記が実際にやってみたサンプル


```
[root@hoge ~]# echo 'config get cluster' | nc -v hoge.fgjtnh.cfg.apne1.cache.amazonaws.com 11211
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 10.13.48.xxx:11211.
CONFIG cluster 0 174
3
hoge.fgjtnh.0001.apne1.cache.amazonaws.com|10.13.48.xxx|11211 hoge.fgjtnh.0002.apne1.cache.amazonaws.com|10.13.10.xxx|11211

END
Ncat: 19 bytes sent, 203 bytes received in 0.01 seconds.
```

※実際にやってみるてわかったが、各ノードに同じコマンドを送っても同様のものを取得することができた。

## クラスターにはどのようにキーが格納されているか？

クラスターといっても実際には複数のノードにシャーディングされているだけなので、各ノード間でレプリケーションされているわけではない。  
なのでそれぞれの値は、クラスターに所属するノードに独立して保存されている。`どのノードに保存するかはdalliが格納/検索するときのキーからノードを決定している。`  
dalliを経由せずにtelnetなどで直接値を取得する場合は、全サーバーにキーを問い合わせてみる必要がある。
これは結構めんどくさいし、代表エンドポイントに問い合わせてもいずれかのノードに聞いてくれるだけなので、キーがあったりなかったりするので注意が必要。

## dalliはどのように格納するノードを決めているか？

dalli gem自体で、複数のmemcachedを扱うことが出来るようになっている  
複数のmemcached(ノード群)は初期化時に登録される。  
どのノードに格納するかは、キーを元に算出するようになっている  
下記が決定に使われているメソッド[(コード)](https://github.com/petergoldstein/dalli/blob/3ecc41e2e4521fd969d50a396b5a82e33c4e8226/lib/dalli/ring.rb#L32-L51)

```ruby
    def server_for_key(key)
      if @continuum
        hkey = hash_for(key)
        20.times do |try|
          # Find the closest index in the Ring with value <= the given value
          entryidx = @continuum.bsearch_index { |entry| entry.value > hkey }
          if entryidx.nil?
            entryidx = @continuum.size - 1
          else
            entryidx -= 1
          end
          server = @continuum[entryidx].server
          return server if server.alive?
          break unless @failover
          hkey = hash_for("#{try}#{key}")
        end
      else
        server = @servers.first
        return server if server&.alive?
      end
```

## まとめ

というわけで、Railsでelasticache(memcached)を使ったときのことを書いてみた。
そもそもelasticacheのクラスターについて知らなくて、格納されているキーを探すのも一苦労だった。まずは敵を知ることの大切さがわかった。
