# MWBase × VRMod 互換性調査レポート

## 概要
MWBase武器がVRModで正しく表示されない問題の根本原因と解決策を分析。

---

## 1. アーキテクチャ比較

### MWBase ビューモデルシステム
- **独自エンティティ**: `mg_viewmodel` エンティティを作成
- **NetworkVar**: `SWEP:CustomNetworkVar("Entity", "ViewModel")` で管理
- **位置計算**: `CalcViewModelView` フックで独自のスプリング物理エンジンを使用
- **描画**: 独自の `cl_render.lua` で描画制御

### VRMod ビューモデルシステム
- **標準GMod**: `LocalPlayer():GetViewModel()` を使用
- **フック**: `CalcViewModelView`, `PreDrawViewModel` で制御
- **位置計算**: コントローラー追跡 + オフセット適用

---

## 2. 根本原因

### 衝突ポイント1: ビューモデル取得方法の違い
```lua
-- MWBase (mg_base/shared.lua:286-295)
function SWEP:Initialize()
    if (SERVER) then
        local vm = ents.Create("mg_viewmodel")  -- 独自エンティティ
        vm:SetParent(self)
        vm:Spawn()
        self:SetViewModel(vm)  -- NetworkVarに保存
    end
end

-- VRMod (vrmod_viewmodelinfo.lua:98)
g_VR.viewModel = not drawWorld and LocalPlayer():GetViewModel() or wep
```

### 衝突ポイント2: フックの競合
- **MWBase**: `CalcView` フックで独自計算 (`cl_calcview.lua`)
- **VRMod**: `CalcViewModelView` フックで上書き (`vrmod.lua:958`)

---

## 3. データフロー図

```
MWBase:
プレイヤー → 武器 → mg_viewmodelエンティティ → 独自描画

VRMod:
プレイヤー → LocalPlayer():GetViewModel() → VR追跡 → 標準描画
```

---

## 4. 解決オプション

### オプションA: VRMod側でMWBase対応を追加 (推奨)
**変更箇所**: `vrmod_viewmodelinfo.lua`
```lua
function vrmod.UpdateViewmodelInfo(wep, force)
    -- MWBase武器の検出
    if wep:GetViewModel and IsValid(wep:GetViewModel()) then
        g_VR.viewModel = wep:GetViewModel()
    else
        g_VR.viewModel = LocalPlayer():GetViewModel()
    end
end
```

### オプションB: MWBase側でVRMod対応を追加
**変更箇所**: `mg_viewmodel/client/cl_calcview.lua`
- VRModがアクティブな場合に標準ビューモデルを使用するように分岐

### オプションC: 両者のハイブリッド
- MWBaseのアニメーションシステム + VRModの位置追跡を組み合わせ

---

## 5. 実装プラン (オプションA)

### ステップ1: MWBase武器の検出
```lua
local function IsMWBaseWeapon(wep)
    return wep:GetClass():find("^mg_") or IsValid(wep:GetViewModel())
end
```

### ステップ2: ビューモデル取得の修正
`vrmod.lua` の `UpdateViewmodelInfo` 関数を修正

### ステップ3: フックの調整
`CalcViewModelView` フックでMWBaseエンティティを処理

---

## 6. 検証手順

1. MWBase武器を装備
2. VRModがビューモデルを正しく認識するか確認
3. コントローラー追跡が機能するかテスト
4. アニメーションが正常に再生されるか確認

---

## 7. 影響範囲

### 変更が必要なファイル
- `vrmodunoffcial/vrmod_viewmodelinfo.lua` - ビューモデル取得ロジック
- `vrmodunoffcial/vrmod.lua` - フック処理

### 既存機能への影響
- 標準GMod武器には影響なし
- MWBase以外のカスタムビューモデル武器にも対応可能
