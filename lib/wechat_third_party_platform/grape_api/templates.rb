# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class Templates < Grape::API
    include Grape::Kaminari

    namespace "wechat_third_party_platform/templates" do
      desc "代码模板列表"
      paginate
      get do
        authorize! :read, "Template"

        response = WechatThirdPartyPlatform.gettemplatelist

        response_error(response.cn_msg) unless response.success?

        collection = response["template_list"].map do |hash|
          hash["id"] = hash["template_id"]
          hash["create_time"] = Time.at(hash["create_time"])

          hash
        end

        present paginate(Kaminari.paginate_array(collection))
      end

      route_param :id do
        delete do
          authorize! :destroy, "Template"

          response = WechatThirdPartyPlatform.deletetemplate(template_id: params[:id])

          response_error(response.cn_msg) unless response.success?

          response_success
        end
      end
    end
  end
end
