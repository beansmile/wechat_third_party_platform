# frozen_string_literal: true

module WechatThirdPartyPlatform
  class TemplateSetting < ApplicationRecord
    def self.instance
      first || create
    end
  end
end
