---
title: "envoyでrequest headerを変更する"
date: 2021-09-26T02:18:58+09:00
draft: false
tags: ["infra"]
---

## 概要
envoyを経由してhttpリクエストを、APPサーバーに送るときのヘッダー情報を追加/変更をしてみる

## やったこと

`route_config.request_headers_to_add` を利用する。`header`に `key` `value` を指定する。
appendについては、オプションだがデフォルトだと値の追加になり、下記の例で、`append: true` だと
`http`の値が来た場合に `http,https` のような変な値になってしまったので `append: false` を指定している。

```yaml
request_headers_to_add:
 - header: { key: "X-Forwarded-Port", value: "443" }
   append: false
 - header: { key: "X-Forwarded-Proto", value: "https" }
   append: false
```

### リクエスト情報をヘッダーの値として格納したい

formated-stringsを利用する。[ コレ ](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-strings)
`"%REQ(X-FORWARDED-FOR)%"` のような感じでリクエストのメタ情報を値として使うことができる
例えば...

- `%REQ(:METHOD)%`
- `%REQ(USER-AGENT)%`
- `%REQ(X-REQUEST-ID)`

などなど  
ちなみに先頭に `:` がつく、つかないの規則はよくわからない

```yaml
request_headers_to_add:
 - header: { key: "X-Forwarded-Port", value: "%REQ(X-REAL-FORWARDED-PORT)%" }
   append: false
 - header: { key: "X-Forwarded-Proto", value: "%REQ(X-REAL-FORWARDED-PROTO)%" }
   append: false
```

## 参考情報

- [HTTP route components — envoy 1.20.0-dev-755e28 documentation]( https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#http-route-components )

