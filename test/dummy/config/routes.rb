Rails.application.routes.draw do
  get '/home', to: 'home#show'
  mount WechatThirdPartyPlatform::Engine => "/wtpp"
end
