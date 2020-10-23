module WechatThirdPartyPlatform
  class Tester < ApplicationRecord
    belongs_to :application, class_name: WechatThirdPartyPlatform.application_class_name
  end
end
