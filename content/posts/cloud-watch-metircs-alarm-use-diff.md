---
title: "CloudWatch Metrics で変化量をアラームにする"
date: 2021-08-05T21:11:47+09:00
draft: false
tags: ["infra"]
categories: ["infra", "aws"]
---

## 概要

- cloudwatch metricsで、常に増加するような値をアラームにするやり方について

## やり方

使用したいメトリクスを選択し、数式の追加から `DIFF` を選択すると
式1 `DIFF(METRICS())` が追加される。これを利用すると直前と現在の値の差を出せるようになる。
ただしこれをアラームにしようとすると `アラームの式では、正確に 1 つの時系列を作成する必要があります。` 
と注意が表示されてアラームにできない。  
正しくは次のように 明示的に関数に利用するメトリクスのIDを指定する。

```
`DIFF(METRICS())`  => `DIFF(m1)` 
```

## 参考情報

- [メトリクスの数式に基づく CloudWatch アラームの作成 - Amazon CloudWatch]( https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/Create-alarm-on-metric-math-expression.html )
- [Using metric math - Amazon CloudWatch]( https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax )
