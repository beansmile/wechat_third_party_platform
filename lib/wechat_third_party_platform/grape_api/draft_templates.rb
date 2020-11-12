# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class DraftTemplates < Grape::API
    include Grape::Kaminari

    namespace "wechat_third_party_platform/draft_templates" do
      desc "代码草稿列表"
      paginate
      get do
        authorize! :read, "DraftTemplate"

        response = WechatThirdPartyPlatform.gettemplatedraftlist

        response_error(response.cn_msg) unless response.success?

        collection = response["draft_list"].map do |hash|
          hash["id"] = hash["draft_id"]
          hash["create_time"] = Time.at(hash["create_time"])

          hash
        end

        present paginate(Kaminari.paginate_array(collection))
      end

      route_param :id do
        post "add_to_template" do
          authorize! :add_to_template, "DraftTemplate"

          response = WechatThirdPartyPlatform.addtotemplate(draft_id: params[:id])

          response_error(response.cn_msg) unless response.success?

          response_success
        end
      end
    end
  end
end
