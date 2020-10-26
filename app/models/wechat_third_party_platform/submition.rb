# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Submition < ApplicationRecord
    belongs_to :application, class_name: "WechatThirdPartyPlatform::Application"
  end
end
