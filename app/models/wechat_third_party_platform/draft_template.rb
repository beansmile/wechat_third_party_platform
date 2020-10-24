module WechatThirdPartyPlatform
  class DraftTemplate < ApplicationRecord
    def self.fetch_list!
      response = WechatThirdPartyPlatform.gettemplatedraftlist

      raise response["errmsg"] unless response["errcode"] == 0

      response["draft_list"].map do |hash|
        hash["create_time"] = Time.at(hash["create_time"])

        hash
      end
    end
  end
end
