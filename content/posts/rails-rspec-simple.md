---
title: "Railsでrspecのシンプルな例"
date: 2022-04-19T14:19:27+09:00
draft: false
tags: ["backend"]
---

## はじめに

Railsでspecを書くときにこういう風に書いてという場合に、シンプルな例が欲しかったので書いてみました。


## こんな感じ

- itのなかはできるだけテストの対象のことだけを書く
- contextで条件分けをする
- contextのなかは、その文脈で差分が分かるようにする => `let(:name)...` の部分

対象のmodel

```ruby
class User < ActiveRecord::Base
  validates :name, format: { with: /\A[^-][0-9A-Za-z-]+\z/, message: "英数字及びハイフン(-)のみが使えます" }
end
```

上に対するテストコード

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validation about name rule' do
    let!(:user) { FactoryBot.build(:user, name: name) }

    context 'valid name' do
      let(:name) { 'mario-and-luige' }
      it 'return true' do
        expect(user.valid?).to be true
      end
    end

    context 'start with hiphen' do
      let(:name) { '-invalid-name' }
      it 'return false' do
        expect(user.valid?).to be false
      end
    end

    context 'include under score' do
      let(:name) { 'mario_luige' }
      it 'return false' do
        expect(user.valid?).to be false
      end
    end
  end
end
```

## これだけが良い書き方ではない

rspecの書き方は、何をテストしているかわかりやすく書くことは大切ですが、
それに対してのやり方は割と好みがあるなと感じています。

- [僕がRSpecでsubjectを使わない理由 - give IT a try](https://blog.jnito.com/entry/2021/10/09/105651)

