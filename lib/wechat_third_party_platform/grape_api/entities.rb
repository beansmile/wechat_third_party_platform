module WechatThirdPartyPlatform
  module GrapeAPI
    module Entities
    end
  end
end

[
  :submition,
  :application,
  :tester,
  :register,
].each do |name|
  require "wechat_third_party_platform/grape_api/entities/simple_#{name}"
  require "wechat_third_party_platform/grape_api/entities/#{name}"
  require "wechat_third_party_platform/grape_api/entities/#{name}_detail"
end
