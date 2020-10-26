# frozen_string_literal: true

module WechatThirdPartyPlatform
  class WechatController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :set_app_id_params, only: :authorization_events

    LOGGER = ::Logger.new("./log/wechat_third_party_platform_event.log")

    def authorization_events
      LOGGER.debug("request: params: #{params.inspect}, msg_hash: #{msg_hash.inspect}")
      event_handler = "#{msg_hash["InfoType"]}_handler"
      send(event_handler) if respond_to?(event_handler)

      render plain: "success"
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-授权成功
    def authorized_handler
      # do nothing
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-取消授权
    def unauthorized_handler
      # do nothing
    end

    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorize_event.html
    # 授权变更通知推送-取消授权
    def updateauthorized_handler
      # do nothing
    end

    def component_verify_ticket_handler
      # msg_hash为{"AppId"=>"wx6049dd9d0df6e593", "CreateTime"=>"1603094188", "InfoType"=>"component_verify_ticket", "ComponentVerifyTicket"=>"ticket@@@Hcp1sWsxoI7cuskY_boQJLDC6RPKc5PR7v7SzeHjwFv2CZAyEJCSOEAptlmRLuFmLMyEcYoMpcVPFr4w5jSn9Q"}
      wtpp_verify_ticket = msg_hash["ComponentVerifyTicket"]
      Rails.cache.write("wtpp_verify_ticket", wtpp_verify_ticket, expires_in: 115.minutes)
    end

    # 默认小程序授权之后redirect url
    def auth_callback
      if params[:auth_code] && params[:expires_in]
        # 根据授权码获取小程序的授权信息
        resp = WechatThirdPartyPlatform.api_query_auth(authorization_code: params[:auth_code])
        auth_info = resp["authorization_info"]
        application = WechatThirdPartyPlatform.application_class_name.constantize.find_or_create_by(appid: auth_info["authorizer_appid"])
        application.update(
          access_token: auth_info["authorizer_access_token"],
          refresh_token: auth_info["authorizer_refresh_token"],
          func_info: auth_info["func_info"]
        )
        render json: { status: 200, message: "auth success" }
      else
        render json: { status: 400, message: "parameter error" }
      end
    end

    def component_auth
      @auth_url = "https://mp.weixin.qq.com/cgi-bin/componentloginpage?component_appid=#{WechatThirdPartyPlatform.component_appid}&pre_auth_code=#{WechatThirdPartyPlatform.api_create_preauthcode}&redirect_uri=#{WechatThirdPartyPlatform.auth_redirect_url}&auth_type=2"
    end

    def messages
      LOGGER.debug("request: params: #{params.inspect}, msg_hash: #{msg_hash.inspect}")

      event_handler = "#{msg_hash["Event"]}_handler"
      send(event_handler) if respond_to?(event_handler)

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
      # do nothing
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
      # do nothing
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
      # do nothing
    end

    # 名称审核结果事件推送
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
    end

    def current_application
      @application ||= WechatThirdPartyPlatform.application_class_name.constantize.find_by(authorizer_appid: params[:appid])
    end

    def msg_hash
      @msg_hash ||= Hash.from_xml(WechatThirdPartyPlatform::MessageEncryptor.decrypt_message(request.body.read))["xml"]
    end

    def set_app_id_params
      params[:appid] = msg_hash["AuthorizerAppid"]
    end
  end
end
