# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class Testers < Grape::API
    include Grape::Kaminari

    wtpp_apis [:create, :index, :destroy, :show] do
      helpers do
        def end_of_association_chain
          WechatThirdPartyPlatform::Tester.where(application_id: current_application.wechat_application_id)
        end

        params :create_params do
          requires :all, using: @api.resource_entity.documentation.slice(
            :wechat_id,
          )
        end

        def create_api
          super
        rescue => e
          response_error(e.message)
        end

        def destroy_api
          super
        rescue => e
          response_error(e.message)
        end
      end
    end
  end
end
