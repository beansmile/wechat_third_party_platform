# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Application < ApplicationRecord
    require "open-uri"

    include AccessTokenConcern
    include AuthorizationHandlerConcern

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

    # effective: 审核通过，submitting: 提交审核中，rejected：拒绝
    enum name_changed_status: {
      name_effective: 0,
      name_submitting: 1,
      name_rejected: 2,
    }

    enum authorization_status: {
      authorizer_pending: 0,
      authorizer_authorized: 1,
      authorizer_unauthorized: 3,
      authorizer_updateauthorized: 4
    }

    belongs_to :audit_submition, class_name: "WechatThirdPartyPlatform::Submition", optional: true
    belongs_to :register, class_name: "WechatThirdPartyPlatform::Register", optional: true
    belongs_to :online_submition, class_name: "WechatThirdPartyPlatform::Submition", optional: true
    belongs_to :trial_submition, class_name: "WechatThirdPartyPlatform::Submition", optional: true

    has_many :testers, dependent: :destroy
    has_one :project_application, class_name: WechatThirdPartyPlatform.project_application_class_name, foreign_key: :wechat_application_id, dependent: :nullify

    has_one_attached :head_img
    has_one_attached :qrcode_url

    validates :appid, uniqueness: true
    validate :new_name_modified_check, if: :new_name_changed?

    before_save :set_name_changed_status, if: :new_name_changed?

    def client
      @client ||= WechatThirdPartyPlatform::MiniProgramClient.new(appid, access_token, self)
    end

    def set_default_domain
      set_default_domain!
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def set_default_domain!
      get_domain_response = client.modify_domain(action: :get)

      raise get_domain_response["errmsg"] unless get_domain_response["errcode"] == 0

      # 如果小程序domain配置已包含所有默认domain配置，则不发送修改请求，不然会返回错误信息
      return if (get_domain_response["requestdomain"] & WechatThirdPartyPlatform.requestdomain) == WechatThirdPartyPlatform.requestdomain &&
        (get_domain_response["wsrequestdomain"] & WechatThirdPartyPlatform.wsrequestdomain) == WechatThirdPartyPlatform.wsrequestdomain &&
        (get_domain_response["uploaddomain"] & WechatThirdPartyPlatform.uploaddomain) == WechatThirdPartyPlatform.uploaddomain &&
        (get_domain_response["downloaddomain"] & WechatThirdPartyPlatform.downloaddomain) == WechatThirdPartyPlatform.downloaddomain

      response = client.modify_domain(
        action: "add",
        requestdomain: WechatThirdPartyPlatform.requestdomain,
        wsrequestdomain: WechatThirdPartyPlatform.wsrequestdomain,
        uploaddomain: WechatThirdPartyPlatform.uploaddomain,
        downloaddomain: WechatThirdPartyPlatform.downloaddomain
      )

      raise response["errmsg"] unless response["errcode"] == 0

      # 如果没有指定 action，则默认将第三方平台登记的小程序业务域名全部添加到该小程序
      resp =  client.setwebviewdomain
      raise resp["errmsg"] unless resp["errcode"] == 0

      true
    end

    def commit(template_id:, user_version:, user_desc:)
      commit!(template_id: template_id, user_version: user_version, user_desc: user_desc)
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def commit!(template_id:, user_version:, user_desc:)
      ext_json = if project_application
                   # TODO 这里的project_application.app_config会与项目耦合，后面需要把app_config关联到当前model
                   project_application.app_config.format_ext_json
                 else
                   {}
                 end

      response = client.commit(
        template_id: template_id,
        user_version: user_version,
        user_desc: user_desc,
        ext_json: ext_json.to_json
      )

      raise response["errmsg"] unless response["errcode"] == 0

      self.trial_submition = Submition.new(
        template_id: template_id,
        ext_json: ext_json,
        user_version: user_version,
        user_desc: user_desc,
        application: self
      )

      save!

      WechatThirdPartyPlatform::GenerateTrialVersionQrcodeJob.perform_later(trial_submition)

      true
    end

    def commit_latest_template
      commit_latest_template!
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def commit_latest_template!
      response = WechatThirdPartyPlatform.gettemplatelist

      raise response["errmsg"] unless response["errcode"] == 0

      # TODO 暂时根据id来判断哪个template是最新的
      latest_template = response["template_list"].sort { |a, b| a["template_id"] <=> b["template_id"] }.last

      raise "无任何代码模板" if latest_template.nil?

      commit!(template_id: latest_template["template_id"], user_version: latest_template["user_version"], user_desc: latest_template["user_desc"])
    end

    def submit_audit(auto_release: false)
      submit_audit!(auto_release: auto_release)
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def submit_audit!(auto_release: false)
      raise "请先上传代码" unless trial_submition
      raise "已有正在审核的代码" if audit_submition && (audit_submition.pending? || audit_submition.delay?)

      # TODO 后期需要支持item_list，preview_info，version_desc等参数
      response = client.submit_audit

      raise response["errmsg"] unless response["errcode"] == 0

      create_audit_submition!(trial_submition.dup.merge(auto_release: auto_release))
    end

    def release
      release!
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def release!
      raise "请先上传代码" unless audit_submition
      raise "代码尚未通过审核" unless audit_submition.success?

      response = client.release

      raise response["errmsg"] unless response["errcode"] == 0

      update!(online_submition: audit_submition, audit_submition: nil)
    end

    def enqueue_set_base_data
      WechatThirdPartyPlatform::ApplicationSetBaseDataJob.perform_later(self)
    end

    def set_base_data!
      info = client.api_get_authorizer_info

      raise info["errmsg"] if info["errmsg"]

      authorizer_info = info["authorizer_info"]
      head_img_file = open(authorizer_info["head_img"])
      qrcode_url_file = open(authorizer_info["qrcode_url"])
      head_img_blob = ActiveStorage::Blob.create_after_upload!(io: head_img_file, filename: SecureRandom.uuid, content_type: head_img_file.meta["content-type"])
      qrcode_url_blob = ActiveStorage::Blob.create_after_upload!(io: qrcode_url_file, filename: SecureRandom.uuid, content_type: qrcode_url_file.meta["content-type"])

      update!(
        nick_name: authorizer_info["nick_name"],
        user_name: authorizer_info["user_name"],
        principal_name: authorizer_info["principal_name"],
        mini_program_info: authorizer_info["MiniProgramInfo"],
        head_img: head_img_blob.signed_id,
        qrcode_url: qrcode_url_blob.signed_id,
        refresh_token: info.dig("authorization_info", "authorizer_refresh_token") || refresh_token
      )

      project_application&.update!(name: authorizer_info["nick_name"])
    end

    def name_to_effective!
      update!(
        name_changed_status: "name_effective",
        nick_name: new_name,
        name_rejected_reason: nil
      )
    end

    def reject_name_changed!(reason)
      update!(
        name_changed_status: "name_rejected",
        name_rejected_reason: reason
      )
    end

    def handle_weapp_audit_success(msg_hash:)
      return unless audit_submition.pending? || audit_submition.delay?

      audit_submition.update(audit_result: msg_hash, state: :success)
      ReleaseJob.perform_later(self) if audit_submition.auto_release?
    end

    def self.handle_notify_third_fasteregister(msg_hash:)
      info = msg_hash["info"]
      register = Register.where({
        name: info["name"],
        code: info["code"],
        code_type: info["code_type"],
        legal_persona_wechat: info["legal_persona_wechat"],
        legal_persona_name: info["legal_persona_name"]
      }).last

      return unless register

      register.update(state: "failed", audit_result: msg_hash) and return unless msg_hash["status"] == 0

      ThirdFasteregisterJob.perform_later(register, msg_hash["auth_code"])
    end

    private

    def new_name_modified_check
      errors[:base] << "小程序名字审核中，禁止更改" if name_submitting?
    end

    def set_name_changed_status
      self.name_changed_status = "name_submitting"
    end
  end
end
