# frozen_string_literal: true

require "rails/generators/migration"

module ActsAsVotable
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Generates migration for votable (votes table)"

    def self.orm
      Rails::Generators.options[:rails][:orm]
    end

    def self.source_root
      File.join(File.dirname(__FILE__), "templates", (orm.to_s unless orm.class.eql?(String)))
    end

    def self.orm_has_migration?
      [:active_record].include? orm
    end

    def self.next_migration_number(_path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def create_migration_file
      if self.class.orm_has_migration?
        migration_template "migration.erb", "db/migrate/acts_as_votable_migration.rb", migration_version: migration_version
      end
    end


    private

    def migration_version
      if rails5?
        "[4.2]"
      elsif rails6?
        "[6.0]"
      elsif rails7?
        "[7.0]"
      end
    end

    def rails5?
      Rails.version.start_with? "5"
    end

    def rails6?
      Rails.version.start_with? "6"
    end

    def rails7?
      Rails.version.start_with? "7"
    end
  end
end
