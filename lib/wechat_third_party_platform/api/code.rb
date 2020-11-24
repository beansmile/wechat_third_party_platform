# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module Code
    # 上传小程序代码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/commit.html
    def commit(template_id:, ext_json:, user_version:, user_desc:)
      http_post("/wxa/commit", body: {
        template_id: template_id,
        ext_json: ext_json,
        user_version: user_version,
        user_desc: user_desc
      })
    end

    # 获取体验版二维码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/get_qrcode.html
    def get_qrcode(path: nil)
      http_get("/wxa/get_qrcode?path=#{ERB::Util.url_encode(path)}", {}, format_data: false)
    end

    # 提交审核
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/submit_audit.html
    def submit_audit(item_list: nil, preview_info: nil, version_desc: nil, feedback_info: nil, feedback_stuff: nil, ugc_declare: nil)
      http_post("/wxa/submit_audit", body: {
        item_list: item_list,
        preview_info: preview_info,
        version_desc: version_desc,
        feedback_info: feedback_info,
        feedback_stuff: feedback_stuff,
        ugc_declare: ugc_declare
      })
    end

    # 查询指定发布审核单的审核状态
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/get_auditstatus.html
    def get_auditstatus(auditid:)
      http_post("/wxa/get_auditstatus", body: { auditid: auditid })
    end

    # 发布已通过审核的小程序
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/release.html
    def release
      http_post("/wxa/release")
    end

    # 分阶段发布
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/grayrelease.html
    def grayrelease(gray_percentage:)
      http_post("/wxa/release", body: { gray_percentage: gray_percentage })
    end

    # 修改小程序线上代码的可见状态
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/change_visitstatus.html
    def change_visitstatus(action:)
      http_post("/wxa/change_visitstatus", body: { action: action })
    end

    # 查询当前设置的最低基础库版本及各版本用户占比
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/getweappsupportversion.html
    def getweappsupportversion
      http_post("/cgi-bin/wxopen/getweappsupportversion")
    end

    # 设置最低基础库版本
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/setweappsupportversion.html
    def setweappsupportversion(version:)
      http_post("/cgi-bin/wxopen/setweappsupportversion", body: { version: version })
    end

    # 加急审核申请
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/speedup_audit.html
    def speedupaudit(auditid:)
      http_post("/wxa/speedupaudit", body: { auditid: auditid })
    end

    [
      # 获取已上传的代码的页面列表
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/get_page.html
      :get_page,
      # 查询最新一次提交的审核状态
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/get_latest_auditstatus.html
      :get_latest_auditstatus,
      # 小程序审核撤回
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/undocodeaudit.html
      :undocodeaudit,
      # 版本回退
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/revertcoderelease.html
      :revertcoderelease,
      # 查询当前分阶段发布详情
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/getgrayreleaseplan.html
      :getgrayreleaseplan,
      # 取消分阶段发布
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/revertgrayrelease.html
      :revertgrayrelease,
      # 查询服务商的当月提审限额（quota）和加急次数
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code/query_quota.html
      :queryquota,
    ].each do |action|
      define_method action do
        http_get("/wxa/#{action}")
      end
    end
  end
end
