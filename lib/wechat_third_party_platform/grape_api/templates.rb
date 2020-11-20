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

        template_setting = WechatThirdPartyPlatform::TemplateSetting.instance

        collection = response["template_list"].map do |hash|
          hash["id"] = hash["template_id"]
          hash["create_time"] = Time.at(hash["create_time"])
          hash["is_latest"] = template_setting.latest_template_id == hash["template_id"]

          hash
        end.sort { |a,b| (a["is_latest"] == b["is_latest"]) ? ((a["template_id"] > b["template_id"]) ? -1 : 1) : (a["is_latest"] ? -1 : 1)}

        present paginate(Kaminari.paginate_array(collection))
      end

      route_param :id, type: Integer do
        delete do
          authorize! :destroy, "Template"

          response_error("不能删除最新的模板") if WechatThirdPartyPlatform::TemplateSetting.instance.latest_template_id == params[:id]

          response = WechatThirdPartyPlatform.deletetemplate(template_id: params[:id])

          response_error(response.cn_msg) unless response.success?

          response_success
        end
      end
    end
  end
end
