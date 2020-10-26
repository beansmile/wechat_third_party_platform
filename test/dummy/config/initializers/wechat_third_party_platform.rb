# frozen_string_literal: true

host = Rails.application.credentials.dig(Rails.env.to_sym, :host)
config = Rails.application.credentials.dig(Rails.env.to_sym, :wechat_third_party_platform) || {}

WechatThirdPartyPlatform.auth_redirect_url = "#{host}/wtpp/wechat/auth_callback"
WechatThirdPartyPlatform.component_appid = config[:component_appid]
WechatThirdPartyPlatform.component_appsecret = config[:component_appsecret]
WechatThirdPartyPlatform.message_token = config[:message_token]
WechatThirdPartyPlatform.message_key = config[:message_key]
