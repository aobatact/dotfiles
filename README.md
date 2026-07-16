# dotfiles

個人用の dotfiles。ホスト(WSL/Linux)と devcontainer の両方で使えるように、
共通で使うツールとホスト専用のツールを分けて管理している。

シンボリックリンク方式で、各ツールの設定ファイルを `~/` や `~/.config/` 配下へリンクする。

## セットアップ

### ホスト(ローカル)

フルセットアップ。共通ツールに加えて、ホストでしか使わないツール(git / zed)も設定する。

```sh
git clone https://github.com/aobatact/dotfiles.git ~/works/dotfiles
cd ~/works/dotfiles
./install-local.sh
```

### devcontainer

devcontainer の [dotfiles 機能](https://containers.dev/implementors/features/#dotfiles)から
`install-devcontainer.sh` を実行させる。tmux / shell / claude だけをセットアップする。

`shell/aliases` の `devcu` 関数を使うと、この dotfiles を渡した状態で devcontainer を起動できる。

```sh
devcu   # = devcontainer up --dotfiles-repository ... --dotfiles-install-command install-devcontainer.sh
```

## 構成

| ディレクトリ | 内容 | リンク先 |
| --- | --- | --- |
| `shell/` | 共有エイリアス・devcontainer ヘルパー関数 | `~/.bash_aliases` |
| `tmux/` | tmux 設定 | `~/.config/tmux/tmux.conf`, `~/.tmux.conf` |
| `claude/` | Claude Code の全体設定と skills | `~/.claude/settings.json`, `~/.claude/skills/*` |
| `git/` | git 設定・グローバル gitignore(ホスト専用) | `~/.config/git/{config,ignore}` |
| `zed/` | Zed 用の git 操作スクリプト(ホスト専用) | `~/.config/zed/scripts` |
| `lib/` | 各 install スクリプトが source する共通ヘルパー | — |

### エントリポイント

- `install-local.sh` — ホスト用フルセットアップ。`install-devcontainer.sh` + git + zed。
- `install-devcontainer.sh` — 共通エントリ。tmux / shell / claude をセットアップ。devcontainer からも実行される。
- `<module>/install.sh` — 各モジュールのセットアップ。`lib/common.sh` の `link` を使ってリンクを張る。

## マシン固有設定

git 管理に含めたくないマシン固有の設定は、雛形(`*.example`)からローカルファイルを生成して扱う。
初回セットアップ時に生成され、既存ファイルは上書きしない。

| ローカルファイル | 雛形 | 用途 |
| --- | --- | --- |
| `~/.config/git/config.local` | `git/config.local.example` | `user.email` / credential / `safe.directory` など |
| `~/.config/shell/aliases.local` | `shell/aliases.local.example` | マシン固有のエイリアス |

`git/config` は末尾で `config.local` を `[include]` し、`shell/aliases` は末尾で `aliases.local` を source する。

## Zed のタスク定義について

`zed/tasks.json` はリポジトリに含めているが install ではリンクしない。

`scripts/*` はタスク実行時にプロジェクト(WSL)側のシェルで走るため WSL 側へリンクするが、
`tasks.json` は Zed の**グローバル設定**で、Windows 版 Zed では実体が Windows 側(`%APPDATA%\Zed\tasks.json`)に
置かれる。WSL 側の `~/.config/zed/` に置いても読まれず、`zed` CLI にも取り込むコマンドが無い。
そのため `zed/tasks.json` は Windows 側へ手動で反映するための参照/雛形として置いている。

## リンクの挙動

`lib/common.sh` の `link` 関数がリンクを張る:

- 既存が**実ファイル/実ディレクトリ**なら `.bak` へ退避してから張り直す。
- 既存がシンボリックリンクなら `ln -sfn` で安全に上書きする。
- リンク元が存在しなければ skip する。
