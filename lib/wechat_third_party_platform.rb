# frozen_string_literal: true

require "custom_grape"

require "wechat_third_party_platform/engine"
require "wechat_third_party_platform/message_encryptor"
require "wechat_third_party_platform/api"
require "wechat_third_party_platform/mini_program_client"
require "wechat_third_party_platform/mixin"
require "wechat_third_party_platform/visit_distribution_data"
require "wechat_third_party_platform/result"

module WechatThirdPartyPlatform
  include HTTParty

  base_uri "https://api.weixin.qq.com"

  LOGGER = ::Logger.new("./log/wechat_third_party_platform.log")

  ENV_FALLBACK_ARRAY = [:production, :staging, :development]

  HTTP_ERRORS = [
    EOFError,
    Errno::ECONNRESET,
    Errno::EINVAL,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    Timeout::Error
  ]

  TIMEOUT = 5

  mattr_accessor :component_appid, :component_appsecret, :message_token, :message_key, :auth_redirect_url, :component_phone
  mattr_accessor :project_application_class_name, :set_wxacode_page_option
  @@project_application_class_name ||= "::Application"
  @@set_wxacode_page_option ||= true

  mattr_accessor :requestdomain
  @@requestdomain ||= []

  mattr_accessor :wsrequestdomain
  @@wsrequestdomain ||= []

  mattr_accessor :uploaddomain
  @@uploaddomain ||= []

  mattr_accessor :downloaddomain
  @@downloaddomain ||= []

  class<< self
    def cache_key_prefix
      "#{Rails.application.class.module_parent.name.underscore}_#{Rails.env}:#{component_appid}"
    end

    def access_token_cache_key
      "#{cache_key_prefix}:wtpp_access_token"
    end

    def pre_auth_code_cache_key
      "#{cache_key_prefix}:wtpp_pre_auth_code"
    end

    def wtpp_verify_ticket_cache_key
      "#{cache_key_prefix}:wtpp_verify_ticket"
    end

    # TODO: 第三方平台上设置的是正式环境域名，Staging上没办法调起微信授权页
    def component_auth_url(application_id:)
      "https://mp.weixin.qq.com/cgi-bin/componentloginpage?component_appid=#{component_appid}&pre_auth_code=#{api_create_preauthcode}&redirect_uri=#{auth_redirect_url}/#{application_id}&auth_type=2"
    end

    def get_component_access_token
      access_token = Rails.cache.fetch(access_token_cache_key)
      return access_token if access_token

      ENV_FALLBACK_ARRAY.each do |env|
        if Rails.env == env.to_s
          if access_token.nil?

            resp = component_access_token
            access_token = resp["component_access_token"]
            Rails.cache.write(access_token_cache_key, access_token, expires_in: 115.minutes)
          end

          break
        else
          host = Rails.application.credentials.dig(env, :host)
          # 未部署的环境暂时不配置host
          next if host.blank?

          resp = get("#{host}/admin_api/v1/wechat_third_party_platform/applications/component_access_token", headers: { "api-authorization-token" => Rails.application.credentials.dig(env, WechatThirdPartyPlatform::Application.api_authorization_token_key) })
          next unless access_token = resp["component_access_token"]
          Rails.cache.write(access_token_cache_key, access_token, expires_in: 5.minutes)

          break
        end
      end

      access_token
    end

    # 令牌
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/component_access_token.html
    def component_access_token
      component_verify_ticket = Rails.cache.fetch(wtpp_verify_ticket_cache_key)
      raise "component verify ticket not exist" unless component_verify_ticket

      http_post("/cgi-bin/component/api_component_token", { body: {
        component_appid: WechatThirdPartyPlatform.component_appid,
        component_appsecret: WechatThirdPartyPlatform.component_appsecret,
        component_verify_ticket: component_verify_ticket
      } }, { need_access_token: false })
    end

    # 预授权码
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/pre_auth_code.html
    def api_create_preauthcode
      pre_auth_code = fetch_pre_auth_code

      return pre_auth_code if pre_auth_code

      resp = http_post("/cgi-bin/component/api_create_preauthcode", { body: {
        component_appid: component_appid
      }}, { format_data: false })

      pre_auth_code = resp["pre_auth_code"]
      cache_pre_auth_code(pre_auth_code)

      pre_auth_code
    end

    def cache_pre_auth_code(pre_auth_code)
      Rails.cache.write(pre_auth_code_cache_key, pre_auth_code, expires_in: 10.minutes)
    end

    def fetch_pre_auth_code
      Rails.cache.fetch(pre_auth_code_cache_key)
    end

    # 创建小程序接口
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Fast_Registration_Interface_document.html
    def create_fastregisterweapp(name:, code_type:, code:, legal_persona_wechat:, legal_persona_name:, component_phone:)
      http_post("/cgi-bin/component/fastregisterweapp?action=create", body: {
        name: name,
        code: code,
        code_type: code_type,
        legal_persona_wechat: legal_persona_wechat,
        legal_persona_name: legal_persona_name,
        component_phone: component_phone
      })
    end

    # 查询创建任务状态
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/Fast_Registration_Interface_document.html
    def search_fastregisterweapp(name:, legal_persona_wechat:, legal_persona_name:)
      http_post("/cgi-bin/component/fastregisterweapp?action=search", body: {
        name: name,
        legal_persona_wechat: legal_persona_wechat,
        legal_persona_name: legal_persona_name
      })
    end

    # 使用授权码获取授权信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/authorization_info.html
    def api_query_auth(authorization_code:)
      http_post("/cgi-bin/component/api_query_auth", { body: {
        component_appid: component_appid,
        authorization_code: authorization_code
      } }, { format_data: false })
    end

    def refresh_authorizer_access_token(authorizer_appid:, authorizer_refresh_token:)
      http_post("/cgi-bin/component/api_authorizer_token", { body: {
        component_appid: component_appid,
        authorizer_appid: authorizer_appid,
        authorizer_refresh_token: authorizer_refresh_token
      } }, { format_data: false })
    end

    # 小程序登录
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/WeChat_login.html
    def jscode_to_session(appid:, js_code:)
      http_get("/sns/component/jscode2session", { body: {
        appid: appid,
        js_code: js_code,
        grant_type: "authorization_code",
        component_appid: component_appid
      } }, { need_access_token: false, format_data: false })
    end

    # 获取代码草稿列表
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code_template/gettemplatedraftlist.html
    def gettemplatedraftlist
      http_get("/wxa/gettemplatedraftlist")
    end

    # 将草稿添加到代码模板库
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code_template/addtotemplate.html
    def addtotemplate(draft_id:)
      http_post("/wxa/addtotemplate", body: { draft_id: draft_id } )
    end

    # 获取代码模板列表
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code_template/gettemplatelist.html
    def gettemplatelist
      http_get("/wxa/gettemplatelist")
    end

    # 删除指定代码模板
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/code_template/deletetemplate.html
    def deletetemplate(template_id:)
      http_post("/wxa/deletetemplate", body: { template_id: template_id })
    end

    [:get, :post].each do |method|
      define_method "http_#{method}" do |path, options = {}, other_config = {}|
        other_config = other_config.reverse_merge!({ need_access_token: true, format_data: true })
        body = (options[:body] || {}).select { |_, v| !v.nil? }
        headers = (options[:headers] || {}).reverse_merge({
          "Content-Type" => "application/json",
          "Accept-Encoding" => "*"
        })

        if other_config[:need_access_token]
          connector = path.include?("?") ? "&" : "?"
          path = "#{path}#{connector}component_access_token=#{get_component_access_token}"
        end

        uuid = SecureRandom.uuid

        LOGGER.debug("request[#{uuid}]: method: #{method}, url: #{path}, body: #{body}, headers: #{headers}")

        response = begin
                     resp = self.send(method, path, body: JSON.pretty_generate(body), headers: headers, timeout: TIMEOUT).body
                     JSON.parse(resp)
                   rescue JSON::ParserError
                     resp
                   rescue *HTTP_ERRORS
                     { "errcode" => 9206901, "errmsg" => "连接超时" }
                   end

        LOGGER.debug("response[#{uuid}]: #{response}")
        other_config[:format_data] ? WechatThirdPartyPlatform::Result.new(response) : response
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  include WechatThirdPartyPlatform::Mixin
end
