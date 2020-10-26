# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Tester < ApplicationRecord
    belongs_to :application, class_name: "WechatThirdPartyPlatform::Application"
  end
end
