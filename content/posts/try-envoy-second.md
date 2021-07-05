---
title: "Try envoy(Health checks)"
date: 2021-07-06T01:43:21+09:00
draft: false
---

## try envoy

### Detecting Unavailable Services Using health checks and outlier detection

各接続先へのヘルスチェックを行う方法について説明してくれている。
clustersにhealth_checksを追加し、特定のヘルスチェックエンドポイントを指定してヘルスチェックを行う設定を行った。
`health_checks` と `common_lb_config` 配下あたりがポイント

チュートリアルどおりにhealth_checksのみを設定すると、エラーを返す
アップストリームに対しても変わらず、振り分けられてしまいうまく動作しなかった

いろいろ調べて、 `healthy_panic_threshold` をデフォルトの設定から変更しないと
状況によっては、エラーを返すサーバーにも振り分けられてしまうということがわかり
設定を変更した。
今回は、シンプルな動作にしたかったため `clusters.common_lb_config.healthy_panic_threshold` の設定を `0` に変更した


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
    common_lb_config:
      healthy_panic_threshold:
        value: 0
    health_checks:
    - timeout: 1s
      interval: 1s
      healthy_threshold: 3
      unhealthy_threshold: 3
      event_log_path: /tmp/health_check.log
      always_log_health_check_failures: true
      http_health_check:
        path: "/health"
        expected_statuses: [{start: 200, end: 201 }]
    load_assignment:
      cluster_name: nodes
      endpoints:
      - lb_endpoints:
        - endpoint:
            health_check_config:
              port_value: 80
            address:
              socket_address: { address: web1, port_value: 80 }
        - endpoint:
            health_check_config:
              port_value: 80
            address:
              socket_address: { address: web2, port_value: 80 }
        - endpoint:
            health_check_config:
              port_value: 80
            address:
              socket_address: { address: web3, port_value: 80 }

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```

## healthy_panic_threshold はなになのか？

公式に説明があった。[Panic threshold](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/panic_threshold#arch-overview-load-balancing-panic-threshold) 

ヘルスチェックに成功するhostの数がどれくらいのパーセンテージを下回るとパニックモードに移行するかを  
決めるしきい値。デフォルト設定だと、50%となっている。  
例えば4台中2台までヘルスチェックに成功しているhostの割合は50%で、
パニックモードに移行せず、残りの健康な2台にリクエストを振り分ける  
さらに障害が進み1台のhostのみが健康な状態になるとヘルスチェックに成功しているhostの割合が25%になり
しきい値を下回ることになりパニックモードへ移行する  
`healthy_panic_threshold` を0に設定することでパニックモードを無効にすることができる
この場合は、健康な台数が何台でもヘルスチェックに成功したhostにのみトラフィックを流し、
健康なhostが存在しない場合は、envoy自身が503を返すようになる

### パニックモードとは？

いくつかのhostのヘルスチェックが失敗ししきい値を下回った状態  
パニックモードに移行するとデフォルトではヘルスチェックに失敗しているhostも含め  
全てのhostにリクエストを流し始める
この動作は、[設定](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto#config-cluster-v3-cluster-commonlbconfig-zoneawarelbconfig)で、パニックモード時に

- 全てのhostにリクエストを流す(デフォルト)
- 全てのリクエストを遮断する

かを設定することができる。

