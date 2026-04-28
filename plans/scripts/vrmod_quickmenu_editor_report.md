# vrmod_quickmenu_editor.lua — クイックメニューエディタUI

**ファイルパス**: `lua/vrmodunoffcial/vrmod_quickmenu_editor.lua`
**行数**: 473行
**種別**: クライアントサイド
**役割**: クイックメニュー項目の追加・編集・削除・並べ替えを行うDermaベースのGUIエディタ

---

## 1. ファイル概要

このファイルは「クイックメニュー設定」を**視覚的に編集**するためのDermaパネルを実装する。`vrmod_quickmenu_config.lua` で読み書きされるJSON設定の「エディタフロントエンド」を担当し、メニュー項目の追加・編集・削除・並べ替え・プレビュー機能を備える。

### 主な機能
- メニュー項目の一覧表示（DListView）
- 項目の追加・編集・削除・上下移動
- 6×10グリッド上のプレビュー表示
- 項目エディタダイアログ（名前・スロット・位置・アクションタイプ・値）
- メインメニュー（`VRMod_Menu`フック）への統合

---

## 2. ConVar一覧

| ConVar名 | デフォルト | 説明 |
|---------|-----------|------|
| `vrmod_quickmenu_use_custom` | `1` | カスタムクイックメニュー設定の使用有無（チェックボックスで切り替え） |

---

## 3. グリッド定数

```lua
GRID_COLS = 6      -- 列数（スロット数 0〜5）
GRID_ROWS = 10     -- 行数（位置数 0〜9、設定ファイルでは0〜20だがUIでは0〜9）
CELL_WIDTH = 70    -- 1セルの幅（ピクセル）
CELL_HEIGHT = 40   -- 1セルの高さ（ピクセル）
CELL_PADDING = 2   -- セル間隔
```

---

## 4. 主要関数・構造体

### グローバル状態
```lua
local L = VRModL or function(_, fb) return fb or "" end  -- ローカライズ関数
```

### Dermaパネル定義
```lua
vgui.Register("VRMod_QuickMenuEditor", PANEL, "DPanel")
```

### PANEL構造（Init〜Paint）

#### PANEL:Init()
- **役割**: エディタUIの全ウィジットを初期化
- **サイズ**: 520×500ピクセル
- **構成要素**:
  | 要素 | 型 | 位置 | 説明 |
  |------|-----|------|------|
  | enableCheck | DCheckBoxLabel | (10,10) | `vrmod_quickmenu_use_custom` ConVar接続チェックボックス |
  | listLabel | DLabel | (10,40) | 「Menu Items:」ラベル |
  | itemList | DListView | (10,60) 300×180 | 項目一覧（Name/Slot/Pos/Type/Action列） |
  | addBtn | DButton | (320,60) 90×25 | 「Add」— 項目追加ダイアログを開く |
  | editBtn | DButton | (320,90) 90×25 | 「Edit」— 選択項目を編集 |
  | deleteBtn | DButton | (320,120) 90×25 | 「Delete」— 選択項目を削除 |
  | moveUpBtn | DButton | (320,160) 42×25 | 「Up」— 選択項目を上に移動 |
  | moveDownBtn | DButton | (368,160) 42×25 | 「Down」— 選択項目を下に移動 |
  | saveBtn | DButton | (320,200) 90×30 | 「Save」— 設定をJSONに保存 |
  | loadBtn | DButton | (420,200) 90×30 | 「Reload」— 設定を再読み込み |
  | previewLabel | DLabel | (10,250) | 「Preview (6x10 Grid):」ラベル |
  | previewPanel | DPanel | (10,270) | 6×10グリッドプレビュー（カスタムPaint） |

#### PANEL:UpdateButtonStates()
- **役割**: 選択状態に応じて編集/削除/移動ボタンの有効化を切り替え
- **判定**:
  - `hasSelection`: 選択行がありかつアイテムが存在 → Edit/Delete有効
  - `selectedIndex > 1`: 1行目以外 → Up有効
  - `selectedIndex < #items`: 最終行以外 → Down有効

#### PANEL:RefreshList()
- **役割**: `self.items` を `itemList` に反映
- **表示変換**:
  | actionType | 表示 |
  |-----------|------|
  | `convar_toggle` | "Toggle" |
  | `key_press` | "Key" |
  | `command` | "Cmd" |
- **キー表示**: `vrmod.InputEmu_GetKeyDisplayName()` でキーコードを人間 readable 名に変換
- **アクション値**: 15文字 truncation（... サフィックス）

#### PANEL:LoadConfig()
- **役割**: JSON設定を読み込んで `self.items` に設定
- **処理**:
  1. `vrmod.LoadQuickMenuConfig()` で設定読み込み
  2. `table.Copy()` でディープコピー
  3. `RefreshList()` で一覧更新
  4. `UpdateButtonStates()` でボタン状態更新

#### PANEL:SaveConfig()
- **役割**: `self.items` をJSONに保存
- **処理**:
  1. `vrmod.SaveQuickMenuConfig(self.items)` で保存
  2. 成功: `NOTIFY_GENERIC` 通知（2秒）
  3. 失敗: `NOTIFY_ERROR` 通知（3秒）
  4. カスタム設定有効時は `vrmod.ApplyQuickMenuConfig()` で即時反映

#### PANEL:PaintPreview(pnl, w, h)
- **役割**: 6×10グリッドのビジュアルプレビューを描画
- **描画処理**:
  1. 背景: 角丸黒（Color 30,30,30）
  2. グリッド配置: `grid[slot][pos]` にアイテム名をマッピング
  3. セル描画:
     - アイテムあり: 緑（60,100,60）
     - 空セル: 灰色（50,50,50）
     - 空セルには座標ラベル（col,row）
  4. テキスト: 8文字 truncation（7文字 + ".."）

#### PANEL:OpenItemDialog(editIndex)
- **役割**: 項目追加/編集ダイアログを表示
- **引数**: `editIndex` — nil=追加、number=編集対象インデックス
- **ダイアログ構成**（350×280ピクセル）:
  | 要素 | 型 | 説明 |
  |------|-----|------|
  | nameLabel + nameEntry | DLabel + DTextEntry | 項目名（必須） |
  | slotLabel + slotSlider | DLabel + DNumSlider | スロット 0〜5（整数） |
  | posLabel + posSlider | DLabel + DNumSlider | 位置 0〜9（整数） |
  | typeLabel + typeCombo | DLabel + DComboBox | アクションタイプ選択 |
  | valueLabel + valueEntry | DLabel + DTextEntry | コマンド/ConVar値 |
  | keyPickerLabel + keyPicker | DLabel + DComboBox | キーコード選択（key_press時のみ表示） |
  | okBtn | DButton | 確定（検証・追加/編集） |
  | cancelBtn | DButton | キャンセル |
- **アクションタイプ切替**: `typeCombo.OnSelect` で value/key picker の表示切替
- **キーピッカー**: `vrmod.InputEmu_GetAssignableKeys()` から利用可能なキー一覧を取得
- **検証**: 名前とアクション値が空の場合はエラー通知

---

## 5. メインフロー図

```mermaid
flowchart TD
    A[VRMod_QuickMenuEditor Init] --> B[enableCheck: ConVar接続]
    B --> C[itemList: 一覧表示初期化]
    C --> D[LoadConfig 呼び出し]
    D --> E{JSON存在?}
    E -->|No| F[items = 空テーブル]
    E -->|Yes| G[items = config.items コピー]
    G --> H[RefreshList]
    F --> H
    H --> I[UpdateButtonStates]
    I --> J[ユーザー操作]
    J --> K{操作}
    K -->|Add| L[OpenItemDialog nil]
    K -->|Edit| M[OpenItemDialog selectedIndex]
    K -->|Delete| N[table.remove items]
    K -->|Up| O[items交換: i↔i-1]
    K -->|Down| P[items交換: i↔i+1]
    K -->|Save| Q[SaveConfig]
    K -->|Reload| D
    L --> R[OK: newItem作成]
    R --> S{追加/編集?}
    S -->|追加| T[table.insert items]
    S -->|編集| U[self.items[editIndex] = newItem]
    T --> H
    U --> H
    N --> H
    O --> H
    P --> H
    Q --> V{保存成功?}
    V -->|Yes| W[NOTIFY_GENERIC + ApplyQuickMenuConfig]
    V -->|No| X[NOTIFY_ERROR]
    W --> H
    X --> H
```

---

## 6. メインメニュー統合

```lua
hook.Add("VRMod_Menu", "addsettings_quickmenu_editor", function(frame)
    if not frame or not frame.quickmenuBtnSheet then return end
    local sheet = frame.quickmenuBtnSheet
    local container = vgui.Create("DPanel", sheet)
    container:Dock(FILL)
    container.Paint = function() end
    local scroll = vgui.Create("DScrollPanel", container)
    scroll:Dock(FILL)
    local editor = vgui.Create("VRMod_QuickMenuEditor", scroll)
    editor:Dock(TOP)
    editor:SetTall(520)
    sheet:AddSheet(L("Quick Menu Editor", "Quick Menu Editor"), container, "icon16/application_view_tile.png")
end)
```

- `VRMod_Menu` フックでメインメニューの `quickmenuBtnSheet` にタブを追加
- `DScrollPanel` 内に `VRMod_QuickMenuEditor` を配置
- アイコン: `icon16/application_view_tile.png`

---

## 7. 他ファイルとの依存関係

| 依存ファイル | 関係 |
|------------|------|
| `vrmod_quickmenu_config.lua` | `vrmod.LoadQuickMenuConfig` / `vrmod.SaveQuickMenuConfig` / `vrmod.ApplyQuickMenuConfig` を使用 |
| `vrmod_input.lua` | `vrmod.InputEmu_GetAssignableKeys` / `vrmod.InputEmu_GetKeyDisplayName` をキーピッカーで使用 |
| `vrmod_ui_quickmenu.lua` | 同じグリッド構成（6列×10行）でプレビューと連動 |
| `vrmod.lua` | `g_VR.menuItems` は config で間接的に操作 |

---

## 8. VR関連の注意点

1. **Dermaは通常2D UI**: このエディタはVR内ではなく通常のGModメニュー上で動作（デスクトップモードで設定）
2. **グリッド数**: プレビューは 6×10（0〜9）だが、設定ファイルのバリデーションは slotPos 0〜20 を許容（UI制限はバリデーションより狭い）
3. **キーピッカー**: `vrmod.InputEmu_GetAssignableKeys()` に依存 — この関数が存在しない場合はキー選択機能が無効化される
4. **ローカライズ**: `L()` 関数でテキストをラップ（`VRModL` が存在しない場合は英語フォールバック）
5. **ダイアログ**: `SetDeleteOnClose(true)` で閉じた際に自動削除

---

## 9. アクションタイプとUIの対応

| アクションタイプ | valueEntry | keyPicker |
|----------------|-----------|-----------|
| `command` | 表示 | 非表示 |
| `convar_toggle` | 表示 | 非表示 |
| `key_press` | 非表示 | 表示 |

`typeCombo.OnSelect` で動的に表示切り替え:
```lua
typeCombo.OnSelect = function(_, _, _, data)
    local kp = (data == "key_press")
    keyPickerLabel:SetVisible(kp)
    keyPicker:SetVisible(kp)
    valueLabel:SetVisible(not kp)
    valueEntry:SetVisible(not kp)
end
```

---

## 10. 特記事項

- `self.items` は `table.Copy()` でディープコピー（JSON読み込み時）
- 保存時は `vrmod.SaveQuickMenuConfig()` が内部でバリデーションを行う（エディタ側でも検証は行わない）
- プレビューの座標ラベルは `col,row` 形式（0-indexed）
- ログ出力: `[VRMod] Quick Menu Editor loaded (tab disabled)` — 「disabled」は現在の状態を示すコメント
- `DNumSlider` の `SetDecimals(0)` で整数のみ許容（slot/slotPosは整数値のみ）

---

*作成日: 2026/4/27*
*分析完了: vrmod_quickmenu_editor.lua (473行)*