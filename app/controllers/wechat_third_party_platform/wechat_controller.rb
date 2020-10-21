module WechatThirdPartyPlatform
  class WechatController < ApplicationController
    skip_before_action :verify_authenticity_token

    def authorization_events
      message = WechatThirdPartyPlatform::MessageEncryptor.decrypt_message(request.body.read)
      # {"xml"=>{"AppId"=>"wx6049dd9d0df6e593", "CreateTime"=>"1603094188", "InfoType"=>"component_verify_ticket", "ComponentVerifyTicket"=>"ticket@@@Hcp1sWsxoI7cuskY_boQJLDC6RPKc5PR7v7SzeHjwFv2CZAyEJCSOEAptlmRLuFmLMyEcYoMpcVPFr4w5jSn9Q"}}
      msg_hash = Hash.from_xml(message)
      wtpp_verify_ticket = msg_hash["xml"]["ComponentVerifyTicket"]
      Rails.cache.write("wtpp_verify_ticket", wtpp_verify_ticket, expires_in: 115.minutes)
      render plain: "success"
    end

    # 默认小程序授权之后redirect url
    def auth_callback
      if params[:auth_code] && params[:expires_in]
        # 根据授权码获取小程序的授权信息
        WechatThirdPartyPlatform.api_query_auth(authorization_code: params[:auth_code])
        render json: { status: 200, message: "auth success" }
      end
      render json: { status: 400, message: "parameter error" }
    end

    def component_auth
      @auth_url = "https://mp.weixin.qq.com/cgi-bin/componentloginpage?component_appid=#{WechatThirdPartyPlatform.appid}&pre_auth_code=#{WechatThirdPartyPlatform.api_create_preauthcode}&redirect_uri=#{WechatThirdPartyPlatform.auth_redirect_url}&auth_type=2"
    end

    def messages
      # TODO:
      render plain: "success"
    end
  end
end
