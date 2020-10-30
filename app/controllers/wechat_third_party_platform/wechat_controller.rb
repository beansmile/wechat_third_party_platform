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
      send(event_handler) if respond_to?(event_handler)

      render plain: "success"
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-授权成功
    # <xml>
    #   <AppId>第三方平台appid</AppId>
    #   <CreateTime>1413192760</CreateTime>
    #   <InfoType>authorized</InfoType>
    #   <AuthorizerAppid>公众号appid</AuthorizerAppid>
    #   <AuthorizationCode>授权码</AuthorizationCode>
    #   <AuthorizationCodeExpiredTime>过期时间</AuthorizationCodeExpiredTime>
    #   <PreAuthCode>预授权码</PreAuthCode>
    # <xml>
    def authorized_handler
      if current_application.authorizer_authorized!
        WechatThirdPartyPlatform.cache_pre_auth_code(msg_hash["PreAuthCode"])
      end
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-取消授权
    # <xml>
    #   <AppId>第三方平台appid</AppId>
    #   <CreateTime>1413192760</CreateTime>
    #   <InfoType>unauthorized</InfoType>
    #   <AuthorizerAppid>公众号appid</AuthorizerAppid>
    # </xml>
    def unauthorized_handler
      current_application.authorizer_unauthorized!
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-取消授权
    # <xml>
    #   <AppId>第三方平台appid</AppId>
    #   <CreateTime>1413192760</CreateTime>
    #   <InfoType>updateauthorized</InfoType>
    #   <AuthorizerAppid>公众号appid</AuthorizerAppid>
    #   <AuthorizationCode>授权码</AuthorizationCode>
    #   <AuthorizationCodeExpiredTime>过期时间</AuthorizationCodeExpiredTime>
    #   <PreAuthCode>预授权码</PreAuthCode>
    # <xml>
    def updateauthorized_handler
      if current_application.authorizer_updateauthorized!
        WechatThirdPartyPlatform.cache_pre_auth_code(msg_hash["PreAuthCode"])
      end
    end

    def component_verify_ticket_handler
      # msg_hash为{"AppId"=>"wx6049dd9d0df6e593", "CreateTime"=>"1603094188", "InfoType"=>"component_verify_ticket", "ComponentVerifyTicket"=>"ticket@@@Hcp1sWsxoI7cuskY_boQJLDC6RPKc5PR7v7SzeHjwFv2CZAyEJCSOEAptlmRLuFmLMyEcYoMpcVPFr4w5jSn9Q"}
      wtpp_verify_ticket = msg_hash["ComponentVerifyTicket"]
      Rails.cache.write("wtpp_verify_ticket", wtpp_verify_ticket, expires_in: 115.minutes)
    end

    # 默认小程序授权之后redirect url
    def auth_callback
      if params[:auth_code] && params[:expires_in]
        project_application = WechatThirdPartyPlatform.project_application_class_name.constantize.find_by(id: params[:id])
        render json: { status: 400, message: "授权失败，找不到ID为#{params[:id]}的应用" } and return unless project_application

        # 根据授权码获取小程序的授权信息
        resp = WechatThirdPartyPlatform.api_query_auth(authorization_code: params[:auth_code])
        auth_info = resp["authorization_info"]
        wechat_application = WechatThirdPartyPlatform::Application.find_or_create_by(appid: auth_info["authorizer_appid"])
        if wechat_application.id
          render json: { status: 400, message: "授权失败，当前应用已授权小程序，不可授权为其他小程序" } and return if project_application.wechat_application && project_application.wechat_application.id != wechat_application.id
          render json: { status: 400, message: "授权失败，当前小程序已授权给其他应用" } and return if wechat_application.project_application && wechat_application.project_application.id != project_application.id
        end

        project_application.update(wechat_application: wechat_application, name: (wechat_application.nick_name || project_application.name))
        wechat_application.update(
          access_token: auth_info["authorizer_access_token"],
          refresh_token: auth_info["authorizer_refresh_token"],
          func_info: auth_info["func_info"]
        )

        render json: { status: 400, message: wechat_application.errors.full_messages.join(",") } and return unless wechat_application.commit_latest_template

        render json: { status: 200, message: "授权成功" }
      else
        render json: { status: 400, message: "parameter error" }
      end
    end

    def component_auth
      @auth_url = WechatThirdPartyPlatform.component_auth_url(application_id: WechatThirdPartyPlatform.project_application_class_name.constantize.first&.id)
    end

    def messages
      LOGGER.debug("request: params: #{params.inspect}, msg_hash: #{msg_hash.inspect}")

      event_handler = "#{msg_hash["Event"]}_handler"
      send(event_handler) if respond_to?(event_handler, true)

      render plain: "success"
    end

    protected
    # 代码审核结果推送 - 审核通过
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/audit_event.html
    # <xml>
    #   <ToUserName><![CDATA[gh_fb9688c2a4b2]]></ToUserName>
    #   <FromUserName><![CDATA[od1P50M-fNQI5Gcq-trm4a7apsU8]]></FromUserName>
    #   <CreateTime>1488856741</CreateTime>
    #   <MsgType><![CDATA[event]]></MsgType>
    #   <Event><![CDATA[weapp_audit_success]]></Event>
    #   <SuccTime>1488856741</SuccTime>
    # </xml>
    def weapp_audit_success_handler
      current_application.handle_weapp_audit_success(msg_hash: msg_hash)
    end

    # 代码审核结果推送 - 审核不通过
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/audit_event.html
    # <xml>
    #   <ToUserName><![CDATA[gh_fb9688c2a4b2]]></ToUserName>
    #   <FromUserName><![CDATA[od1P50M-fNQI5Gcq-trm4a7apsU8]]></FromUserName>
    #   <CreateTime>1488856591</CreateTime>
    #   <MsgType><![CDATA[event]]></MsgType>
    #   <Event><![CDATA[weapp_audit_fail]]></Event>
    #   <Reason><![CDATA[1:账号信息不符合规范:<br>(1):包含色情因素<br>2:服务类目"金融业-保险_"与你提交代码审核时设置的功能页面内容不一致:<br>(1):功能页面设置的部分标签不属于所选的服务类目范围。<br>(2):功能页面设置的部分标签与该页面内容不相关。<br>]]></Reason>
    #   <FailTime>1488856591</FailTime>
    #   <ScreenShot>xxx|yyy|zzz</ScreenShot>
    # </xml>
    def weapp_audit_fail_handler
      return unless audit_submition = current_application.audit_submition
      return unless audit_submition.pending? || audit_submition.delay?

      audit_submition.update(audit_result: msg_hash, state: :fail)
    end

    # 代码审核结果推送 - 审核延后
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/audit_event.html
    #
    # <xml>
    #   <ToUserName><![CDATA[gh_fb9688c2a4b2]]></ToUserName>
    #   <FromUserName><![CDATA[od1P50M-fNQI5Gcq-trm4a7apsU8]]></FromUserName>
    #   <CreateTime>1488856591</CreateTime>
    #   <MsgType><![CDATA[event]]></MsgType>
    #   <Event><![CDATA[weapp_audit_delay]]></Event>
    #   <Reason><![CDATA[为了更好的服务小程序，您的服务商正在进行提审系统的优化，可能会导致审核时效的增长，请耐心等待]]></Reason>
    #   <DelayTime>1488856591</DelayTime>
    # </xml>
    def weapp_audit_delay_handler
      return unless audit_submition = current_application.audit_submition
      return unless audit_submition.pending? || audit_submition.delay?

      audit_submition.update(audit_result: msg_hash, state: :delay)
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/wxa_nickname_audit.html
    # <xml>
    #   <ToUserName><![CDATA[gh_fxxxxxxxa4b2]]></ToUserName>
    #   <FromUserName><![CDATA[odxxxxM-xxxxxxxx-trm4a7apsU8]]></FromUserName>
    #   <CreateTime>1488800000</CreateTime>
    #   <MsgType><![CDATA[event]]></MsgType>
    #   <Event><![CDATA[wxa_nickname_audit]]></Event>
    #   <ret>2</ret>
    #   <nickname>昵称</nickname>
    #   <reason>驳回原因</reason>
    # </xml>
    def wxa_nickname_audit_handler
      return if current_application.blank? || !current_application.name_submitting?

      # 审核结果 2：失败，3：成功
      msg_hash["ret"] == 3 ? current_application.name_to_effective! : current_application.reject_name_changed!(msg_hash["reason"])
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
    def notify_third_fasteregister_handler
      Application.handle_notify_third_fasteregister(msg_hash: msg_hash)
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
