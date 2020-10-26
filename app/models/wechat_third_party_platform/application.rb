# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Application < ApplicationRecord
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
      # TODO 小程序尚未完善暂时统一返回成功
      response = if Rails.env.production?
                   client.submit_audit
                 else
                   {
                     "errcode" => 0,
                     "errmsg" => "ok",
                     "auditid" => Time.current.to_i
                   }
                 end

      errors.add(:base, response["errmsg"]) and return false unless response["errcode"] == 0

      audit_submition.update(auditid: response["auditid"])
      audit_submition.pending!

      true
    end
  end
end
