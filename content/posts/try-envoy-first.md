---
title: "Try envoy(GettingStarted/NGINX/HAProxy)"
date: 2021-06-30T10:52:04+09:00
draft: false
tags: ["infra"]
---

## try envoyをやってみた

- 公式にものっているチュートリアルtry envoyをやってみた
  - https://www.katacoda.com/envoyproxy
- チュートリアル内の設定ファイルが1.18あたりだと動かないので書き換えてみた

## envoyについて

- サービスディスカバリ
- Istioの内部で動いているやつ
- プロキシーのすごいやつ

## envoyのコア機能について

最初の3つくらいのシナリオでは、envoyを構成する4つのコアコンポーネントについて繰り返し
説明されていた。  
envoyは次の4つを利用して、nginx、haproxyと同様の機能実現するといった内容だった  
シナリオ内で書かれていたことと、自分の理解を含めて説明する


### Listerner
どのようなリクエストを受け付けるかを定義する。現時点ではTCPベースのもののみサポートしている。  
受け付けたリクエストは次のFiltersに送られる
設定ファイル上では、`listener` と対応する

### Filters
データをパイプラインで処理する、送信前にgzipでデータを圧縮するようなフィルターの機能を有効化できる  
それぞれのFilterは次のコンポーネントであるRoutersを持つ
設定ファイル上では、`filter_chains` `filters` あたりが対応してる

### Routers
Filterで処理したトラフィックを、次のコンポーネントであるClusterを宛先に振り分ける機能  
設定ファイル上では、`route_config` あたりが対応している

### Clusters
リクエストの送信先を定義する、また紐づく送信先のヘルスチェック方法などを定義する  
設定ファイル上では、`clusters` に対応する

## シナリオについて

最初の3つのシナリオの内容と、自分なりに同様の内容を実現するための設定を作ったので
載せておく。
シナリオの内容が、過去のバージョンを対象とした内容になっているため、そのまま動かしても
現行である、1.18.3 あたりでは動作しなかったので注意が必要

### Getting Started with Envoy

envoyの設定を作成しながら基本的なenvoyの構成要素を説明してくれている。
最終的にenvoy経由で google.comに接続する設定を作った

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route: { host_rewrite_literal: www.google.com, cluster: service_google }
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: service_google
    connect_timeout: 10s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: www.google.com
                port_value: 443
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        sni: google.com

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```

Step4で、pathに合わせて各clusterを呼び分けるようにする設定に変更した

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["*"]
              routes:
              - match: { prefix: "/google/" }
                route: { host_rewrite_literal: www.google.com, cluster: service_google }
              - match: { prefix: "/yahoo/" }
                route: { host_rewrite_literal: www.yahoo.com, cluster: service_yahoo }
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: service_google
    connect_timeout: 10s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: google.com
                port_value: 443
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        sni: google.com
  - name: service_yahoo
    connect_timeout: 10s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: yahoo.com
                port_value: 443
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        sni: yahoo.com

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```


### Migrating from NGINX to Envoy Proxy

nginxの役割をenvoyで行うための設定について説明してくれている  
clusterに設定するアップストリームを複数にして、リバースプロキシとして分散させる  
さらにaccess_logでログ出力フォーマットの設定等についてできることを説明してくれていた  
nginxの設定と、envoyの設定を対応付けて説明してくれているのでわかりやすかった  
(下記、設定のclustersのweb{1,2,3}はdocker-composeで起動してあるテスト用のサーバー)

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address: { address: 0.0.0.0, port_value: 10000 }
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          access_log:
          - name: envoy.access_loggers.stdout
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains: ["one.example.com"]
              routes:
              - match: { prefix: "/" }
                route: { cluster: service1 }
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: service1
    connect_timeout: 10s
    type: STRICT_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: web1, port_value: 80 }
        - endpoint:
            address:
              socket_address: { address: web2, port_value: 80 }
        - endpoint:
            address:
              socket_address: { address: web3, port_value: 80 }

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```

### Migrating from HAProxy to Envoy Proxy

このシナリオでは、haproxyの役割をenvoyが担うための設定について説明してくれている  
nginxのシナリオとほとんど変わらない、json形式でのログ出力について説明があったくらい


```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address: { address: 0.0.0.0, port_value: 10000 }
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          access_log:
          - name: envoy.access_loggers.stdout
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
              log_format:
                json_format: {"protocol": "%PROTOCOL%", "duration": "%DURATION%", "request_method": "%REQ(:METHOD)%"}
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route: { cluster: nodes }
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: nodes
    connect_timeout: 1s
    type: STRICT_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: nodes
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: web1, port_value: 80 }
        - endpoint:
            address:
              socket_address: { address: web2, port_value: 80 }

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```

## リファレンスの見方

ネット上の情報だとv2の情報が多いのでv3の情報を調べたい場合
それぞれ調べたい設定項目をV3 API Reference でたどっていくと良かった
なかなかこのやり方にたどりつかず試行錯誤を繰り返した orz

- Listeners: https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto
- Clusters: https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto

## 資料
- envoy設定ファイルの公式サンプル[★ ](https://www.envoyproxy.io/docs/envoy/v1.18.3/configuration/overview/examples)
- v1.81.3のドキュメント[コレ](https://www.envoyproxy.io/docs/envoy/v1.18.3/)
