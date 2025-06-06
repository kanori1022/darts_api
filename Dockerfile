FROM ruby:3.4.4

# 作業ディレクトリの設定
RUN mkdir /api
WORKDIR /api

# Gemfileのコピー
COPY Gemfile /api/Gemfile
COPY Gemfile.lock /api/Gemfile.lock

# Bundlerのインストール
RUN gem install bundler

# 依存関係のインストール
RUN bundle install

# プロジェクトのコピー
COPY . /api

# ポート番号の設定
EXPOSE 8000

# コンテナ起動時に実行されるコマンド
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "8000"]

# https://zenn.dev/tmasuyama1114/articles/b2bb8bc141dcbd
# 1. gem install bundler
# 2. bundle init
# 3. Gemfileの書き換えrails8.0以上
# 4. bundle install --path=.bundle
# 5. bundle exec rails -v
# 6. rails new . --api --skip-docker --skip-keeps --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-job --skip-action-cable --skip-asset-pipeline --skip-javascript --skip-hotwire --skip-test --skip-system-test --skip-thruster --skip-brakeman --skip-kamal --skip-solid

# https://railsguides.jp/command_line.html