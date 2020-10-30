# frozen_string_literal: true

module WechatThirdPartyPlatform
  class ApplicationJob < ActiveJob::Base
    queue_as :default

  end
end
