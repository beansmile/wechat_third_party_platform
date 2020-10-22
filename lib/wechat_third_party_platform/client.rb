# frozen_string_literal: true

require "httparty"

module WechatThirdPartyPlatform
  class Client
    include HTTParty
    include WechatThirdPartyPlatform::API::AccountBaseInfo
    include WechatThirdPartyPlatform::API::Code
    include WechatThirdPartyPlatform::API::UploadMedia
    include WechatThirdPartyPlatform::API::Category
    include WechatThirdPartyPlatform::API::Tester
    include WechatThirdPartyPlatform::API::Wxacode

    base_uri "https://api.weixin.qq.com"

    attr_accessor :access_token

    def initialize(access_token)
      @access_token = access_token
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
