# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'production'

require 'rails'
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "sprockets/railtie"

require '../lib/elastic-apm' unless ENV.fetch('DISABLE_APM', false)

module Bench
  class Application < Rails::Application
    config.secret_key_base = '__secret_key_base'
    # config.consider_all_requests_local = false

    config.logger = Logger.new(ENV.fetch('DEBUG', false) ? STDOUT : nil)
    config.logger.level = Logger::DEBUG

    config.eager_load = false

    config.active_record.sqlite3.represent_boolean_as_integer = true

    # config.elastic_apm.flush_interval = nil
    # config.elastic_apm.debug_transactions = true
  end
end

class ApplicationController < ActionController::Base
end

class PagesController < ApplicationController
  def index
    @pages = Page.all
  end
end

class Page < ActiveRecord::Base
end

Bench::Application.initialize!
Bench::Application.routes.draw do
  root to: 'pages#index'
end

ActiveRecord::Base.connection.execute <<-SQL
create table if not exists pages (id integer primary key, title varchar(255), body text);
insert into pages (id, title, body) values (1, 'Hello', 'You');
SQL

