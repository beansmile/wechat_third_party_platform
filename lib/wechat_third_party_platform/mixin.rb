# frozen_string_literal: true

module WechatThirdPartyPlatform
  module Mixin
    extend ActiveSupport::Concern

    module ClassMethods
      def set_unlimited_wxacode(client:, column:, page:, scene: nil, width: nil, auto_color: nil, line_color: nil, is_hyaline: nil)
        send :after_save_commit do
          WechatThirdPartyPlatform::SetUnlimitedWxacodeJob.perform_later(self, column)
        end

        send :define_method, "set_#{column}_with_unlimited_wxacode" do
          mini_program_client = if client.is_a?(String) || client.is_a?(Symbol)
                                  send(client)
                                else
                                  instance_exec(&client)
                                end
          # 关联了小程序才可创建二维码
          return if !mini_program_client || send(column).attached?

          scene_value = if scene
                          if scene.is_a?(String) || scene.is_a?(Symbol)
                            send(scene)
                          else
                            instance_exec(&scene)
                          end
                        else
                          "id=#{id}"
                        end

          set_wxacode_page_option = WechatThirdPartyPlatform.set_wxacode_page_option
          can_set_wxacode_page_option = if !!set_wxacode_page_option == set_wxacode_page_option
                                          set_wxacode_page_option
                                        else
                                          instance_exec(&set_wxacode_page_option)
                                        end

          page = nil unless can_set_wxacode_page_option
          response = mini_program_client.getwxacodeunlimit(scene: scene_value, page: page, width: width, auto_color: auto_color, line_color: line_color, is_hyaline: is_hyaline)
          if response.is_a?(String)
            img_type = is_hyaline ? "png" : "jpg"
            filename = Digest::MD5.hexdigest(response).concat(".#{img_type}")

            folder = "./tmp/wxacode"
            temp_file_path = "#{folder}/#{filename}"

            FileUtils.mkdir_p(folder)

            open(temp_file_path, "wb") do |file|
              file << response
            end

            send(column).attach(io: File.open(temp_file_path), filename: filename, content_type: "image/#{img_type}")

            FileUtils.rm_f(temp_file_path)
          else
            raise response["errmsg"]
          end
        end
      end
    end
  end
end
