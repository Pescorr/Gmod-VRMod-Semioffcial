<!-- Template v1.0 -->
# {project_name} 開発ポリシー（核心原則）

**作成日**: {date}
**最終更新**: {date}
**役割**: 設計の羅針盤。詳細な背景や判断理由を確認したい時に参照する。

> **注**: 核心ルール（原則・禁止事項・コーディング規約）はCLAUDE.mdに集約済み。
> CLAUDE.mdは毎セッション自動読込されるため、このファイルを毎回全文読む必要はない。

---

## プロジェクトの目的（Why）

### なぜ{project_name}を作るのか

<!-- 3-5 numbered goals. Each with sub-bullets: what IS in scope, what IS NOT -->

1. {goal_1}
   - {in_scope}
   - {not_in_scope}

2. {goal_2}
   - {in_scope}
   - {not_in_scope}

3. {goal_3}
   - {in_scope}
   - {not_in_scope}

### 開発順序の原則

<!-- What to build first, second, third. Prevents jumping ahead -->

1. {foundation_first: e.g. コア基盤（初期化、設定、基本構造）}
2. {core_features_second: e.g. 主要機能（ユーザーが直接使う機能）}
3. {advanced_features_last: e.g. 応用機能（最適化、拡張、統合）}
4. 各段階で動作確認を行ってから次に進む

### 技術的前提

<!-- Domain-specific context that rarely changes but is crucial for decisions -->
<!-- e.g. API versions, compatibility requirements, platform constraints -->

- {technical_context_1}
- {technical_context_2}

---

## 核心原則の詳細

<!-- For EACH principle listed in CLAUDE.md, provide full reasoning here -->

### 原則1: {principle_name}

<!-- What it means, why it matters, what is allowed, what is forbidden -->

- {what_is_allowed: e.g. 既存APIのシグネチャを変更しない}
- {what_is_forbidden: e.g. 後方互換性を壊す変更}
- **理由**: {why_this_matters: e.g. 既存のユーザー/プラグインが動作し続けるため}

### 原則2: {principle_name}

- {what_is_allowed}
- {what_is_forbidden}
- **理由**: {why_this_matters}

### 原則3: {principle_name}

- {what_is_allowed}
- {what_is_forbidden}
- **理由**: {why_this_matters}

<!-- Add sections for each principle in CLAUDE.md -->

---

## 採用しない要素（アンチパターン）

### 採用してはいけないもの

<!-- Numbered list. Each: name + concrete failure scenario -->

1. {anti_pattern_1}
   - 理由: {concrete_failure_scenario: e.g. パフォーマンスが10倍悪化する実測値あり}

2. {anti_pattern_2}
   - 理由: {concrete_failure_scenario}

3. {anti_pattern_3}
   - 理由: {concrete_failure_scenario}

### 採用するもの（参考にするもの）

<!-- Patterns and approaches worth following -->

- {good_pattern_1: e.g. モジュラーアーキテクチャ}
- {good_pattern_2: e.g. ロギングシステム}
- {good_pattern_3: e.g. 命名規約の統一}

---

## 品質基準（各セッション終了時に確認）

### コード品質チェックリスト

<!-- Generic gates + project-specific additions -->

- [ ] **動作確認済み**: 実装した機能が実際に動く
- [ ] **命名規則**: {naming_convention}を守っている
- [ ] **依存関係**: {dependency_rule}に従っている
- [ ] **名前衝突**: 既存システムと衝突していない
- [ ] **コメント**: 実装意図が説明されている
- [ ] **エラーハンドリング**: エラーが起きても致命的にならない
- [ ] {project_specific_quality_gate_1}
- [ ] {project_specific_quality_gate_2}

### テストケースの書き方

```markdown
## {feature_name} テストケース
- [ ] TC1: 基本動作の確認
- [ ] TC2: エラーケースの確認
- [ ] TC3: 既存システムとの互換性確認
```

**重要**: テストケースを書かずに実装を進めてはいけない

---

## 各セッションで守るべきルール

### ルール1: スコープ厳守
- 1セッションで1〜2タスクのみ
- **理由**: 欲張りすぎるとコンテキスト圧縮が発生し、中途半端な実装が残る

### ルール2: 動作確認必須
- 各セッション終了時に**最低限動くもの**を作る
- 動作しない状態で次セッションに進まない
- **理由**: 問題の切り分けが困難になる

### ルール3: 優先度の厳守

**必須機能**（これがないとプロジェクトとして成立しない）:
- {must_have_1}
- {must_have_2}

**重要だがオプション**:
- {nice_to_have_1}
- {nice_to_have_2}

### ルール4: コンテキスト管理
- CLAUDE.mdに核心ルールを集約済み（圧縮されない永続情報）
- 1セッション1〜2タスクに限定し、圧縮前に作業完了を目指す
- 大規模ファイル読込後は手動圧縮を検討
- **サブエージェント活用**: 大規模な調査や解析はサブエージェント（Task tool）に委任し、メインコンテキストを清潔に保つ。サブエージェントの結果はファイルパス参照のみでメインコンテキストに取り込む

### ルール5: 引き継ぎファイル必須
- セッション終了前に必ず以下を更新：
  - PROGRESS.md（進捗記録）
  - CODE_STATUS.md（実装済みファイル一覧）
  - LESSONS.md（新たな教訓があれば）
  - NEXT_SESSION.md（次セッションへの具体的指示）
- **NEXT_SESSION.mdは簡潔に**: コード埋込禁止、ファイルパス+行番号で参照

---

## 実装前の設計審問（Pre-Implementation Interrogation）

> 複雑な機能の実装前に、plan modeで設計を審問する。
> 手戻りコストが高い作業ほど、事前審問の価値が高い。

### いつ実施するか
- 新しいフェーズの開始時
- アーキテクチャに影響する機能の実装前
- 前セッションで設計上の疑問が残った時

### 審問で問うべきこと
- 「この設計で見落としているエッジケースは？」
- 「既存システムとの衝突はないか？」
- 「なぜこの設計か？代替案は？」
- 「この設計は核心原則に反していないか？」

### 審問の結果
- NEXT_SESSION.mdのタスク記述に反映する
- 重要な判断はLESSONS.mdに記録する

---

## 軌道修正プロトコル（Mid-Course Correction）

> セッション中に設計前提の誤りや方針変更が必要になった場合、
> パニックにならず以下の手順で軌道修正する。

### 手順

1. **問題の明確化**: 何が間違っていたかを1文で記述
2. **影響範囲の評価**: 既存コードのどこに影響するか（テーブルで整理）
   - 既存コードの中で「そのまま使えるもの」「修正が必要なもの」「廃棄すべきもの」
3. **回答可能な問い**: 判断材料として何を調べるべきか（具体的な質問を列挙）
4. **調査実施**: 問いに答える（サブエージェントの活用を推奨）
5. **ポリシー修正**: DEVELOPMENT_POLICY.md/CLAUDE.mdの該当箇所を更新
6. **LESSONS.mdに記録**: 番号付きで教訓として記録

### 重要な原則
- **サンクコスト回避**: 既存コードの「使える部分」を明示的に評価する
- **現セッション内で完結**: 軌道修正は現セッション内で完了させる。次セッションに持ち越さない
- **ポリシー更新必須**: 軌道修正の結果は必ずドキュメントに反映する

---

## 調査フレームワーク（Investigation Framework）

> 新しい技術的疑問や未知の領域に直面した場合、
> 以下のフレームワークで体系的に調査する。

### 構造

1. **問い（Question）**: 何を知りたいか
2. **情報源（Source）**: どこを調べるか（ファイルパス、ドキュメント、API）
3. **仮説（Hypothesis）**: 予想される答え
4. **期待する発見（Expected Finding）**: 具体的に何が見つかるはずか
5. **結果（Result）**: 実際に見つかったもの
6. **比較（Comparison）**: 仮説と実際の差 → 差があれば教訓として記録

### 使い方の例

```markdown
### Q1: {specific_question}
- **Source**: {file_path}:{line_range}
- **Hypothesis**: {expected_answer}
- **Result**: {actual_finding}
- **Lesson**: {if_hypothesis_was_wrong, what_was_learned}
```

---

## 成功の定義

このプロジェクトは以下を達成した時に成功とする：

1. {success_criterion_1: e.g. コア機能が正常動作}
2. {success_criterion_2: e.g. ユーザーが10分以内にセットアップ完了}
3. {success_criterion_3: e.g. 既存システムとの互換性維持}
4. {success_criterion_4: e.g. パフォーマンス基準を満たす}

---

## 失敗の兆候（これらが現れたら立ち止まる）

### 危険信号

- {failure_signal_1: e.g. 「とりあえず動けばいい」という実装}
- {failure_signal_2: e.g. テストケースを書かずに次の機能に進む}
- {failure_signal_3: e.g. エラーハンドリングがない}
- {failure_signal_4: e.g. 依存関係が不明確}
- {failure_signal_5: e.g. 既存の参考実装をそのままコピー（独自性を失う）}

### 対処法

1. **一旦実装を止める**
2. **このファイル（DEVELOPMENT_POLICY.md）を再読する**
3. **原則に立ち返って設計を見直す**
4. **必要なら前のセッションに戻る**（やり直しを恐れない）

---

## ファイル配置規約

### ディレクトリ構造

<!-- Define your project's fixed directory structure -->

```
{project_name}/
├── {dir_1}/          ({description})
├── {dir_2}/          ({description})
├── {dir_3}/          ({description})
├── CLAUDE.md
├── DEVELOPMENT_POLICY.md
├── NEXT_SESSION_TEMPLATE.md
├── NEXT_SESSION.md
├── PROGRESS.md
├── CODE_STATUS.md
└── LESSONS.md
```

### ファイル命名規約

<!-- Define naming conventions for your language/framework -->

- {convention_1: e.g. コンポーネント: PascalCase (UserProfile.tsx)}
- {convention_2: e.g. ユーティリティ: camelCase (formatDate.ts)}
- {convention_3: e.g. テスト: *.test.ts or *.spec.ts}

---

## 毎セッション開始時のチェックリスト

> **注**: CLAUDE.mdが毎セッション自動読込されるため、以下は補足用。

- [ ] CLAUDE.mdの核心原則を確認した
- [ ] NEXT_SESSION.mdの目標を理解した
- [ ] 前セッションの成果物を確認した（CODE_STATUS.md）
- [ ] LESSONS.mdの関連項目を確認した
- [ ] テストケースを確認した

**このチェックリストが完了するまで実装を始めてはいけない**

---

## 変更履歴

<!-- Version this document. Include date and reason for change -->

- {date}: 初版作成

---

**このファイルは、{project_name}プロジェクトの羅針盤です。**
**迷ったら、このファイルに戻ってください。**

**最終更新**: {date}
**バージョン**: 1.0
