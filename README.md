# vrmod_semioffcial_addonplus

VRMod (semiofficial / original v21) 用の追加アドオン。VR未接続時は一切動作しない。

## 必要なもの

- Garry's Mod
- [VRMod semiofficial](https://steamcommunity.com/sharedfiles/filedetails/?id=1678408548) または オリジナル VRMod
- SteamVR対応HMD

## 機能一覧

### 武器操作

| 機能 | 内容 |
|------|------|
| ホルスターシステム (Type1/Type2) | 体の周囲に武器を格納・取り出し。左右手別ロック、スロット12個、OBB判定 |
| フォアグリップ | 両手持ち。左手をフォアグリップ位置に近づけて掴む |
| マガジンボーンシステム (VRMag) | マガジンを掴んで手動リロード。ボーン自動検出 |
| ARC9対応 | ARC9武器フレームワークのViewModel自動更新、マガジンボーン非表示/復元 |
| 近接攻撃 | 手の相対速度ベース。HMD速度を差し引いて移動中の誤検出を防止 |
| ViewModelInfo自動調節 | マズルアタッチメント基準でオフセットを自動計算、JSONに保存 |

### 操作・入力

| 機能 | 内容 |
|------|------|
| 物理ガンVRピックアップ | 条件付きビーム可視化（手が空き+拾えるものにヒット時のみ） |
| VRピックアップ改善 | 自動ドロップ制御、VRMod_Exit時クリーンアップ |

### 車両

| 機能 | 内容 |
|------|------|
| LVS車両統合 | LVS車両のVR操作対応 |
| 車両ビューリセット | VRMod Menu経由で動作するReset Vehicle View |


### UI・メニュー

| 機能 | 内容 |
|------|------|
| Settings02 DTreeサイドバー | VRModメニュー内に左サイドバー+コンテンツパネル。16カテゴリ |
| スポーンメニュータブ | Qメニューに「VRMod」タブを追加。8カテゴリ |
| Feature Guide | 機能組合せガイド+トラブルシューター。en/ja/ru/zh対応 |
| 最適化プリセット | 4段階 (変更なし / リセット / 最適化 / 最大最適化) |

### その他

| 機能 | 内容 |
|------|------|
| デスクトップカメラ共存 | VR描画と非VR描画を分離。他カメラmodとの共存、鏡にプレイヤー表示 |
| VRE ConVar互換ブリッジ | VRE Dynamic Menuのvrutil_* ConVarと双方向同期 |
| SteamVRバインディング | コントローラーバインド設定 |
| アイトラッキング (SRANIPAL) | 対応デバイス使用時 |
| Cardboard VR | スマートフォンVR対応 |
| デバッグツール | コールバックプロファイラ、stale hook検出、キー入力モニター、UI描画スキャン |

## インストール

Workshop版: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2780083257)からサブスクライブ

手動: このリポジトリを `garrysmod/addons/` に配置

## フォルダ構成

```
lua/
  autorun/            エントリーポイント
  vrmodunoffcial/
    0/  コア・API
    1/  自動設定・最適化
    2/  ホルスター Type2
    3/  フォアグリップ
    4/  マグボーン・ARC9
    5/  近接攻撃
    6/  ホルスター Type1
    7/  VR Hand HUD
    8/  物理ガンピックアップ
    9/  VRピックアップ
    10/ デバッグ
    11/ Feature Guide
    12/ Guide UI
    13/ RealMech
    14/ VR Throw
    15/ Hand Sync

materials/              VMTファイル
models/                 モデルファイル
```


## ライセンス

[LICENSE](LICENSE) を参照。
