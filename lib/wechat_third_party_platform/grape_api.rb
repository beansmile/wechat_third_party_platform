module WechatThirdPartyPlatform
  module GrapeAPI
    module DSLMethods
      def wtpp_apis(*args, &block)
        options = args.extract_options!
        actions = args.flatten

        entity_namespace = "WechatThirdPartyPlatform::GrapeAPI::Entities"
        options[:resource_class] ||= "WechatThirdPartyPlatform::#{base.name.split("::")[-1].singularize}".constantize
        options[:collection_entity] ||= "WechatThirdPartyPlatform::GrapeAPI::Entities::#{base.name.split("::")[-1].singularize}".constantize
        options[:resource_entity] ||= "WechatThirdPartyPlatform::GrapeAPI::Entities::#{base.name.split("::")[-1].singularize}Detail".constantize
        options[:namespace] ||= "wechat_third_party_platform"

        apis(*actions, options, &block)
      end
    end

    Grape::API::Instance.extend(DSLMethods)
  end
end

[
  :entities,
  :applications,
  :access_token,
  :draft_templates,
  :templates,
  :wechat_categories,
  :base,
  :testers,
  :data_analysis,
  :utils,
  :registers,
].each do |name|
  require "wechat_third_party_platform/grape_api/#{name}"
end
