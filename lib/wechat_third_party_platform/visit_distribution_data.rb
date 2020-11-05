# frozen_string_literal: true

module WechatThirdPartyPlatform
  class VisitDistributionData
    base_path = File.expand_path("../../config", File.dirname(__FILE__))
    @@access_depth_info = YAML.load(File.read("#{base_path}/wechat_access_depth_info.yml"))
    @@access_source_session_cnt = YAML.load(File.read("#{base_path}/wechat_access_source_session_cnt.yml"))
    @@access_staytime_info = YAML.load(File.read("#{base_path}/wechat_access_staytime_info.yml"))

    def self.access_depth_info_value(key)
      @@access_depth_info[key] || "未知"
    end

    def self.access_source_session_cnt_value(key)
      @@access_source_session_cnt[key] || "未知"
    end

    def self.access_staytime_info_value(key)
      @@access_staytime_info[key] || "未知"
    end
  end
end
