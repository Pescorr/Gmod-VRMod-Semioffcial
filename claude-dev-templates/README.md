<!-- Template v1.0 -->
# Claude Code 開発様式テンプレート集

AI支援開発プロジェクトのための構造化ドキュメントシステム。
15セッション以上の実戦開発から抽出した手法を、任意のプロジェクトに適用可能な形式で提供する。

## ドキュメント階層

```
         CLAUDE.md (自動読込、毎セッション、~50行)
             |
  +----------+----------+
  |                     |
DEVELOPMENT_         MEMORY.md
POLICY.md            (自動読込、Auto Memory)
(迷った時のみ)
  |
  +-------+-------+-------+
  |       |       |       |
PROGRESS  CODE_   LESSONS  NEXT_SESSION
.md      STATUS    .md    _TEMPLATE.md
         .md                    |
                          NEXT_SESSION.md
                          (毎セッション作成)
```

## 読み込み頻度

| ファイル | いつ読むか | 誰が読むか |
|---------|-----------|-----------|
| CLAUDE.md | 毎セッション開始時（自動） | Claude |
| MEMORY.md | 毎セッション開始時（自動） | Claude |
| NEXT_SESSION.md | 毎セッション開始時（手動指示） | Claude |
| LESSONS.md | 番号で引用された時 | Claude |
| PROGRESS.md | セッション開始時（概要把握） | Claude + 人間 |
| CODE_STATUS.md | ファイル状態を確認する時 | Claude + 人間 |
| DEVELOPMENT_POLICY.md | 「なぜ」を確認したい時 | Claude + 人間 |
| NEXT_SESSION_TEMPLATE.md | 次セッション引き継ぎ作成時 | Claude |

## 各ファイルの役割

| ファイル | 一言説明 | 行数目安 |
|---------|---------|---------|
| **CLAUDE.md** | 不変のルール。毎セッション自動読込。圧縮されない | ~50行 |
| **DEVELOPMENT_POLICY.md** | ルールの「なぜ」。原則の背景と判断理由 | ~300行 |
| **NEXT_SESSION_TEMPLATE.md** | セッション引き継ぎのフォーマット強制 | ~200行 |
| **PROGRESS.md** | セッション履歴とフェーズ進捗 | 成長する |
| **CODE_STATUS.md** | 全ファイルの実装状態を一覧表示 | 成長する |
| **LESSONS.md** | 番号付き教訓。引用可能、追記のみ | 成長する |
| **MEMORY_GUIDE.md** | Auto Memory設定の手引き（プロジェクトにはコピーしない） | ~80行 |

## 設計原則

1. **「何」と「なぜ」の分離**: CLAUDE.mdにルール、DEVELOPMENT_POLICY.mdに理由
2. **セッションスコープ制御**: 1セッション1〜2タスクに限定
3. **テストファースト**: テストケースを実装前に定義
4. **番号付き教訓**: `L1`, `L2`...で引用可能。同じ議論を繰り返さない
5. **3層引き継ぎ**: 開始前確認 → 作業 → 検証+引き継ぎ
6. **圧縮生存**: Compact Instructionsセクションで、圧縮時に何を保持するか明示
7. **自己改善ループ**: 修正のたびにLESSONS.mdを更新し、同じ間違いを防ぐ

## クイックスタート（5段階、所要約25分）

### Phase 1: 初期化（5分）

1. このディレクトリからテンプレートファイルをプロジェクトルートにコピー
   - `CLAUDE.md`, `DEVELOPMENT_POLICY.md`, `NEXT_SESSION_TEMPLATE.md`
   - `PROGRESS.md`, `CODE_STATUS.md`, `LESSONS.md`
   - `MEMORY_GUIDE.md`はコピー不要（設定手引きのみ）
2. 各ファイルの`{placeholder}`を自分のプロジェクトに合わせて記入

### Phase 2: CLAUDE.md記入（10分）— 最重要

3. CLAUDE.mdを最初に記入する（これが全体の基盤）
   - 核心原則を3〜7個定義
   - 禁止事項を列挙
   - コーディング規約を設定
   - Compact Instructionsセクションを記入

### Phase 3: ポリシー定義（10分）

4. DEVELOPMENT_POLICY.mdを記入
   - CLAUDE.mdの各原則に理由を追加
   - アンチパターンを定義
   - 成功と失敗の基準を設定

### Phase 4: 追跡ファイル準備（3分）

5. PROGRESS.mdにPhase 0（プロジェクトセットアップ）を記入
6. CODE_STATUS.mdに初期ファイル構成を記入
7. LESSONS.mdはヘッダーのみで開始（教訓は経験から生まれる）

### Phase 5: 最初のセッション（2分）

8. NEXT_SESSION_TEMPLATE.mdをコピーしてNEXT_SESSION.mdを作成
9. MEMORY_GUIDE.mdに従ってAuto Memoryを設定
10. 最初のセッションを開始

### 毎セッションのフロー

```
セッション開始:
  Claude reads CLAUDE.md (自動)
  Claude reads MEMORY.md (自動)
  ユーザーがClaudeにNEXT_SESSION.mdを指示
  ClaudeがLESSONS.mdの関連項目を確認

セッション中:
  最大1〜2タスク
  実装前にテストケースを定義
  複雑な機能はplan modeで設計審問

セッション終了:
  PROGRESS.md更新
  CODE_STATUS.md更新
  LESSONS.md更新（新たな知見があれば）
  次のNEXT_SESSION.mdをテンプレートから作成
```

## 言語ポリシー

| 内容の種類 | 言語 | 理由 |
|-----------|------|------|
| セクション見出し・ルール文 | 日本語 | ポリシー文書に自然 |
| 核心原則・禁止事項 | 日本語 | 母語での強調 |
| 品質チェックリスト | 日本語 | 内部的な確認用 |
| 技術的記述・ファイルパス | 英語 | プログラミング用語 |
| プレースホルダー指示 | 英語 | `{placeholder}`形式は普遍的 |
| テンプレート内コメント | 英語 | `<!-- instructions -->`での記入指示 |

日本語が不要な場合は、全て英語に書き換えても問題ない。構造が価値の本体。

## このシステムが防ぐ問題

| 問題 | 防止メカニズム |
|------|-------------|
| スコープ肥大 | CLAUDE.md: 1-2タスク/セッション |
| AIの幻覚 | CLAUDE.md毎セッション再読 + MEMORY.mdのパターン言語 |
| フォーマット劣化 | NEXT_SESSION_TEMPLATE.mdの★必須セクション |
| 教訓の消失 | LESSONS.mdの番号付き教訓（引用可能） |
| 引き継ぎ不完全 | テンプレートの「セッション終了前タスク」チェックリスト |
| アーキテクチャ退行 | DEVELOPMENT_POLICY.mdの成功基準 + 失敗兆候 |
| 設計判断の忘却 | DEVELOPMENT_POLICY.mdに「なぜ」を記録 |
| コンテキスト枯渇 | Compact Instructions + サブエージェント活用 |
