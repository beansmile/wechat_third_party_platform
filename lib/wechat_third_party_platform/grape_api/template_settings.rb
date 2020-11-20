# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class TemplateSettings < Grape::API

    wtpp_apis [] do
      helpers do
        def resource
          @resource ||= resource_class.instance
        end
      end
      desc "代码模板设置"
      params do
        optional :latest_template_id, type: Integer
      end
      put do
        authorize_and_update_resource
      end
    end
  end
end
