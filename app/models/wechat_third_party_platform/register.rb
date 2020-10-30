# frozen_string_literal: true

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

    def set_component_phone
      self.component_phone = WechatThirdPartyPlatform.component_phone
    end
  end
end
