# frozen_string_literal: true

module WechatThirdPartyPlatform
  class WechatController < ApplicationController
    InvalidMessageSignatureError = Class.new StandardError

    skip_before_action :verify_authenticity_token
    before_action :verify_message!, :set_app_id_params, only: :authorization_events

    LOGGER = ::Logger.new("./log/wechat_third_party_platform_event.log")

    def authorization_events
      LOGGER.debug("request: params: #{params.inspect}, msg_hash: #{msg_hash.inspect}")
      event_handler = "#{msg_hash["InfoType"]}_handler"
      # component_verify_ticket_handler、notify_third_fasteregister_handler
      # authorized_handler、unauthorized_handler、updateauthorized_handler
      send(event_handler) if respond_to?(event_handler, true)

      render plain: "success"
    end

    # 默认小程序授权之后redirect url
    def auth_callback
      @redirect_to = "original_page"
      if params[:auth_code] && params[:expires_in]
        project_application = WechatThirdPartyPlatform.project_application_class_name.constantize.find_by(id: params[:id])
        @message = "授权失败，找不到ID为#{params[:id]}的应用" and return unless project_application

        # 根据授权码获取小程序的授权信息
        resp = WechatThirdPartyPlatform.api_query_auth(authorization_code: params[:auth_code])
        auth_info = resp["authorization_info"]
        wechat_application = WechatThirdPartyPlatform::Application.find_or_create_by(appid: auth_info["authorizer_appid"])
        # 小程序重新授权，refresh_token可能有所更新，需将最新的refresh_token存下来
        wechat_application.update(
          access_token: auth_info["authorizer_access_token"],
          refresh_token: auth_info["authorizer_refresh_token"],
          func_info: auth_info["func_info"]
        )

        if wechat_application.id
          @message = "授权失败，当前应用已授权小程序，不可授权为其他小程序" and return if project_application.wechat_application && project_application.wechat_application_id != wechat_application.id
          @message = "授权失败，当前小程序已授权给其他应用" and return if wechat_application.project_application && wechat_application.project_application.id != project_application.id
        end

        project_application.update(wechat_application: wechat_application, name: (wechat_application.nick_name || project_application.name))

        @message = wechat_application.errors.full_messages.join(",") and return unless wechat_application.commit_latest_template

        WechatThirdPartyPlatform::BindingApplicationJob.perform_later(wechat_application)

        @message = "授权成功"
        @redirect_to = "home_page"
      else
        @message = "parameter error"
      end
    end

    def component_auth
      @auth_url = WechatThirdPartyPlatform.component_auth_url(application_id: WechatThirdPartyPlatform.project_application_class_name.constantize.first&.id)
    end

    def messages
      LOGGER.debug("request: params: #{params.inspect}, msg_hash: #{msg_hash.inspect}")

      event_handler = "#{msg_hash["Event"]}_handler"
      current_application.send(event_handler, msg_hash) if current_application.respond_to?(event_handler)

      render plain: "success"
    end

    protected

    def authorized_handler
      current_application&.authorized_handler(msg_hash)
    end

    def unauthorized_handler
      current_application&.unauthorized_handler(msg_hash)
    end

    def updateauthorized_handler
      current_application&.updateauthorized_handler(msg_hash)
    end

    # 快速注册小程序审核事件推送
    # <xml>
    #     <AppId><![CDATA[第三方平台appid]]></AppId>
    #     <CreateTime>1535442403</CreateTime>
    #     <InfoType><![CDATA[notify_third_fasteregister]]></InfoType>
    #     <appid>创建小程序appid<appid>
    #     <status>0</status>
    #     <auth_code>xxxxx第三方授权码</auth_code>
    #     <msg>OK</msg>
    #     <info>
    #     <name><![CDATA[企业名称]]></name>
    #     <code><![CDATA[企业代码]]></code>
    #     <code_type>1</code_type>
    #     <legal_persona_wechat><![CDATA[法人微信号]]></legal_persona_wechat>
    #     <legal_persona_name><![CDATA[法人姓名]]></legal_persona_name>
    #     <component_phone><![CDATA[第三方联系电话]]></component_phone>
    #     </info>
    # </xml>
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Fast_Registration_Interface_document.html
    def notify_third_fasteregister_handler
      Application.handle_notify_third_fasteregister(msg_hash: msg_hash)
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/component_verify_ticket.html
    # msg_hash为{"AppId"=>"wx6049dd9d0df6e593", "CreateTime"=>"1603094188", "InfoType"=>"component_verify_ticket", "ComponentVerifyTicket"=>"ticket@@@Hcp1sWsxoI7cuskY_boQJLDC6RPKc5PR7v7SzeHjwFv2CZAyEJCSOEAptlmRLuFmLMyEcYoMpcVPFr4w5jSn9Q"}
    def component_verify_ticket_handler
      wtpp_verify_ticket = msg_hash["ComponentVerifyTicket"]
      Rails.cache.write(WechatThirdPartyPlatform.wtpp_verify_ticket_cache_key, wtpp_verify_ticket, expires_in: 115.minutes)
    end

    def current_application
      @current_application ||= WechatThirdPartyPlatform::Application.find_by(appid: params[:appid])
    end

    def original_xml
      @original_xml ||= request.body.read
    end

    def msg_hash
      @msg_hash ||= Hash.from_xml(WechatThirdPartyPlatform::MessageEncryptor.decrypt_message(original_xml))["xml"]
    end

    def set_app_id_params
      params[:appid] = msg_hash["AuthorizerAppid"]
    end

    def verify_message!
      msg_encrypt = Hash.from_xml(original_xml)["xml"]["Encrypt"]
      raise InvalidMessageSignatureError unless Digest::SHA1.hexdigest([WechatThirdPartyPlatform.message_token, params[:timestamp], params[:nonce], msg_encrypt].sort.join).eql?(params[:msg_signature])
    end
  end
end
