# WechatThirdPartyPlatform
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'wechat_third_party_platform'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install wechat_third_party_platform
```

## Usage
### Config
Create config/initializers/wechat_third_party_platform.rb and put following configurations into it.

```
# required
//登录授权的发起页域名需要跟在第三方平台配置域名一致
WechatThirdPartyPlatform.auth_redirect_url = 'http://xifengzhu.ngrok.io/wtpp/wechat/auth_callback'
WechatThirdPartyPlatform.component_appid = 'wxxxxxx'
WechatThirdPartyPlatform.component_appsecret = 'xxxxxxxxxxx'
// 消息校验Token
WechatThirdPartyPlatform.message_token = 'xxxxxx'
// 消息加解密Key
WechatThirdPartyPlatform.message_key = 'xxxxxx'
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
