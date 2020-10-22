module WechatThirdPartyPlatform::API
  module Category
    [
      # 获取可以设置的所有类目
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/getallcategories.html
      :getallcategories,
      # 获取已设置的所有类目
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/getcategory.html
      :getcategory
    ].each do |action|
      define_method action do
        http_get("/cgi-bin/wxopen/#{action}")
      end
    end

    # 添加类目
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/addcategory.html
    def addcategory(categories:)
      http_post("/cgi-bin/wxopen/addcategory", body: {
        categories: categories
      })
    end

    # 删除类目
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/deletecategory.html
    def deletecategory(first:, second:)
      http_post("/cgi-bin/wxopen/deletecategory", body: {
        first: first, # 一级类目 ID
        second: second # 二级类目 ID
      })
    end

    # 修改类目资质信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/modifycategory.html
    def modifycategory(first:, second:, certicates:)
      http_post("/cgi-bin/wxopen/modifycategory", body: {
        first: first,
        second: second,
        certicates: certicates
      })
    end

    # 获取审核时可填写的类目信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/category/get_category.html
    def wxa_get_category
      http_get("/wxa/get_category")
    end
  end
end
