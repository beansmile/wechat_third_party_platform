# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Result < ::Hash
    @@wechat_error_codes = YAML.load_file("#{WechatThirdPartyPlatform::Engine.root}/config/wechat_error_codes.yml")

    SUCCESS_FLAG = "ok".freeze

    def initialize(result)
      result.each_pair do |k, v|
        self[k] = v
      end
    end

    def success?
      self["errcode"] == 0 && self["errmsg"] == SUCCESS_FLAG
    end

    def cn_msg
      "wtpp: #{@@wechat_error_codes[self["errcode"]] || self["errmsg"]}"
    end
  end
end
