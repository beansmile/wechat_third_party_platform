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

    base_uri "https://api.weixin.qq.com"

    attr_accessor :appid, :access_token

    def initialize(appid, access_token)
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
          analysis_key = "getweanalysisappiddailyvisittrend/#{appid}/#{date}"
          data_in_redis = Rails.cache.fetch(analysis_key)
          if data_in_redis
            ActiveSupport::JSON.decode(data_in_redis)
          elsif date < Date.current
            result = http_post("/datacube/getweanalysisappiddailyvisittrend", body: { begin_date: date, end_date: date })
            next if result["errcode"]
            object = result["list"][0]
            Rails.cache.write(analysis_key, object.to_json, expires_in: 1.month)
            object
          end
        end
      end
    end

    [:get, :post].each do |method|
      define_method "http_#{method}" do |path, options = {}, need_access_token = true|
        body = (options[:body] || {}).select { |_, v| !v.nil? }
        headers = (options[:headers] || {}).reverse_merge({
          "Content-Type" => "application/json",
          "Accept-Encoding" => "*"
        })
        raw_body = headers["Content-Type"] == "multipart/form-data" # 上传临时素材的Content-Type是multipart/form-data，body不需要生成字符串
        path = "#{path}?access_token=#{access_token}" if need_access_token

        uuid = SecureRandom.uuid

        WechatThirdPartyPlatform::LOGGER.debug("request[#{uuid}]: method: #{method}, url: #{path}, body: #{body}, headers: #{headers}")

        response = begin
                     resp = self.class.send(method, path, body: raw_body ? body : JSON.pretty_generate(body), headers: headers, timeout: WechatThirdPartyPlatform::TIMEOUT).body
                     JSON.parse(resp)
                   rescue JSON::ParserError
                     resp
                   rescue *WechatThirdPartyPlatform::HTTP_ERRORS
                     { "errmsg" => "连接超时" }
                   end

        WechatThirdPartyPlatform::LOGGER.debug("response[#{uuid}]: #{response}")

        response
      end
    end
  end
end
