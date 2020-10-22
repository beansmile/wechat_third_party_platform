module WechatThirdPartyPlatform::API
  module UploadMedia
    # 上传临时图片素材
    # https://developers.weixin.qq.com/doc/offiaccount/Asset_Management/New_temporary_materials.html
    def image_media_id(image_url)
      result = HTTParty.get(image_url)

      if result.code == 200 && result.body.present?
        file_name = Digest::MD5.hexdigest(image_url)
        temp_file = Tempfile.new([file_name, ".png"], binmode: true)
        temp_file << result.body

        response = http_post("/cgi-bin/media/upload?access_token=#{access_token}&type=image",
          {
            body: {
              media: File.new(temp_file.path)
            },
            headers: {
              "Content-Type" => "multipart/form-data"
            }
          }, false)
        temp_file.close
        if response["media_id"]
          response["media_id"]
        else
          raise UploadImageFail.new("图片上传失败，请检查尺寸和规格大小是否符合要求")
        end
      else
        raise UploadImageFail.new("图片路径错误，获取图片失败")
      end
    end
    class UploadImageFail < StandardError; end
  end
end
