# frozen_string_literal: true

module WechatThirdPartyPlatform
  class Tester < ApplicationRecord
    belongs_to :application, class_name: "WechatThirdPartyPlatform::Application"

    validates_presence_of :wechat_id
    validates_uniqueness_of :wechat_id, scope: :application_id

    before_create :create_wechat_tester
    before_destroy :remove_wechat_tester

    def display_name
      wechat_id
    end

    private
    # {
    #   "errcode": 0,
    #   "errmsg": "ok",
    #   "userstr": "xxxxxxxxx"
    # }
    def create_wechat_tester
      resp = application.client.bind_tester(wechatid: wechat_id)

      raise resp.cn_msg unless resp.success?
      self.userstr = resp["userstr"]
    end

    def remove_wechat_tester
      resp = application.client.unbind_tester(userstr: userstr, wechatid: wechat_id)

      raise resp.cn_msg unless resp.success?

    end
  end
end
