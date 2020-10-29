# frozen_string_literal: true

module WechatThirdPartyPlatform::API
  module DataAnalysis
    [
      # 获取用户访问小程序数据概况
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/analysis.getDailySummary.html
      :getweanalysisappiddailysummarytrend,
      # 获取小程序用户画像数据
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/analysis.getUserPortrait.html
      :getweanalysisappiduserportrait,
      # 获取小程序访问分布数据
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/analysis.getVisitDistribution.html
      :getweanalysisappidvisitdistribution,
      # 获取小程序访问页面数据
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/analysis.getVisitPage.html
      :getweanalysisappidvisitpage,
      # 获取用户访问小程序日留存
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-retain/analysis.getDailyRetain.html
      :getweanalysisappiddailyretaininfo,
      # 获取用户访问小程序月留存
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-retain/analysis.getMonthlyRetain.html
      :getweanalysisappidmonthlyretaininfo,
      # 获取用户访问小程序周留存
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-retain/analysis.getWeeklyRetain.html
      :getweanalysisappidweeklyretaininfo,
      # 获取用户访问小程序数据日趋势
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-trend/analysis.getDailyVisitTrend.html
      :getweanalysisappiddailyvisittrend,
      # 获取用户访问小程序数据月趋势
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-trend/analysis.getMonthlyVisitTrend.html
      :getweanalysisappidmonthlyvisittrend,
      # 获取用户访问小程序数据周趋势
      # https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Mini_Programs/data_analysis/visit-trend/analysis.getWeeklyVisitTrend.html
      :getweanalysisappidweeklyvisittrend
    ].each do |action|
      define_method action do |begin_date:, end_date:|
        http_post("/datacube/#{action}", body: {
          begin_date: begin_date,
          end_date: end_date
        })
      end
    end
  end
end
