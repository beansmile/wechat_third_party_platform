module WechatThirdPartyPlatform
  class Engine < ::Rails::Engine
    isolate_namespace WechatThirdPartyPlatform


    initializer "wechat_third_party_platform.assets.precompile" do |app|
      app.config.assets.precompile += %w( wechat_third_party_platform/application.css )
    end
  end
end
