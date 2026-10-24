# 宇治川ライン DRIFT — Web v0.4.0
iPhone/Safari向けの公開用Godot 4.5.1プロジェクト。7車種・3コース各5km。
公開URLは https://mike1192296-netizen.github.io/uji-line-drift-web/ 。

## 遊び方
Safariで公開URLを開く → プレイする → 横画面 → START。
左右ボタンと手動アクセル／ブレーキ。同時押し対応。VIEWで運転席と追従視点を切替。
共有メニューから「ホーム画面に追加」も可能。オフライン保証はありません。
初回はWebAssemblyとゲームデータを読み込みます。WebGL 2必須。iPhone実機・Safari固有の操作／音／性能は未検証です。
Web版は初期設定で影をOFF。音はユーザー操作後に再生されます。記録はブラウザ内に保存され、データ消去やプライベートブラウズでは保持できないことがあります。
App StoreアプリやIPAではありません。

## ビルドと公開
GitHub Actions「Web build」がmain更新でGodotのWebテンプレートを取得し、単一スレッドWebGL 2版をbuild/webに出力。
出力のみをgh-pagesブランチへコミットします。Settings > Pages > Deploy from a branch > gh-pages / (root) を指定。
既にPagesが有効ならAPIでPagesビルドを要求します。Actions Artifactの容量を使用しません。
ローカル: Godot 4.5.1のExport Templates導入後、
```
mkdir -p build/web/game
godot --headless --editor --import --quit
godot --headless --export-release Web build/web/game/index.html
cp web/* build/web/
python3 -m http.server 8000 --directory build/web
```
http://localhost:8000/ を開く。HTMLファイルの直接起動は不可。
APK開発用の既存リポジトリとは別の公開用スナップショットです。以降の変更はこのリポジトリにも反映が必要です。

## 制限・出典
車両形状は自作の簡略モデル。馬力・トルク・変速比の出典と推定箇所はdata/POWERTRAIN.md。
タイムと接触+3秒ペナルティ、ベスト記録、設定に対応。実車の完全な物理再現ではありません。
画像素材は本作向け生成アトラス、メッシュと音は自作。Noto Sans JPサブセットはSIL OFL 1.1（fonts/OFL.txt）。
