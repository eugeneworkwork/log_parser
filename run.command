cd -- "$(dirname "$0")"
gem install bundler
bundle install --local
bundle exec ruby main.rb