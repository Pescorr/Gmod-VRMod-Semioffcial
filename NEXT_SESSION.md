# NEXT SESSION: バグ修正・小改善（続き）

## 概要
NEXT_SESSION Phase 1の残タスクを実施する。タスク1-3はS6で完了済み。

## 完了済み（S6-S8）
- ~~1. vrmod_lefthandleftfireのデフォルト値変更~~ ✅ (S6)
- ~~2. Seat: reset vehicle view修正~~ ✅ (S6)
- ~~3. Type1ホルスター: 未所持武器のポーチロック問題~~ ✅ (S6)
- ~~4. Physgunビーム条件付き可視化~~ ✅ (S7、一部保留)
- ~~5. Mirror UI調査~~ ✅ (S8、ウィザード形式への計画派生)

## 次のアクション

**Phase 1（バグ修正・小改善）完了**。次は中規模な改善フェーズへ移行。

BACKLOGから次のタスクを選択するか、以下の候補から:

### 候補タスク（優先度順）

#### 小規模バグ修正
- [ ] Physgun関連の残課題（Pull時の衝突問題、ビーム発射位置）
- [ ] HUD安定化（vrmod_autohudctrl.lua等）

#### 中規模改善
- [ ] Holster位置の不安定さ改善（ボーン位置オフセット調整）
- [ ] Foregrip判定方式改善
- [ ] ウィザード形式Mirror UI（大規模）

## 進め方
- 完了したらPROGRESS.mdに記録
- 新しい問題が見つかったらBACKLOG.mdに追記
- 全て完了したら「中規模な改善」フェーズへ移行
