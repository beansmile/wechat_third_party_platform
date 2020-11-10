# frozen_string_literal: true

module WechatThirdPartyPlatform
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def install
      route 'mount WechatThirdPartyPlatform::Engine => "/wtpp"'
    end

    def copy_initializer
      template "install_wechat_third_party_platform.rb", "config/initializers/wechat_third_party_platform.rb"
    end

    def configure_application
      application <<-CONFIG
      config.to_prepare do
        # Load application's model / class decorators
        Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end
      CONFIG
    end

    def copy_migration
      migration_template "migrations/create_wechat_third_party_platform_registers.rb.erb", "db/migrate/create_wechat_third_party_platform_registers.rb"
      migration_template "migrations/create_wechat_third_party_platform_applications.rb.erb", "db/migrate/create_wechat_third_party_platform_applications.rb"
      migration_template "migrations/create_wechat_third_party_platform_submitions.rb.erb", "db/migrate/create_wechat_third_party_platform_submitions.rb"
      migration_template "migrations/create_wechat_third_party_platform_testers.rb.erb", "db/migrate/create_wechat_third_party_platform_testers.rb"
      migration_template "migrations/create_wechat_third_party_platform_visit_data.rb.erb", "db/migrate/create_wechat_third_party_platform_visit_data.rb"
      migration_template "migrations/add_submition_reference_to_wechat_third_party_platform_applications.rb.erb", "db/migrate/add_submition_reference_to_wechat_third_party_platform_applications.rb"
    end

    def copy_decorators
      template "wechat_controller.rb", "app/decorators/controllers/wechat_third_party_platform/wechat_controller_decorator.rb"
    end

    private
    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end
  end
end
