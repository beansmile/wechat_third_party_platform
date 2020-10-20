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

    def auth_callback
      if params[:auth_code] && params[:expires_in]
        WechatThirdPartyPlatform::QueryAuth.api_query_auth(params[:auth_code])
      end
    end

    def component_auth
      @auth_url = "https://mp.weixin.qq.com/cgi-bin/componentloginpage?component_appid=#{WechatThirdPartyPlatform.appid}&pre_auth_code=#{WechatThirdPartyPlatform::PreauthCode.api_create_preauthcode}&redirect_uri=#{WechatThirdPartyPlatform.domain}/auth_callback&auth_type=2"

    end

    def messages
      # TODO:
      render plain: "success"
    end
  end
end
