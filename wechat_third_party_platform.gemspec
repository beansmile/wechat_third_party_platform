# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "wechat_third_party_platform/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "wechat_third_party_platform"
  spec.version     = WechatThirdPartyPlatform::VERSION
  spec.authors     = ["leif"]
  spec.email       = ["leif@beansmile.com"]
  spec.homepage    = "https://github.com/beansmile/wechat_third_party_platform"
  spec.summary     = "微信第三方平台接口"
  spec.description = "微信第三方平台接口"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://github.com/beansmile/wechat_third_party_platform"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.4"
  spec.add_dependency "httparty", "~> 0.18.0"

  spec.add_development_dependency "sqlite3"

end
