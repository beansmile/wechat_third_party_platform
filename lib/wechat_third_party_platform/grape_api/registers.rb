# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class Registers < Grape::API
    wtpp_apis [:create] do
      helpers do
        params :create_params do
          requires :all, using: @api.resource_entity.documentation.slice(
            :name,
            :code,
            :code_type,
            :legal_persona_wechat,
            :legal_persona_name
          )
        end

        def create_api
          authorize! :create, WechatThirdPartyPlatform::Register

          register = WechatThirdPartyPlatform::Register.find_or_create_by({
            application_id: current_application.id,
            creator_id: current_user.id
          })

          standard_update(register, resource_params, resource_entity)
        end
      end

      desc "获取当前应用快速注册详情"
      get "info" do
        present current_application.register, with: resource_entity
      end
    end
  end
end
