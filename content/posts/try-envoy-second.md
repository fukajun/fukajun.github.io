---
title: "Try envoy(HealthChecks)"
date: 2021-07-06T01:43:21+09:00
draft: false
tags: ["infra"]
---

## try envoy

Envoyを触っていくにあたって、公式のチュートリアル[try-envoy](https://www.envoyproxy.io/try/)をやってみたきのメモ  
今回は「 Detecting Unavailable Services Using health checks and outlier detection」の内容について

## Detecting Unavailable Services Using health checks and outlier detection

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

#### endpointsが複数あり優先度が設定してある場合の動作

`lb_endpoints` が2つあり `priority`が0と1が設定されている下記のような設定のとき  
それぞれの`lb_endpoints`のグループを、p=0とp=1と呼ぶことにする

p=1全部のhostが健康な状態では、p=0だけにリクエストが送られる。そこからp=0で障害が起き
ヘルスチェックに失敗した台数を補うように、p=1にリクエストが送られるようになる  
トータルでp=0の100%相当のリクエストを受けれる台数が生きている場合はパニックモードには
移行しない。100%未満になる場合は、各グループごとにしきい値(`healthy_panic_threshold`)を
下回っていないかがチェックされ、それぞれのグループ毎に条件に当てはまる場合はパニックモードが適用される

```yaml
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
        priority: 0
      - lb_endpoints:
        - endpoint:
            address:
              socket_address: { address: web3, port_value: 80 }
        - endpoint:
            address:
              socket_address: { address: web4, port_value: 80 }
        priority: 1
```

この辺のことは、[ココ](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/panic_threshold#arch-overview-load-balancing-panic-threshold) に書いてあるので正確にはそちらをみるとよさそう

`If P=1 becomes unhealthy, panic threshold continues to be disregarded until the sum of the health P=0 + P=1 goes below 100%. At this point Envoy starts checking panic threshold value for each priority.`


P=1が不調になった場合、P=0+P=1の不調の合計が100%以下になるまで、パニック閾値は無視され続けます。この時点で、Envoyは各プライオリティのパニック閾値のチェックを開始します。


## 感想

シンプルにヘルスチェックに失敗したホストに送られなくするだけだろうと思っていたが
意外にヘルスチェックが失敗したときのリクエストの流し方にもいろいろ方針があることが
わかった。頭の片隅に入れておくと、何かのタイミングで活かせそうな内容だったというか
かなりシナリオの内容からはずれたところまできてしまった....

