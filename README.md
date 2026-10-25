# 宇治川ライン DRIFT — Web v0.4.2 (local, unpublished)
iPhone/Safari向けの公開用Godot 4.5.1プロジェクト。8車種・従来3コース各5km＋OSM形状プレビュー約10.86km。
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

## v0.4.1 local changes
- Added an original DJ Demio-inspired mesh, labelled 2016 13S / 1.3 petrol / FF / 6AT (not a diesel assumption).
- Added a permanent car-name HUD in chase and driver views. Existing controls and seven existing cars remain unchanged.
- Original source is preserved separately at commit 7d159cea9d2846e7677b4cd8be50e5e37ad2658c. This release is maintained in the public Web repository above.
- Tested with Godot 4.5.1: smoke, powertrain, driver_view, race_result, demio_hud, handling_parity, course_drive. All passed. 24 car/course combinations completed using automated driving. Existing seven cars had exactly equal position, velocity, rotation, RPM and gear for 1,800 identical-input frames per car against the original source.
- Web export passed. Browser-rendered visuals, iPhone touch/audio/performance and human driving have NOT been verified. Local rendering was blocked by X-server socket restrictions. Headless tests do not establish visual quality.
- Existing three fictional 5 km courses are unchanged. See the v0.4.2 OSM route preview below.

## v0.4.2
- H-BRAKE is an independent held touch control (keyboard SPACE), separate from normal BRAKE. Three-finger steering + throttle + handbrake supported. Pause, focus loss, cancellation and restart release it. Arcade rear-slip/deceleration model; not real brake calibration.
- SETTINGS: Counter assist OFF / WEAK / MEDIUM / STRONG, default WEAK; current setting also in HUD. Extra yaw/slip stabilisation, not lane/path steering. OFF + unused handbrake retains the original seven cars' deterministic response. Other saved settings/records stay intact.
- Fourth selectable route **UJI LINE / OSM PREVIEW** uses licensed OSM centreline points, approximately 10.86 km, not forced to 5 km. Start/end crop boundaries are approximate (hundreds of metres). West/Uji→northeast/Shiga direction is an assumption. Y=0 is intentionally an unverified placeholder: NOT actual road height, NOT downhill recreation. Width, rails and surroundings are provisional. No artificial generic bridges/tunnels/river were placed on this preview. Original 3 courses remain unchanged.
- Route data: © OpenStreetMap contributors, ODbL https://www.openstreetmap.org/copyright . The derived centreline JSON is included at routes/uji_visible_route_osm.json, with source nodes/ways and caveats. The map screenshot is not included or used as a texture.
- Detailed tests in build/*.log. Headless runtime verification does not prove smartphone visual quality, performance or feel. Browser/iPhone still require visual QA.

Final v0.4.2 verification: all 32 car/course combinations completed; all listed tests passed with no script/engine errors. Mirror-direction slide bounded for all eight cars. See data/VALIDATION-v0.4.2.json.
