---
title: "BigQueryのパーティションについて調べてみた"
date: 2022-07-15T14:46:40+09:00
lastmod: 2022-07-15
draft: false
---

## はじめに

BigQueryを使うにあたって、クエリー料金を安く抑えるのに重要と思われる
パーティション分割について調べたときのメモ

## パーティション分割とは?

- テーブルをパーティションキーに指定した値でパーティションとして分割することができる
  - [BigQuery初心者を脱出したい２（パーティション分割テーブル）](https://zenn.dev/ykdev/articles/c98bbd8f87a9d7)
- パーティションをクエリーの条件に指定することでスキャン量をへらすことができる★
- テーブルを作るときに「パーティションとクラスタ」の設定でパーティション分割に利用する列を指定できる
- 列の型にあわせて、パーティションタイプを選べる
- パーティション列にDATETIMEを指定した場合は、「1日毎」「1時間ごと」「月別」「年別」を選択することができる


## パーティションの一覧を確認するには？

- [INFORMATION_SCHEMA を使用したテーブル メタデータの取得  |  BigQuery  |  Google Cloud](https://cloud.google.com/bigquery/docs/information-schema-tables?hl=ja#partitions_view)
- `INFORMATION_SCHEMA.PARTITIONS` テーブルを参照する方法を使う、ただしプレビュー機能となっている

```
select * from プロジェクト名.データセット名.INFORMATION_SCHEMA.PARTITIONS
```

クエリー設定をレガシーSQLに変更する必要があるが次の方法でも可能

```
select * from [ プロジェクト名.データセット名.対象テーブル名$__PARTITIONS_SUMMARY__]
```

## パーティションを削除するには？

### 手動での削除

下記のように書いてあるが、`DROP VIEW` `DROP TABLE` などは見つかるものの `DROP PARTITION` という構文は見つからなかった。

> テーブルの削除、ビューの削除、個々のテーブル パーティションの削除、ユーザー定義関数の削除は無料です。
> [料金  |  BigQuery: クラウド データ ウェアハウス  |  Google Cloud](https://cloud.google.com/bigquery/pricing#long-term-storage)

### 有効期限による削除

パーティションキーをもとにテーブルにパーティションの有効期限を設定することで、
期限切れのパーティションを自動で削除してくれる。
日時をもとにしたパーティションであれば、テーブルのデータを一定期間に保つことができる

- [分割テーブルの管理  |  BigQuery  |  Google Cloud](https://cloud.google.com/bigquery/docs/managing-partitioned-tables?hl=ja)
- [BigQuery 日付で自動的にパーティションを区切り有効期限を設定する - Qiita](https://qiita.com/Fea/items/c6ea946ad07e294450d6)


## まとめ

BigQueryのパーティションの使い方についてメモでした。

