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

    has_many :testers, dependent: :destroy

    def client
      @client ||= WechatThirdPartyPlatform::MiniProgramClient.new(appid, access_token)
    end
  end
end
