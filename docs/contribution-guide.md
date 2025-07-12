# コントリビューションガイド

Windowsユーザーを前提としています。

## 初期設定

### 1. WSL のインストール

まずは Windows Subsystem for Linux (WSL) をインストールします。

[Windows 11にWSL2をインストールする - Qiita](https://qiita.com/SAITO_Keita/items/148f794a5b358e5cb87b)を参考にWSLをインストールしてください。

### 2. 使用するソフトウェア・ライブラリのインストール

WSLをインストールした後、以下のコマンドで必要なツールやライブラリをインストールします。

```bash
sudo apt update
sudo apt install git ruby
sudo gem install rubyXL
```

### 3. WSLのマウントの設定

デフォルトの形式では権限などの問題でpaksetのビルドが上手く行かないため、WSLのマウントの設定を変更します。

```bash
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata
```

参考 : [WSL Ubuntu Distro | How to solve `Operation not permitted` on cloning repository - askUbuntu](https://askubuntu.com/questions/1115564/wsl-ubuntu-distro-how-to-solve-operation-not-permitted-on-cloning-repository)

### 4. libpng15.so.15 のインストール

以下のコマンドを実行して、libpng15.so.15をインストールします。1行ずつではなく、すべてのコマンドをコピーして一度に実行してください。

```bash
mkdir -p ~/libpng15-work && cd ~/libpng15-work && \
sudo apt install -y build-essential zlib1g-dev && \
wget https://download.sourceforge.net/libpng/libpng-1.5.30.tar.gz && \
tar -xzf libpng-1.5.30.tar.gz && \
cd libpng-1.5.30 && \
./configure --prefix=$HOME/libpng15-install && \
make -j$(nproc) && \
make install && \
sudo cp -r ~/libpng15-install/lib/* /usr/local/lib/ && \
sudo cp -r ~/libpng15-install/include/* /usr/local/include/ && \
sudo ln -sf /usr/local/lib/libpng15.so.15 /usr/lib/x86_64-linux-gnu/libpng15.so.15 && \
sudo ln -sf /usr/local/lib/libpng15.so /usr/lib/x86_64-linux-gnu/libpng15.so && \
sudo ldconfig
```

インストールが成功したか確認するには、次のコマンドを実行してください。何行か表示されれば成功です。

```bash
ldconfig -p | grep libpng15
```

### 5. GitHub CLI のインストールと設定

GitHub CLI(ghコマンド)をインストールし、公開鍵認証を設定します。

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
```

次に、GitHubにログインします。コマンドを実行した後の流れは、[俺たちはもう GitHub のために ssh-keygen しなくていい - Zenn](https://zenn.dev/lovegraph/articles/529fe37caa3f19)を参考に操作を進めてください。

```bash
gh auth login
```

GitHub CLIを使いたくない場合は、[新しい SSH キーを生成して ssh-agent に追加する - GitHub](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)を参考にSSHキーを生成し、GitHubに登録してください。

### 6. リポジトリのクローン

次はリポジトリをクローンします。

まず、作業するフォルダに移動します。パスを入力するときにはTABキーを2回押すことで、いい感じに補完されます。

```bash
# Windows側のデスクトップで作業する場合(おすすめ)
cd /mnt/c/Users/<あなたのWindows側のユーザー名>/Desktop # 或いは他の適切な場所

# WSL側のホームディレクトリで作業する場合
cd ~
```

リポジトリをクローンします。

```bash
git clone git@github.com:soukouki/simutrans-pak128.japan-ex.git
```

### 7. リポジトリのフォーク

GitHub上でリポジトリをフォークします。以下のURLにアクセスし、右上の「Fork」ボタンをクリックしてください。フォーク後、画面を更新するとあなたのアカウントの下にリポジトリが作成されたことを確認できます。

http://github.com/soukouki/simutrans-pak128.japan-ex

### 8. リモートリポジトリを登録

先程のフォークしたリポジトリの画面を開き、右上の「Code」ボタンをクリックして、SSHと書いてある箇所をクリックし、URLをコピーします。

次に、WSLのターミナルに戻り、以下のコマンドを実行してリモートリポジトリを登録します。

```bash
cd ~/simutrans-pak128.japan-ex
git remote add fork <先程コピーしたURL>
```

### 9. Gitの設定

以下のコマンドを実行して、Gitのユーザー名とメールアドレスを設定します。これは全世界に公開されるため、公開しても良い名前とメールアドレスを設定してください。もしスパムが嫌な場合は、GitHubが提供しているno-replyメールアドレスを使用することもできます。

```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### 10. 作業フォルダへのショートカットを作成(オプション)

毎回このフォルダに移動するのは面倒なので、WSL側のホームディレクトリにショートカットを作成します。

```bash
ln -s . ~/jpex
```

これで初期設定は完了です。お疲れ様でした！

## 開発の流れ

### 1. リポジトリの更新

作業を始める前に、リポジトリを最新の状態に更新します。以下のコマンドを実行してください。

```bash
git switch main
git pull
```

### 2. 開発用ブランチの作成

作業のために、新しいブランチを作成します。以下のコマンドを実行してください。

```bash
git switch -c <ブランチ名>
```

ブランチ名は、作業内容に応じて適切な名前を付けてください。日本語や空白などは避けてください。特に命名規則などはありません。ぶっちゃけ他のブランチ名と被らなければ何でもOKです。(例: `sou7-update-vehicle-1`, `sou7-123`, `w9ioamcouma`など)。

なお、すでに開発用ブランチが存在していて、そこに移動する場合は代わりに以下のコマンドを実行してください。

```bash
git switch <ブランチ名>
```

### 3. 作業をする

ファイルを編集して、必要な変更を行います。UTF-8(BOMなし)で保存してください。エディタは好きなものを使って良いですが、UTF-8(BOMなし)で保存できるエディタを使ってください。おすすめはVSCodeです。

elsxファイルを編集する場合は、ExcelかLibreOfficeを使ってください。

ビルドを行うには、以下のコマンドを実行します。これらはどのファイルに変更があったのかを検出し、必要なファイルのみを更新します。なので2回目以降のビルドはかなり速くなります。
'
```bash
ruby scripts/make.rb all
```

なにか問題があり、一旦ファイルを全部消してビルドし直したい場合は、以下のコマンドを実行します。

```bash
# 削除のみ
ruby scripts/make.rb clean
# 削除とビルドの両方
ruby scripts/make.rb clean all
```

なお、cleanコマンドは対応するdattファイルがないdatファイルは削除しないようになっています(誤って作業中のdatファイルを消してしまうのを防ぐため)。もし、本当にすべてのdatファイルを削除したい場合は、以下のコマンドを実行してください。

```bash
rm **/*.dat
```

### 4. 変更のコミット

作業が完了したら、変更をコミットします。まず、どのファイルが変更されたかを確認します。

```bash
git status
```

ここで、赤く表示されているファイルが変更されたファイルです。これらの変更を取り込みましょう。

```bash
git add <変更したファイル>
```

このときに、変更した覚えのないファイルが表示されることがあります。エディタなどの設定によって改行コードが変わったり、文字コードが変更されたり、パーミッションが変更されたりしたためです。このようなファイルは`git add`しないようにしましょう。

次に、コミットを行います。以下のコマンドを実行してください。

```bash
git commit -m "<コミットメッセージ>"
```

コミットメッセージは、変更内容を簡潔に説明するものを記述してください。今回はあまり厳密に行っていないので、割と雑に書いても大丈夫です。

### 5. リモートリポジトリへのプッシュ

変更をリモートリポジトリにプッシュします。以下のコマンドを実行してください。

```bash
git push fork -u <現在居るブランチ名>
```

### 6. プルリクエストの作成

https://github.com/soukouki/simutrans-pak128.japan-ex にアクセスし、黄色い枠の「Compare & pull request」ボタンをクリックします。

そうするとプルリクエストを作成する画面が表示されるので、タイトルと説明を入力します。タイトルは変更内容を簡潔に説明するものにしてください。説明については省略しても大丈夫です。もし変更内容をレビューしてほしい場合は、説明の部分も簡単に書いてもらえると助かります。

最後に変更内容を確認し、変な変更(例えば、意図しないファイルが混ざっていたり、変更した記憶のないファイルが混ざっていたり)が無いことを確認したら、右下の「Create pull request」ボタンをクリックします。

これでプルリクエストが作成されました。

変更の内容に自信がなくレビューをしてほしい場合は、その旨をsou7にDiscordで連絡してください。プルリクエストのURLを送ってください。

### 7. (オプション)プルリクエストのマージ

メンバーにはプルリクエストをマージする権限を付与しています(付与されてなければsou7へ連絡してください)。手元でしっかり動作確認できていて、レビューの必要がない場合はそのままプルリクエストをマージしても大丈夫です。

このリポジトリにはCI(継続的インテグレーション)の設定がされており、プルリクエストが作成されると自動でテストが行われます。数十秒ほど待つとテストが終わり、成功すればプルリクエストがマージ出来るようになります。

「Merge pull request」ボタンをクリックし、マージの確認画面が表示されたら「Confirm merge」ボタンをクリックします。これでプルリクエストがマージされました。

プルリクエストがマージされると、自動でn方式バージョンが発行され、自動でリリースまで行います。将来テストプレイサーバーを立てたら、自動でサーバーのpaksetも更新されるようにする予定です。つまり、マージをしたら自動でテストプレイサーバーに反映されるようになります。エラーが起きないように気をつけましょう。

## Tips

### 作業毎にブランチを分ける

1つのブランチでは、あまりたくさんの種類の変更を行わないようにしましょう。例えば、国鉄の車両をいじって、私鉄の車両をいじって、建物をいじって、道路をいじって...というように、いろんな種類の変更を1つのブランチで行うのは避けましょう。この後のプルリクエスト・マージの際に、コンフリクトという面倒な問題が発生しやすくなります。

とはいえ、あまり細かくブランチを分けすぎても、その分の作業が増えてしまいます。ほどほどの粒度で分けましょう。例えば、国鉄の車両をいじる、私鉄の車両をいじる、建物をいじる、道路をいじる...というように、1つの種類の変更ごとにブランチを分けるのが良いでしょう。
