# dotfiles

個人用の dotfiles。ホスト(WSL/Linux)と devcontainer の両方で使えるように、
共通で使うツールとホスト専用のツールを分けて管理している。

シンボリックリンク方式で、各ツールの設定ファイルを `~/` や `~/.config/` 配下へリンクする。

## セットアップ

### ホスト(ローカル)

フルセットアップ。共通ツールに加えて、ホストでしか使わないツール(devc / zed)も設定する。

```sh
git clone https://github.com/aobatact/dotfiles.git ~/works/dotfiles
cd ~/works/dotfiles
./install-local.sh
```

### devcontainer

devcontainer の [dotfiles 機能](https://containers.dev/implementors/features/#dotfiles)から
`install-devcontainer.sh` を実行させる。tmux / shell / claude / git をセットアップする。

`devc/aliases` の `devcu` 関数を使うと、この dotfiles と git の認証情報を渡した状態で devcontainer を起動できる。

```sh
devcu   # = devcontainer up --dotfiles-repository ... --dotfiles-install-command install-devcontainer.sh
```

### devcontainer 内のエージェントを herdr に検知させる

[herdr](https://herdr.dev) はペインのフォアグラウンドプロセスからエージェント種別を判定するが、
devcontainer 越しだと `devcontainer exec` しか見えず Claude Code だと分からない。
`devca` / `devcc` は `HERDR_AGENT` でヒントを与えてから `devcontainer exec` するので、
既存の画面判定ルールが適用され idle / working / blocked が表示されるようになる。

```sh
devcc          # = HERDR_AGENT=claude devcontainer exec claude
devcf          # = HERDR_AGENT=codex devcontainer exec codex-fugu
devca codex    # 他のエージェントはこちら
```

ヒントに渡せるのは herdr の manifest にある agent id だけで、未知の値だと `unknown_agent` に落ちて画面判定が丸ごと効かなくなる。
`codex-fugu` のようにコマンド名と id が食い違うラッパーは、`devca` 内の `case` で id へ読み替えている。

ヒントは**ホスト側**のフォアグラウンドプロセスにしか効かない(コンテナ内で設定しても herdr からは見えない)。
判定結果は `herdr agent explain <pane>` で確認できる。

セッション復元まで欲しい場合は herdr のソケットを bind mount してコンテナ内にも herdr を入れる必要があるが、
得られるのが復元だけなので現状は対応していない。

## devcontainer 内での git 認証

VS Code の Dev Containers 拡張と違い、`devcontainer` CLI は認証情報を自動転送しない。
そのため `devcu` がホスト側の値を渡し、コンテナ内の `git/install.sh` が受け取って設定する。

| 渡すもの | 渡し方 | 受け取り側の処理 |
| --- | --- | --- |
| `GH_TOKEN` (`gh auth token` の値) | `--secrets-file`(一時ファイル・600) | `config.auth` を生成し、トークンは credential cache(メモリ)へ登録 |
| `GIT_USER_EMAIL` (ホストの `user.email`) | `--remote-env` | `config.local` を生成する際に `user.email` として書く |

- トークンは**コマンドライン引数に出さない**ため `--secrets-file` を使う(`--remote-env` だとホストの `ps` に見える)。
- **トークンをディスクに書かない**。`credential.helper cache` に `git credential approve` で流し込むので、
  トークンは cache デーモンのメモリ上にだけ存在する。デーモンは別セッション(`devce` や tmux)からも
  同じソケット経由で引ける。保持時間は既定 12 時間(`GIT_CRED_TIMEOUT` 秒で変更可)。
- `config.auth` は ssh 形式の URL(`git@github.com:...`)を HTTPS へ書き換える `insteadOf` も設定するので、
  ssh リモートのままのリポジトリでもトークン認証で通る。**GitHub 以外(GitLab 等)はカバーしない。**
- cache が切れた / トークンを入れ替えた場合は、コンテナを作り直さずに `devcauth` で入れ直せる。

```sh
devcauth --workspace-folder .   # コンテナ内で git/install.sh を再実行してトークンを入れ直す
```

### コンテナ内の `gh`

`shell/aliases` が `gh` をラップし、呼び出しのたびに credential cache からトークンを取り出して
`GH_TOKEN` として渡す。ラッパーはコンテナ側(`config.auth` がある環境)でだけ定義されるので、
ホストのログイン済み `gh` には影響しない。

`~/.config/gh/hosts.yml` に永続化したい場合(= トークンが平文でディスクに残る)だけ、
ホスト側で `DOTFILES_GH_LOGIN=1` を設定して `devcu` する。

補足: dotfiles のインストールは `postCreateCommand` の**後**に走るため、`postCreateCommand` 内の
git 操作にはまだ認証が効かない。

## 構成

| ディレクトリ | 内容 | リンク先 |
| --- | --- | --- |
| `shell/` | 共有エイリアス | `~/.bash_aliases` |
| `tmux/` | tmux 設定 | `~/.config/tmux/tmux.conf`, `~/.tmux.conf` |
| `claude/` | Claude Code の全体設定・ステータス行・skills | `~/.claude/{settings.json,statusline.sh}`, `~/.claude/skills/*` |
| `devc/` | devcontainer ヘルパー関数(ホスト専用) | `~/.config/shell/aliases.host` |
| `git/` | git 設定・グローバル gitignore・devcontainer 向け認証設定 | `~/.config/git/{config,ignore}` |
| `zed/` | Zed 用の git 操作スクリプト(ホスト専用) | `~/.config/zed/scripts` |
| `lib/` | 各 install スクリプトが source する共通ヘルパー | — |

### エントリポイント

- `install-local.sh` — ホスト用フルセットアップ。`install-devcontainer.sh` + devc + zed。
- `install-devcontainer.sh` — 共通エントリ。tmux / shell / claude / git をセットアップ。devcontainer からも実行される。
- `<module>/install.sh` — 各モジュールのセットアップ。`lib/common.sh` の `link` を使ってリンクを張る。

## マシン固有設定

git 管理に含めたくないマシン固有の設定は、雛形(`*.example`)からローカルファイルを生成して扱う。
初回セットアップ時に生成され、既存ファイルは上書きしない。

| ローカルファイル | 雛形 | 用途 |
| --- | --- | --- |
| `~/.config/git/config.local` | `git/config.local.example` | `user.email` / credential / `safe.directory` など |
| `~/.config/shell/aliases.local` | `shell/aliases.local.example` | マシン固有のエイリアス |

`git/config` は末尾で `config.local` を `[include]` し、`shell/aliases` は末尾で `aliases.local` を source する。

なお `shell/aliases` は `aliases.local` の前に `~/.config/shell/aliases.host`(`devc/aliases` へのリンク)も source する。
これは雛形方式ではなくホスト専用モジュールの分離で、devcontainer 内では `install-local.sh` を通らないので存在せず読み込まれない。

`~/.config/git/config.auth` も `git/config` から `[include]` されるが、こちらは雛形ではなく
`GH_TOKEN` から**毎回生成し直す**(devcontainer 内のみ。無ければ include は黙って無視される)。

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

### ホストと共有されたディレクトリは触らない

devcontainer.json がホストの `~/.claude` や `~/.config/git` をコンテナへ bind mount していると、
コンテナ内でリンクを張り直した結果(コンテナ内の絶対パスを指すリンク)がホスト側に書き戻され、
**ホストの設定が壊れる**。そのため `claude` / `git` の install は、配置先がマウントポイントなら
何もせずに skip する(`lib/common.sh` の `is_mounted`)。

```
claude:
  [skip] /home/devcontainer/.claude はマウント済み(ホストと共有)のためリンクしない
```

この場合、コンテナ内の設定はマウントされたホスト側のディレクトリをそのまま使う。ただし**ファイル単位ではそうならないことがある**(次節)。

## devcontainer 内の Claude Code のステータス行

`~/.claude` をマウントするコンテナでは、このリポジトリの `claude/settings.json` は**何をしても効かない**。

- `~/.claude/settings.json` はホスト側で張ったシンボリックリンクで、リンク先(ホストの絶対パス)が
  コンテナ内に存在しないため壊れている。
- さらに devcontainer.json がプロジェクトの設定ファイルを `~/.claude/settings.json` へ重ねてマウントしている場合、
  docker が**そのシンボリックリンクを解決してリンク先のパスの上にマウントする**。結果、コンテナ内では
  `/home/<ホストユーザー>/works/dotfiles/claude/settings.json` という(コンテナには本来無い)パスが生え、
  中身がプロジェクトの設定に置き換わる。

そこで `claude/install.sh` は、マウント検出で skip するときに `statusLine` **だけ**を設定階層の最上位へ置く:

```
/etc/claude-code/managed-settings.d/50-dotfiles-statusline.json
```

Claude Code の設定は `userSettings < projectSettings < localSettings < flagSettings < policySettings` の順に
マージされ、`managed-settings.d/*.json` はファイル名の昇順でディープマージされる。1 キーしか置かないので
他の管理者設定とは衝突しない。sudo が使えない環境ではメッセージを出して skip する。

副作用として、コンテナ内の Claude Code は「管理者設定あり」の状態になる。

### ステータス行の中身

表示は `claude/statusline.sh` が組み立てる(`<モデル名> | Context: <n>% used | 5h: <n>%`)。
devcontainer には `jq` が入っていないことがあるため、`grep`/`sed` だけで解析している。
ホストでは `~/.claude/statusline.sh` へリンクされ、`settings.json` の `statusLine` から呼ばれる。
