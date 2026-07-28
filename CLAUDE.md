# CLAUDE.md

このリポジトリで作業する Claude Code 向けのガイド。

## 概要

シンボリックリンク方式の個人 dotfiles。ホスト(WSL/Linux)と devcontainer の両方をカバーし、
「共通で使うツール」と「ホスト専用のツール」を install スクリプトで分離している。

コメント・ドキュメントはすべて**日本語**で書く。既存ファイルのトーンに合わせること。

## アーキテクチャ

セットアップは 2 層のエントリポイントとモジュール単位の install から成る。

- `install-local.sh` (ホスト用フル) → `install-devcontainer.sh` を呼び、さらに `devc`・`zed` を追加。
- `install-devcontainer.sh` (共通) → `tmux`・`shell`・`claude`・`git` の install を順に呼ぶ。devcontainer 機能からも起動される。
- `<module>/install.sh` → `lib/common.sh` を source し、`link` 関数でシンボリックリンクを張る。

**devcontainer で使うツールか否か**が分離の基準。ホストでしか使わないもの(zed など)は
`install-local.sh` 側にだけ足す。共通で使うものは `install-devcontainer.sh` に足す。

### `link` ヘルパー (`lib/common.sh`)

全 install スクリプトが使う唯一の共通関数。`link <src> <dest>` で:

- 既存が実体(非シンボリックリンク)なら `.bak` へ退避してから張る。
- 既存がシンボリックリンクなら `ln -sfn` で上書き。
- src が無ければ skip して return 1。

### モジュール install の定型

各 `<module>/install.sh` は同じ前置きで始まる:

```sh
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
source "${DOTFILES_DIR}/lib/common.sh"
```

新しいモジュールを足すときはこの定型に倣い、`echo "<name>:"` でセクション見出しを出してから `link` する。

## 規約

- **配置先は XDG 準拠を優先**(`${XDG_CONFIG_HOME:-$HOME/.config}`)。互換のため伝統パス(`~/.tmux.conf` 等)にも張る場合がある。
- **マシン固有設定は雛形方式**。git 管理する設定ファイルには汎用値だけを置き、環境依存の値(`user.email`・credential・マシン固有 alias 等)は
  `*.example` からローカルファイルを生成して分離する。install スクリプトは既存のローカルファイルを**上書きしない**。
  - git: `git/config` が `~/.config/git/config.local` を `[include]`。
  - shell: `shell/aliases` が末尾で `~/.config/shell/aliases.local` を source。
- **ホスト専用のエイリアスは `devc/` のように別モジュールへ分ける**。`shell/aliases` は共通(devcontainer 内にもリンクされる)なので、
  ホストでしか動かない関数を直接書かない。`devc/install.sh` が `~/.config/shell/aliases.host` へリンクし、`shell/aliases` が
  `aliases.local` より前で source する。コンテナ内は `install-local.sh` を通らないので、このファイルが存在せず読み込まれない。
- **herdr 連携**: devcontainer 内のエージェントは、ホストから見ると `devcontainer exec` にしか見えず種別判定が外れる。
  `devc/aliases` の `devca`/`devcc` が `HERDR_AGENT` でヒントを与えて解決している。ヒントはホスト側のフォアグラウンド
  プロセスにしか効かないので、コンテナ内の設定で代替はできない。
  なお `claude/settings.json` の herdr フックは `herdr integration install claude` が直接書き換えにくる
  (`~/.claude/settings.json` がこのリポジトリへのシンボリックリンクのため)。絶対パスに戻されていないか差分で確認すること。
- **devcontainer への認証の渡し方**: `devcontainer` CLI は VS Code 拡張と違って認証を自動転送しないため、
  `devc/aliases` の `devcu` がホスト側の値を明示的に渡し、`git/install.sh` が受け取って設定する。
  - トークン(`GH_TOKEN`)は `--secrets-file`(一時ファイル)経由。`--remote-env` はホストの `ps` に見えるため使わない。
    CLI 内部で secrets は remoteEnv と合流して dotfiles install コマンドの env に入る(0.87.0 で確認)。
  - 受け取り側は `~/.config/git/config.auth`(毎回生成し直す)と `credentials`(600)を作る。ホストは `GH_TOKEN` が
    無いので何も生成されない = ホスト/コンテナで同じスクリプトが使える。
  - `config.auth` は `insteadOf` で ssh URL を HTTPS に書き換える。GitHub 以外はカバーしない。
  - `gh` は環境変数 `GH_TOKEN` を優先し、その状態では `gh auth login` が認証を保存できない。
    保存させるには `env -u GH_TOKEN -u GITHUB_TOKEN` を噛ませる(そうしないと install 後の対話シェルで gh が失認証になる)。
- **claude モジュール**: `claude/skills/<name>/` を足すだけで `~/.claude/skills/<name>` へ自動リンクされる(`install.sh` がループで拾う)。
- 環境は **WSL2 + Windows 版 Zed** を主に想定。zed スクリプトは zenity → PowerShell → CLI の順でダイアログをフォールバックする。
- **`zed/tasks.json` は install でリンクしない**。`scripts/*` はタスク実行時に WSL 側で走るため WSL へリンクするが、
  `tasks.json` は Zed のグローバル設定で Windows 版 Zed では実体が Windows 側(`%APPDATA%\Zed`)にあり、WSL 側に置いても読まれず
  `zed` CLI にも取り込み手段が無い。リポジトリの `tasks.json` は Windows 側へ手動反映するための参照として置いている。

## 動作確認

install スクリプトは冪等。変更後は再実行して確認する。

```sh
./install-local.sh          # ホスト用フル
bash claude/install.sh      # 個別モジュールだけ確認する場合
```

`set -euo pipefail` 前提。shell スクリプトは shellcheck の指示コメント(`# shellcheck ...`)を尊重すること。
