# frozen_string_literal: true

require "logger"
require "yaml"

ActiveRecord::Base.configurations = YAML.load_file(File.expand_path("db/database.yml", __dir__))
db_config = ActiveRecord::Base.configurations.fetch(ENV["DB"] || "sqlite")

begin
  ActiveRecord::Base.establish_connection(db_config)
  ActiveRecord::Base.connection
rescue
  ActiveRecord::Base.establish_connection(db_config.merge("database" => nil))
  ActiveRecord::Base.connection.create_database(db_config["database"], db_config)
  ActiveRecord::Base.establish_connection(db_config)
end

ActiveRecord::Base.logger = Logger.new(File.join(__dir__, "debug.log"))
ActiveRecord::Base.logger.level = ENV["CI"] ? ::Logger::ERROR : ::Logger::DEBUG
ActiveRecord::Migration.verbose = false
