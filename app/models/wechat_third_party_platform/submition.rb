# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Submition < ApplicationRecord
    belongs_to :application, class_name: "WechatThirdPartyPlatform::Application"
    has_one :audit_application, class_name: "WechatThirdPartyPlatform::Application", foreign_key: :audit_submition_id, dependent: :nullify

    has_one_attached :trial_version_qrcode

    enum state: {
      # 审核中
      pending: 0,
      # 审核通过
      success: 1,
      # 审核不通过
      fail: 2,
      # 审核延后
      delay: 3
    }

    validates :template_id, presence: true
    validates :user_version, presence: true
    validates :user_desc, presence: true

    def reason
      @reason ||= audit_result["Reason"]
    end

    def generate_trial_version_qrcode!
      response = application.client.get_qrcode(path: "pages/index")

      # 成功会直接将返回的二进制结果，所以这里判断是否返回errmsg即可确认是出错
      raise response["errmsg"] if response["errmsg"]

      filename = "#{Digest::MD5.hexdigest(response)}.jpg"

      folder = "./tmp/trial_version_qrcode"
      temp_file_path = "#{folder}/#{filename}"

      FileUtils.mkdir_p(folder)

      open(temp_file_path, "wb") do |file|
        file << response
      end

      self.trial_version_qrcode.attach(io: File.open(temp_file_path), filename: filename, content_type: "image/jpeg")

      FileUtils.rm_f(temp_file_path)
    end
  end
end
