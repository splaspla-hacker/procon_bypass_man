# ProconBypassMan
* プロコンを連射機にしたり、マクロを実行できるツールです
    * 設定ファイルはrubyスクリプトで記述します
* 特定のタイトルに特化した振る舞いにしたい時は各プラグインを使ってください

## 使うハードウェア
* プロコン
* Switch本体とドック
* Raspberry Pi4
    * 他のシリーズは未確認です
* データ通信が可能なUSBケーブル

## 使うソフトウェア
* 必須
  * ruby-3.0.x

## Usage
* 以下のファイルを用意して`sudo`をつけて実行してください
    * ex) `sudo bin/run.rb`

```ruby
# bundler inline
require 'bundler/inline'

gemfile do
  gem 'procon_bypass_man', github: 'splaspla-hacker/procon_bypass_man', branch: "0.1.1"
end

ProconBypassMan.run do
  prefix_keys_for_changing_layer [:zr, :r, :zl, :l]

  layer :up do
    flip :zr, if_pressed: :zr
    flip :zl, if_pressed: [:y, :b, :zl]
    flip :down, if_pressed: true
  end
  layer :right do
  end
  layer :left
  layer :down do
    flip :zl, if_pressed: true
  end
end
```

### プラグインを使った設定例
```ruby
#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  gem 'procon_bypass_man', github: 'splaspla-hacker/procon_bypass_man', branch: "0.1.1"
  gem 'procon_bypass_man-splatoon2', github: 'splaspla-hacker/procon_bypass_man-splatoon2', branch: "master"
end

fast_return = ProconBypassMan::Splatoon2::Macro::FastReturn
guruguru = ProconBypassMan::Splatoon2::Mode::Guruguru

ProconBypassMan.run do
  install_macro_plugin fast_return
  install_mode_plugin guruguru

  prefix_keys_for_changing_layer [:zr, :r, :zl, :l]

  layer :up, mode: :manual do
    flip :zr, if_pressed: :zr, force_neutral: :zl
    flip :zl, if_pressed: [:y, :b, :zl]
    flip :down, if_pressed: :down
    macro fast_return.name, if_pressed: [:y, :b, :down]
  end
  layer :right, mode: guruguru.name
  layer :left do
    # no-op
  end
  layer :down do
    flip :zl
  end
end
```

* 設定ファイルの例
  * https://github.com/jiikko/procon_bypass_man_sample

## Plugins
* https://github.com/splaspla-hacker/procon_bypass_man-splatoon2

## プラグインの作り方
https://github.com/splaspla-hacker/procon_bypass_man-splatoon2 を見てみてください

### モード
* name, binariesの持つオブジェクトを定義してください
* binariesには、Proconが出力するバイナリに対して16進数化した文字列を配列で定義してください

### マクロ
* name, stepsの持つメソッドをオブジェクトを定義してください
* stepsには、プロコンで入力ができるキーを配列で定義してください
  * 現在はintervalは設定できません

## FAQ
### ソフトウェアについて
* どうやって動かすの?
    * このツールはRaspberry Pi4をUSBガジェットモードで起動して有線でプロコンとSwitchに接続して使います
* ラズベリーパイ4のセットアップ方法は？
    * https://github.com/splaspla-hacker/procon_bypass_man/tree/master/docs/setup_raspi.md
* モード, マクロの違いは？
    * modeはProconの入力をそのまま再現するため機能。レイヤーを切り替えるまで繰り返し続ける
    * マクロは特定のキーを順番に入れていく機能。キーの入力が終わったらマクロは終了する
* レイヤーとは？
    * 自作キーボードみたいな感じでレイヤー毎に設定内容を記述して切り替えれる

## TODO
* ログをfluentdへ送信
* 設定ファイルをwebから反映できる
* プロセスの再起動なしで設定の再読み込み
* ケーブルの抜き差しなし再接続
    * 接続確立後、プロセスを強制停止する、接続したままプロセスを再起動する
    * "81020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" 最後にデッドロックする
    * ケーブルを抜いてからリトライすると改善する
* ラズパイのプロビジョニングを楽にしたい
* 起動時に設定ファイルのlintを行う(サブスレッドが起動してから死ぬとかなしいのでメインスレッドで落としたい)
* レコーディング機能(プロコンの入力をマクロとして登録ができる)
* swtichとの接続完了はIOを見て判断する

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/procon_bypass_man. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/procon_bypass_man/blob/master/CODE_OF_CONDUCT.md).

### ロギング
```
ProconBypassMan.tap do |pbm|
  pbm.logger = STDOUT
  pbm.logger.level = :debug
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
