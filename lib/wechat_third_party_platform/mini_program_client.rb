# frozen_string_literal: true

require "httparty"

module WechatThirdPartyPlatform
  class MiniProgramClient
    include HTTParty
    include WechatThirdPartyPlatform::API::AccountBaseInfo
    include WechatThirdPartyPlatform::API::Code
    include WechatThirdPartyPlatform::API::UploadMedia
    include WechatThirdPartyPlatform::API::Category
    include WechatThirdPartyPlatform::API::Tester
    include WechatThirdPartyPlatform::API::Wxacode
    include WechatThirdPartyPlatform::API::Auth
    include WechatThirdPartyPlatform::API::DataAnalysis

    base_uri "https://api.weixin.qq.com"

    attr_accessor :appid, :access_token, :record

    def initialize(appid, access_token, record)
      @record = record
      @appid = appid
      @access_token = access_token
    end

    def decrypt!(session_key:, encrypted_data:, iv:)
      begin
        cipher = OpenSSL::Cipher::AES.new 128, :CBC
        cipher.decrypt
        cipher.padding = 0
        cipher.key = Base64.decode64(session_key)
        cipher.iv  = Base64.decode64(iv)
        data = cipher.update(Base64.decode64(encrypted_data)) << cipher.final
        result = JSON.parse data[0...-data.last.ord]
      rescue StandardError => e
        WechatThirdPartyPlatform::LOGGER.debug("[UserData] decrypt error: #{e.message}")
        raise "微信解析数据错误"
      end

      if result.dig("watermark", "appid") != appid
        WechatThirdPartyPlatform::LOGGER.debug("[UserData] decrypt error: #{result}")
        raise "微信解析数据错误, appid不匹配"
      end

      result
    end

    # 获取授权方的帐号基本信息
    # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/api/api_get_authorizer_info.html
    def api_get_authorizer_info
      WechatThirdPartyPlatform.http_post("/cgi-bin/component/api_get_authorizer_info", body: {
        component_appid: WechatThirdPartyPlatform.component_appid,
        authorizer_appid: appid
      })
    end

    def refresh_record_access_token
      record.update_access_token
      self.access_token = record.reload.access_token
    end

    def access_token_invalid?(invalid_code)
      # 40001 获取 access_token 时 AppSecret 错误，或者 access_token 无效。请开发者认真比对 AppSecret 的正确性，或查看是否正在为恰当的公众号调用接口
      # 42001 access_token 超时，请检查 access_token 的有效期，请参考基础支持 - 获取 access_token 中，对 access_token 的详细机制说明
      # 41001 缺少 access_token 参数, access_token为空是的错误
      [40001, 42001, 41001].include?(invalid_code)
    end

    # 获取小程序PV、UV
    # [{
    #    "ref_date"=>"20180713",
    #    "session_cnt"=>39,
    #    "visit_pv"=>142,
    #    "visit_uv"=>12,
    #    "visit_uv_new"=>1,
    #    "stay_time_uv"=>202.8333,
    #    "stay_time_session"=>62.4103,
    #    "visit_depth"=>2.0256
    # }]
    def get_weanalysis_appid_daily_visit_trend(begin_date, end_date)
      (begin_date..end_date).map do |date|
        if %w[staging production].include?(Rails.env)
          visit_data = WechatThirdPartyPlatform::VisitDatum.find_by(appid: appid, ref_date: date.strftime("%Y%m%d"))
          if visit_data
            visit_data.as_json(except: [:id, :created_at, :updated_at, :appid])
          elsif date < Date.current
            result = getweanalysisappiddailyvisittrend(begin_date: date, end_date: date)
            next if result["errcode"]
            object = result["list"][0]
            WechatThirdPartyPlatform::VisitDatum.new(object.merge(appid: appid)).save if object

            object
          end
        end
      end
    end

    [:get, :post].each do |method|
      define_method "http_#{method}" do |path, options = {}, need_access_token = true|
        access_token_expired_retries = 0
        body = (options[:body] || {}).select { |_, v| !v.nil? }
        headers = (options[:headers] || {}).reverse_merge({
          "Content-Type" => "application/json",
          "Accept-Encoding" => "*"
        })
        wechat_path = path
        raw_body = headers["Content-Type"] == "multipart/form-data" # 上传临时素材的Content-Type是multipart/form-data，body不需要生成字符串

        uuid = SecureRandom.uuid

        response = begin
                     wechat_path = "#{path}?access_token=#{access_token}" if need_access_token
                     WechatThirdPartyPlatform::LOGGER.debug("request[#{uuid}]: method: #{method}, url: #{wechat_path}, body: #{body}, headers: #{headers}")

                     resp = self.class.send(method, wechat_path, body: raw_body ? body : JSON.pretty_generate(body), headers: headers, timeout: WechatThirdPartyPlatform::TIMEOUT).body
                     resp = JSON.parse(resp)
                     raise AccessTokenExpired if resp["errcode"] && access_token_invalid?(resp["errcode"])
                     resp
                   rescue JSON::ParserError
                     resp
                   rescue AccessTokenExpired
                     access_token_expired_retries += 1
                     refresh_record_access_token
                     retry if access_token_expired_retries == 1
                     resp
                   rescue *WechatThirdPartyPlatform::HTTP_ERRORS
                     { "errmsg" => "连接超时" }
                   end

        WechatThirdPartyPlatform::LOGGER.debug("response[#{uuid}]: #{response}")

        response
      end
    end

    class AccessTokenExpired < StandardError; end
  end
end
