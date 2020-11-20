# frozen_string_literal: true
module WechatThirdPartyPlatform
  module GrapeAPI
    module Entities
    end
  end
end

require "wechat_third_party_platform/grape_api/entities/model"
[
  :submition,
  :application,
  :tester,
  :register,
  :template_setting,
].each do |name|
  require "wechat_third_party_platform/grape_api/entities/simple_#{name}"
  require "wechat_third_party_platform/grape_api/entities/#{name}"
  require "wechat_third_party_platform/grape_api/entities/#{name}_detail"
end
