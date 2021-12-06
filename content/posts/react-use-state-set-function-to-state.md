---
title: "React Hooksでstateに関数(function)を設定する"
date: 2021-12-01T12:27:32+09:00
lastMod: 2021-12-01
draft: false
tags: ['front']
---

## はじめに

react hooksを使っているときに、関数を状態として持たせたいというのがあった。
なかなかない状況ではあるが、メモしておく。

## stateに関数(function)を設定するには？

setStateには、引数として渡した関数を評価し、結果をstateに割り当てるという動作もある。
なので、関数をそのまま渡しただけでは、その関数の評価後の値がstateに割り当てられるだけで目的を達成できない
単純で、関数を返す関数を渡すだけである。

```js
const [state, setState] = useState(()=> {})

setState(()=> { console.log('invoked setState') }      # こっちは間違い
setState(()=> ()=> { console.log('invoked setState') } # コチラが正しい
```

## まとめ

リファレンスをちゃんと目を通していると載っているのだけど、探そうと思うと以外に探しにくい情報だった
公式リファレンスをざっと眺めておくみたいなのはやっぱり重要である。

## 参考情報

- [フック API リファレンス – React](https://ja.reactjs.org/docs/hooks-reference.html#usestate)
