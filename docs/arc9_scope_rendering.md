<<## ARC9 新スコープ (cl_pipscope_new.lua) 仕組み解析レポート

### 概要
- ファイル: `ARC-9/lua/weapons/arc9_base/cl_pipscope_new.lua`
- 無効化: `ARC9_ENABLE_NEWSCOPES_MEOW = false` (行1、`false` に変更で旧スコープに戻す)
- 旧スコープ (`cl_pipscope.lua`) は `self:GetShootPos()` をカメラ位置として使用
- 新スコープは `MainEyePos()` / `MainEyeAngles()` に変更

### レンダーターゲット (RT)

| 変数名 | 名前 | サイズ | フォーマット | 深度 | 用途 |
|---|---|---|---|---|---|
| `rt_main` | arc9_optic_main | scrw x scrh | RGB888 | SHARED | メインスコープRT |
| `rt_shaderpass` | arc9_optic_shaderpass | scrw x scrh | RGB888 | NONE | シェーダ後処理 |
| `rt_legacy_reticle` | arc9_optic_legacy_reticle | scrh x scrh | RGBA888 | NONE | 旧式レティクル |
| `rt_cheap` | arc9_optic_cheap | scrw x scrh | RGB888 | NONE | チープスコープRT |

### マテリアル

| 変数名 | 名前 | 親マテリアル | 用途 |
|---|---|---|---|
| `mat_rt_expensive` | arc9_mat_optic | UnlitGeneric | rt_main の表示 |
| `mat_rt_cheap` | arc9_mat_optic_cheap | UnlitGeneric | rt_cheap の表示 |
| `mat_legacy_reticle` | arc9_mat_optic_legacy_reticle | UnlitGeneric | レティクル表示 |
| `mat_shader_lense` | arc9/lense_shader | - | レンズ歪み・CA・ビネット |
| `mat_pixel_lense` | arc9/pixelation_shader | - | ピクセル化 |
| `mat_optic_surface` | effects/arc9/rt | - | .viewmodel への貼り付け |

### エントリポイント

`SWEP:RenderRT(cheap, magnification)` (行226)
  ├─ cheap=true → `SWEP:RenderRTCheap(atttbl)` (行272)
  └─ cheap=false → `SWEP:RenderRTExpensive(atttbl, magnification)` (行330)

### カメラ位置・角度

`rt_eyepos = MainEyePos()` (行340, 280, 233)
`rt_eyeang = MainEyeAngles()` (行339)

- これらは GMod 組み込み関数
- VR 中は VRMod の `CalcView` hook によって HMD の位置/角度が返される
- グローバル変数に保存され、後続の描画で使用される

### RenderRTExpensive (フル RT) のフロー

1. `rt_eyepos = MainEyePos()`, `rt_eyeang = MainEyeAngles()` でカメラ位置を取得
2. `render.RenderView(rt)` で `rt_main` に 3D シーンをレンダリング
   - `origin = rt_eyepos`, `angles = rt_eyeang`
   - `fov = rtfov` (拡大率で調整)
   - `drawviewmodel = rtvm` (convar `arc9_fx_rtvm`)
3. `rt_main` を `mat_shader_lense` でレンズ歪み・CA・ビネットを適用
4. `render.CopyRenderTargetToTexture(rt_shaderpass)` でシェーダパスにコピー
5. `DrawRTReticle` で .viewmodel のサブマテリアルに RT を貼り付け

### RenderRTCheap (チープ RT) のフロー

1. `render.GetScreenEffectTexture()` で現在の画面をコピー
2. `rt_cheap` にコピー + シャープニング
3. レティクル・影を描画

### 描画位置

`SWEP:DrawRTReticle(model, atttbl, nonatt, cheap)` (行475)
- `.viewmodel` の `atttbl.RTScopeSubmatIndex` 番目のサブマテリアルに RT を設定
- `model:SetSubMaterial(atttbl.RTScopeSubmatIndex, "effects/arc9/rt")`

### VR 中での問題

VR 中は `CalcView` hook (vrmod.lua:1014) が `isVRRendering = true` の時に `hmd.pos` / `hmd.ang` を返す
- `render.RenderView(rt)` が呼ばれると `CalcView` hook が発動
- `EyePos()` が HMD の位置を返す
- .viewmodel は右手の位置にある
- 両者が一致しないと「違う場所」を映す

### VR 外での動作

VR 外のときは `g_VR.active = false` で hook が削除されてるから、VRMod は関係ない

</content>
<parameter=filePath>
R:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\vrmod_semioffcial\docs\arc9_scope_rendering.md