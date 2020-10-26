# frozen_string_literal: true

module WechatThirdPartyPlatform
  class MessageEncryptor

    class << self
      def decrypt_message(original_xml)
        msg_encrypt = Hash.from_xml(original_xml)["xml"]["Encrypt"]
        decrypt_content(msg_encrypt)
      end

      def decrypt_content(msg_encrypt)
        msg_decrypt = aes_decrypt(msg_encrypt)
        msg_decrypt[20..msg_decrypt.rindex(">")]
      end

      def encrypt_message(original_xml, app_id)
        timestamp = Time.now.to_i.to_s
        nonce = SecureRandom.hex(5)
        msg_encrypt = encrypt_content(original_xml, app_id)
        msg_signature = Digest::SHA1.hexdigest([WechatThirdPartyPlatform.message_token, timestamp, nonce, msg_encrypt].sort.join)
        <<~END_TEXT_AREA
          <xml>
            <Encrypt><![CDATA[#{msg_encrypt}]]></Encrypt>
            <MsgSignature>#{msg_signature}</MsgSignature>
            <TimeStamp>#{timestamp}</TimeStamp>
            <Nonce>#{nonce}</Nonce>
          </xml>
        END_TEXT_AREA
      end

      def encrypt_content(msg_decrypt, app_id)
        msg = msg_decrypt.force_encoding("ascii-8bit")
        msg = kcs7_encoder "#{SecureRandom.hex(8)}#{[msg.size].pack('N')}#{msg}#{app_id}"
        aes_encrypt(msg)
      end

      private
        def kcs7_encoder(msg)
          block_size = 32
          amount_to_pad = block_size - (msg.length % block_size)
          amount_to_pad = block_size if amount_to_pad == 0
          pad = amount_to_pad.chr
          "#{msg}#{pad * amount_to_pad}"
        end

        def aes_decrypt(msg)
          aes_key = Base64.decode64 WechatThirdPartyPlatform.message_key + "="
          cipher = OpenSSL::Cipher.new("AES-256-CBC")
            .tap { |c| c.decrypt }
            .tap { |c| c.padding = 0 }
            .tap { |c| c.key = aes_key }
            .tap { |c| c.iv = aes_key[0, 16] }
          cipher.update(Base64.decode64(msg.strip)).strip
        end

        def aes_encrypt(msg)
          aes_key = Base64.decode64(WechatThirdPartyPlatform.message_key + "=")
          en_cipher = OpenSSL::Cipher.new("AES-256-CBC")
            .tap { |c| c.encrypt }
            .tap { |c| c.padding = 0 }
            .tap { |c| c.key = aes_key }
            .tap { |c| c.iv = aes_key[0, 16] }
          Base64.encode64("#{en_cipher.update(msg)}#{en_cipher.final}")
        end
      end
  end
end
