# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class WechatCategories < Grape::API
    include Grape::Kaminari

    namespace "wechat_third_party_platform/wechat_categories" do
      desc "获取可设置的所有类目"
      get "available" do
        authorize! :read, "WechatCategory"

        response = current_wechat_application_client.getallcategories

        response_error(response.cn_msg) unless response.success?

        present response["categories_list"]["categories"]
      end

      desc "获取已设置的所有类目"
      paginate
      get do
        authorize! :read, "WechatCategory"

        if current_application.wechat_application
          response = current_wechat_application_client.getcategory

          response_error(response.cn_msg) unless response.success?

          present paginate(Kaminari.paginate_array(response["categories"]))
        else
          present paginate(Kaminari.paginate_array([]))
        end
      end

      desc "添加类目"
      params do
        requires :categories, type: Array do
          requires :first, type: Integer, desc: "一级类目 ID"
          requires :second, type: Integer, desc: "二级类目 ID"
          optional :certicates, type: Array, desc: "资质信息列表" do
            optional :key, type: String, desc: "资质名称"
            optional :value, type: String, desc: "资质图片media_id"
          end
        end
      end
      post do
        authorize! :create, "WechatCategory"

        response = current_wechat_application_client.addcategory(categories: params[:categories])

        response_error(response.cn_msg) unless response.success?

        present response_success
      end

      desc "删除类目"
      params do
        requires :first, type: Integer, desc: "一级类目ID"
        requires :second, type: Integer, desc: "二级类目ID"
      end
      delete do
        authorize! :destroy, "WechatCategory"

        response = current_wechat_application_client.deletecategory(first: params[:first], second: params[:second])

        response_error(response.cn_msg) unless response.success?

        present response_success
      end

      desc "修改类目资质信息"
      params do
        requires :first, type: Integer, desc: "一级类目 ID"
        requires :second, type: Integer, desc: "二级类目 ID"
        requires :certicates, type: Array, desc: "资质信息列表" do
          requires :key, type: String, desc: "资质名称"
          requires :value, type: String, desc: "资质图片media_id"
        end
      end
      put do
        authorize! :update, "WechatCategory"

        params[:certicates].each do |certificate|
          url = ActiveStorage::Blob.find_signed(certificate[:value]).service_url
          certificate[:value] = current_wechat_application_client.image_media_id(url)
        end

        response = current_wechat_application_client.modifycategory(first: params[:first], second: params[:second], certicates: params[:certicates])

        response_error(response.cn_msg) unless response.success?

        present response_success
      end

      desc "获取审核时可填写的类目信息"
      get "avalaible_modification" do
        authorize! :read, "WechatCategory"

        response = current_wechat_application_client.wxa_get_category

        response_error(response.cn_msg) unless response.success?

        present response["category_list"]
      end
    end
  end
end
