---
title: "Rails on Lambda"
date: 2021-06-22T22:48:02+09:00
lastmod: 2021-06-23T01:48:02+09:00
draft: false
tags: ["backend"]
---

## Rails on Lambdaとは？
AWS Lambda上でRailsが動くぽいので試してみた。
過去にaws lambda上で動くrailsライクなフレームワーク[jets](https://rubyonjets.com/)の存在は知っていたが、Railsがそのまま動くのは知らなかった。
[lambdaのコンテナイメージのサポート](https://aws.amazon.com/jp/blogs/news/new-for-aws-lambda-container-image-support/)が関係してそう。

## lamby

[Lamby](https://github.com/customink/lamby)は、まさにRailsをlambda上で走らせるためツールで、新規Railsプロジェクトの作成、Dockerイメージのビルド、Lambdaへのデプロイ、ApiGatewayの作成など面倒を見てくれる。

## 簡単に試す


[公式のQuickStart](https://lamby.custominktech.com/docs/quick_start)に書いてあるとおりにやるとできた。  
とりあえず実行したコマンドは、下記のとおりだけど詳しくは公式をみるのが良い。


### プロジェクト作成

デプロイ等に必要なコマンドが配置されたRailsプロジェクトを作成してくれる。
実行するとプロジェクト名を聞かれるので好きな名前を入力する。


```shell
$ docker run \
  --rm \
  --interactive \
  --volume "${PWD}:/var/task:delegated" \
  lambci/lambda:build-ruby2.7 \
  sam init --location "gh:customink/lamby-cookiecutter"
```

```
project_name [my_awesome_lambda]:
```

### セットアップ

作られたプロジェクトディレクトリに移動して、下記のコマンドを実行する。
ここから、AWSに必要な設定が行われれるので
`AWS_ACCESS_KEY_ID` `AWS_SECRET_ACCESS_KEY` `AWS_REGION` など自分のAWS環境にアクセスできるように環境変数等をせってシておく必要がある。

```
$ cd my_awesome_lambda
$ ./bin/bootstrap
$ ./bin/setup
```

- `bootstrap` : ecrにリポジトリが作成される  
- `setup` : `bundle install` と `yarn` を実行して必要なgenやnpm packageがインストールされる



### デプロイ

あとは下記のコマンドを実行すれば動くようになる。  
実行するとビルドされたdockerイメージがecrにプッシュされ、API Gateway、IAM、LambdaFunctionがClouformation経由で作成される。
そして最後にアクセス可能になったURLが表示される。=> https://xxxxx.execute-api.ap-northeast-1.amazonaws.com/production 

```
$ ./bin/deploy
```

おなじみの画面↓たったこれだけで、動くところまでいけるのは便利だ。

{{<figure src="/images/rails-screen-shot.png" title="">}}

## 作られたlambdaの設定について

- Memoryは、1792MBで設定されていた。しかし実行時の使用は150MB程度だったので、実装内容しだいではあるが、もうすこしサイズを下げて256MB程度でも良さそうだった。

## 速度について

気になる速度について、 ChromeのDeveloperツールで確認すると、下記のような感じだった
`rails new` したばかりのDBアクセスすらないrootページなのでなんともいえないけど  

- 初回: 3-4s くらい
- 2回目以降: 100ms-160ms くらい

[クラメソさん記事](https://dev.classmethod.jp/articles/measure-container-image-lambda-coldstart/)によると、1000並列同時アクセスした場合でも同様に初回起動のもの(コールドスタートのもの)は遅くなるが、それほど変わらない速度でレスポンスを返せるとのことだった

## まとめ

正直、これだけだとDBアクセスもない、実用的な処理も入っていない状態
なので、使えるかどうか判断しにくいけど、公式のドキュメントにも書いてある、相性の良さそうなAurora Servelessとも連携させるなどしてみたい。

## 参考

- https://aws.amazon.com/jp/blogs/news/new-for-aws-lambda-container-image-support/
- https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/runtimes-context.html
- https://aws.amazon.com/jp/blogs/news/new-provisioned-concurrency-for-lambda-functions/
- https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.how-it-works.html
