source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

gem "bootsnap", require: false
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem 'rack-cors', '~> 2.0', '>= 2.0.1'
gem "rails", "~> 7.0.4", ">= 7.0.4.3"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem 'whenever', '~> 1.0'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'dotenv-rails', '~> 2.8', '>= 2.8.1'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'rspec-rails', '~> 6.0', '>= 6.0.1'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem 'shoulda-matchers', '~> 5.3'
end
