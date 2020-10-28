# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Application < ApplicationRecord
    enum source: { wechat: 0, platform: 1 }
    enum account_type: {
      # 订阅号暂不处理
      # 公众号暂不处理
      # official: 2,
      # 小程序
      mini_program: 3
    }, _suffix: true

    enum principal_type: {
      # 个人
      person: 0,
      # 企业
      enterprise: 1,
      # 媒体
      media: 2,
      # 政府
      government: 3,
      # 其他
      other: 4
    }, _suffix: true

    belongs_to :audit_submition, class_name: "WechatThirdPartyPlatform::Submition", optional: true
    belongs_to :register, class_name: "WechatThirdPartyPlatform::Register", optional: true
    belongs_to :online_submition, class_name: "WechatThirdPartyPlatform::Submition", optional: true

    has_many :testers, dependent: :destroy

    def client
      @client ||= WechatThirdPartyPlatform::MiniProgramClient.new(appid, access_token)
    end

    def commit(template_id:, user_version:, user_desc:, ext_json: {})
      errors.add(:base, "已有正在审核的代码") and return false if audit_submition && (audit_submition.pending? || audit_submition.delay?)

      response = client.commit(
        template_id: template_id,
        user_version: user_version,
        user_desc: user_desc,
        ext_json: ext_json.to_json
      )

      errors.add(:base, response["errmsg"]) and return false unless response["errcode"] == 0

      self.audit_submition = Submition.new(
        template_id: template_id,
        ext_json: ext_json,
        user_version: user_version,
        user_desc: user_desc,
        application: self
      )

      save
    end

    def submit_audit
      errors.add(:base, "请先上传代码") and return false unless audit_submition
      errors.add(:base, "已有正在审核的代码") and return false if audit_submition.pending? || audit_submition.delay?

      # TODO 后期需要支持item_list，preview_info，version_desc等参数
      response = client.submit_audit

      errors.add(:base, response["errmsg"]) and return false unless response["errcode"] == 0

      audit_submition.update(auditid: response["auditid"], audit_result: {}, state: :pending)
    end

    def release
      errors.add(:base, "请先上传代码") and return false unless audit_submition
      errors.add(:base, "代码尚未通过审核") and return false unless audit_submition.success?

      response = client.release

      errors.add(:base, response["errmsg"]) and return false unless response["errcode"] == 0

      update(online_submition: audit_submition, audit_submition: nil)
    end
  end
end
