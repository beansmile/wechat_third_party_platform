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
  end
end
