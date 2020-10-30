module WechatThirdPartyPlatform
  class Register < ApplicationRecord

    before_save :set_component_phone

    enum state: {
      pending: 0,
      success: 1,
      failed: 2
    }

    has_one :application, class_name: "WechatThirdPartyPlatform::Application"

    after_create :sync_to_wechat

    def sync_to_wechat
      response = WechatThirdPartyPlatform.create_fastregisterweapp({
          name: name,
          code: code,
          code_type: code_type.to_i,
          legal_persona_wechat: legal_persona_wechat,
          legal_persona_name: legal_persona_name,
          component_phone: component_phone
        })
      if response["errcode"] != 0
        self.errors.add(:base, response)
        raise ActiveRecord::RecordInvalid, self
      end
    end

    def generate_application!(auth_code:)
      response = WechatThirdPartyPlatform.api_query_auth(authorization_code: auth_code)

      # 该API请求成功不会返回errcode
      raise response["errmsg"] if response["errcode"]

      auth_info = response["authorization_info"]

      transaction do
        create_application!({
          appid: auth_info["authorizer_appid"],
          access_token: auth_info["authorizer_access_token"],
          refresh_token: auth_info["authorizer_refresh_token"],
          func_info: auth_info["func_info"],
          register_id: id
        })

        application.commit_latest_template!
      end
    end

    def set_component_phone
      self.component_phone = WechatThirdPartyPlatform.component_phone
    end
  end
end
