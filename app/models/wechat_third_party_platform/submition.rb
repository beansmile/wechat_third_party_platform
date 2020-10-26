# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Submition < ApplicationRecord
    belongs_to :application, class_name: "WechatThirdPartyPlatform::Application"
    has_one :audit_application, class_name: "WechatThirdPartyPlatform::Application", foreign_key: :audit_submition_id, dependent: :nullify

    enum state: {
      # 待提交审核
      init: 0,
      # 审核中
      pending: 1,
      # 审核通过
      success: 2,
      # 审核不通过
      fail: 3,
      # 审核延后
      delay: 4
    }
  end
end
