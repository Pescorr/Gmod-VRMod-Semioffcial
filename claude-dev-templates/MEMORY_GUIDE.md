<!-- Template v1.0 -->
# Claude Auto Memory 設定ガイド

> このファイルはプロジェクトにはコピーしない。
> Auto Memoryの設定方法と運用指針を説明する手引き。

## Auto Memoryとは

Claude Codeは以下のパスに永続的なメモリファイルを保持する:

```
~/.claude/projects/{project-path-hash}/memory/MEMORY.md
```

このファイルは:
- **毎セッション自動読込**される（CLAUDE.mdと同様）
- セッション間で失われない
- Claudeが自動的に更新を提案する
- 200行を超えると切り詰められるため、簡潔に保つ

## CLAUDE.mdとの役割分担

| 内容 | 置き場所 | 理由 |
|------|---------|------|
| 不変のルール・原則 | CLAUDE.md | プロジェクトの法律 |
| 禁止事項・コーディング規約 | CLAUDE.md | 毎セッション強制適用 |
| API固有の挙動・癖 | MEMORY.md | 開発中に発見、名前付きパターン |
| アーキテクチャ判断の要約 | MEMORY.md | CLAUDE.mdに入りきらない背景 |
| 頻出するワークアラウンド | MEMORY.md | コード例付きで記録 |
| プロジェクト構造の要約 | MEMORY.md | ファイル構成・ロード順序 |

**原則**: ルールはCLAUDE.md、パターンはMEMORY.md

## 推奨カテゴリ構造

新しいプロジェクトでMEMORY.mdを初期化する際の推奨構造:

```markdown
# {Project Name} Memory

## Key Architecture Decisions
<!-- "Big" choices that affect the entire project -->
- **{decision_name}**: {brief_description_and_why}

## {Language/Framework} Patterns
<!-- API quirks, idioms, gotchas discovered during development -->
- {pattern_name}: {description}
- {api_quirk}: {what_you_expected} vs {what_actually_happens}

## Project Structure
<!-- How files are organized, loading order, conventions -->
- {structural_fact_1}
- {structural_fact_2}

## Development Policy (never change)
<!-- Brief backup of CLAUDE.md core rules -->
- {immutable_rule_summary}
```

## 初期化方法

### 方法1: 自然な発見に任せる

開発を進める中で、Claudeがパターンを発見すると自動的にMEMORY.mdへの保存を提案する。
承認すれば記録される。最も自然な方法。

### 方法2: 事前にシードする

既知のパターンがある場合、開発開始前に手動で記入しておく:

1. Claude Codeを開く
2. 「MEMORY.mdに以下を記録して」と指示する:
   - 使用するフレームワークの既知の癖
   - 重要なアーキテクチャ決定
   - プロジェクト固有の構造情報

### 方法3: LESSONS.mdからの昇格

LESSONS.mdに記録された教訓のうち、**毎セッション意識すべきもの**はMEMORY.mdに昇格させる。

判断基準:
- LESSONS.md: 「こういうことがあった」（履歴）
- MEMORY.md: 「これは常に意識せよ」（習慣）

## アンチパターン

- CLAUDE.mdの内容をMEMORY.mdに重複させない（ドリフトの原因）
- セッション固有の状態を入れない（それはPROGRESS.mdの役割）
- テスト結果を入れない（それはPROGRESS.mdの役割）
- 200行を超えないよう定期的に整理する
- 未確認の推測を書かない（確認済みのパターンのみ）

## 実際の運用例

vrmod_semiofficial_reプロジェクトでの実例:

```markdown
## GLua Patterns
- `string.StartWith` (no 's' at end) is correct GLua API
- `file.Append` only works with `.txt` extension
- Defensive initialization: `vrmod.X = vrmod.X or {}`
- ConVar cache: avoid `GetConVar()` per frame, use local variables
```

このように、**名前付きパターン**として記録すると、AIが類似の場面で自動的に参照できる。
「防御的初期化パターン」「ConVarキャッシュパターン」など、名前を付けることが重要。
