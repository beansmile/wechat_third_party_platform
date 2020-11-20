# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Application < ApplicationRecord
    require "open-uri"

    include AASM
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
      authorizer_unauthorized: 2,
      authorizer_updateauthorized: 3
    }

    aasm column: :authorization_status, enum: true do
      state :authorizer_pending, initial: true
      state :authorizer_authorized
      state :authorizer_unauthorized
      state :authorizer_updateauthorized

      event :authorization_unauthorize, after_commit: :unbind_application! do
        transitions from: [:authorizer_pending, :authorizer_authorized, :authorizer_updateauthorized],
                    to: :authorizer_unauthorized
      end
    end

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

    def display_name
      project_application&.display_name || appid
    end

    def set_default_domain
      set_default_domain!
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def set_default_domain!
      get_domain_response = client.modify_domain(action: :get)

      raise get_domain_response.cn_msg unless get_domain_response.success?

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

      raise response.cn_msg unless response.success?

      # 个人小程序不支持调用 setwebviewdomain 接口
      if principal_name != "个人"
        # 如果没有指定 action，则默认将第三方平台登记的小程序业务域名全部添加到该小程序
        resp =  client.setwebviewdomain
        raise resp.cn_msg unless resp.success?
      end

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

      raise response.cn_msg unless response.success?

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

      raise response.cn_msg unless response.success?

      template_list = response["template_list"].sort { |a, b| a["template_id"] <=> b["template_id"] }
      template_setting = TemplateSetting.instance
      latest_template = template_list.detect { |template| template["template_id"] == template_setting.latest_template_id } || template_list.last

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

      raise response.cn_msg unless response.success?

      update(audit_submition: Submition.create!(trial_submition.dup.attributes.merge({ "auditid" => response["auditid"], "auto_release" => auto_release })))
    end

    def release
      release!
    rescue RuntimeError => e
      errors.add(:base, e.message)

      false
    end

    def release!
      raise "请先提交审核" unless audit_submition
      raise "代码尚未通过审核" unless audit_submition.success?

      response = client.release

      raise response.cn_msg unless response.success?

      update!(online_submition: audit_submition, audit_submition: nil)
    end

    def enqueue_set_base_data
      WechatThirdPartyPlatform::ApplicationSetBaseDataJob.perform_later(self)
    end

    def set_base_data!
      info = client.api_get_authorizer_info

      raise "获取小程序基本信息失败：#{info["errmsg"]}" if info["errcode"] && info["errcode"] != 0

      authorizer_info = info["authorizer_info"]
      if authorizer_info["head_img"].present?
        head_img_file = open(authorizer_info["head_img"])
        head_img_blob = ActiveStorage::Blob.create_after_upload!(io: head_img_file, filename: SecureRandom.uuid, content_type: head_img_file.meta["content-type"])
      end
      if authorizer_info["qrcode_url"].present?
        qrcode_url_file = open(authorizer_info["qrcode_url"])
        qrcode_url_blob = ActiveStorage::Blob.create_after_upload!(io: qrcode_url_file, filename: SecureRandom.uuid, content_type: qrcode_url_file.meta["content-type"])
      end

      update!(
        nick_name: authorizer_info["nick_name"],
        user_name: authorizer_info["user_name"],
        principal_name: authorizer_info["principal_name"],
        mini_program_info: authorizer_info["MiniProgramInfo"],
        head_img: head_img_blob&.signed_id,
        qrcode_url: qrcode_url_blob&.signed_id,
        refresh_token: info.dig("authorization_info", "authorizer_refresh_token") || refresh_token
      )

      project_application&.update!(name: authorizer_info["nick_name"]) if authorizer_info["nick_name"].present?
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

      state = info["status"].to_i == 0 ? "success" : "failed"
      register.update(state: state, audit_result: msg_hash)

      ThirdFasteregisterJob.perform_later(register, msg_hash["auth_code"]) if register.success?
    end

    private

    def new_name_modified_check
      errors[:base] << "小程序名字审核中，禁止更改" if name_submitting?
    end

    def set_name_changed_status
      self.name_changed_status = "name_submitting"
    end

    def unbind_application!
      project_application&.unbind_application!
    end
  end
end
