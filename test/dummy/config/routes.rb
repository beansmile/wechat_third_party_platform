# frozen_string_literal: true

Rails.application.routes.draw do
  get "/home", to: "home#show"
  mount WechatThirdPartyPlatform::Engine => "/wtpp"
end
