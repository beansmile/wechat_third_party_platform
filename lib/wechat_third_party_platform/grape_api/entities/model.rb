# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI::Entities
  class Model < CustomGrape::Entity
    expose :id, documentation: { type: Integer, desc: "ID" }
    expose :created_at, documentation: { type: DateTime, desc: "创建时间" }
    expose :updated_at, documentation: { type: DateTime, desc: "更新时间" }
    expose :cn do |obj|
      obj.class.name
    end
    expose :tn do |obj|
      obj.class.table_name
    end

    def self.guess_model
      begin
        model_name = "WechatThirdPartyPlatform::#{self.to_s.split("::")[-1].singularize}"

        model = Object.const_get(model_name)
      rescue NameError => e
        # 可能有一个 User entity，还有一个 UserDetail entity 表示更详细的信息
        namespaces = model_name.split("::")[0..-2]
        model_name = model_name.split("::")[-1]

        if model_name.match(/.*Detail$/)
          model_name = (namespaces + [model_name.slice(0..-7)]).join("::")

          model = Object.const_get(model_name)
        elsif model_name.match(/^Simple.*$/)
          model_name = (namespaces + [model_name.slice(6..-1)]).join("::")

          model = Object.const_get(model_name)
        end
      rescue StandardError => e
        # 什么都不处理
      end

      model
    end
  end
end
