# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class DataAnalysis < Grape::API
    include Grape::Kaminari

    namespace "wechat_third_party_platform/data_analysis" do

      before do
        response_error("请先去授权小程序！") unless current_wechat_application_client
      end

      helpers do
        def get_data_by_method(method_name, attrs)
          response = current_wechat_application_client.public_send(method_name, attrs)
          # 没有返回errcode为0，用大于0判断错误
          response_error(response.cn_msg) if response["errcode"].to_i > 0
          response
        end

        def time_range
          if params[:range_kind]
            yesterday = Date.current.yesterday.strftime("%Y%m%d")

            case params[:range_kind]
            when "latest_1_day"
              {
                begin_date: yesterday,
                end_date: yesterday
              }
            when "latest_7_day"
              {
                begin_date: 7.days.ago.strftime("%Y%m%d"),
                end_date: yesterday
              }
            when "latest_30_day"
              {
                begin_date: 30.days.ago.strftime("%Y%m%d"),
                end_date: yesterday
              }
            end
          end
        end

        def in_one_day
          {
            begin_date: params[:date].strftime("%Y%m%d"),
            end_date: params[:date].strftime("%Y%m%d")
          }
        end

        def in_one_month
          {
            begin_date: params[:date].beginning_of_month.strftime("%Y%m%d"),
            end_date: params[:date].end_of_month.strftime("%Y%m%d")
          }
        end

        def in_one_week
          {
            begin_date: params[:date].beginning_of_week.strftime("%Y%m%d"),
            end_date: params[:date].end_of_week.strftime("%Y%m%d")
          }
        end
      end

      desc "获取用户访问小程序数据概况"
      params do
        optional :date, type: Date, desc: "查看数据时间，只能查看一天", default: Date.current.yesterday
      end
      get "daily_summary_trend" do
        authorize! :daily_summary_trend, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappiddailysummarytrend, in_one_day)

        present response
      end

      desc "获取小程序用户画像数据"
      params do
        optional :range_kind, type: String, values: ["latest_1_day", "latest_7_day", "latest_30_day"], desc: "只能查看最近1天，最近7天，最近30天", default: "latest_1_day"
      end
      get "user_portrait" do
        authorize! :user_portrait, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappiduserportrait, time_range)

        present response
      end

      desc "获取小程序访问分布数据"
      params do
        optional :date, type: Date, desc: "查看数据时间，只能查看一天", default: Date.current.yesterday
      end
      get "visit_distribution" do
        authorize! :visit_distribution, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidvisitdistribution, in_one_day)

        result = response["list"]
        result = result.map do |ele|
          [
            ele["index"],
            ele["item_list"].each do |item|
              if WechatThirdPartyPlatform::VisitDistributionData.respond_to?("#{ele["index"]}_value")
                item["name"] = WechatThirdPartyPlatform::VisitDistributionData.send("#{ele["index"]}_value", item["key"])
              end
            end
          ]
        end.to_h
        present result
      end

      desc "获取小程序访问页面数据"
      params do
        optional :begin_date, type: DateTime, desc: "限定查询7天数据", default: (Date.current - 7.days)
        optional :end_date, type: DateTime, desc: "限定查询7天数据", default: Date.current.yesterday
      end
      get "visit_page" do
        authorize! :visit_page, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidvisitpage, {
          begin_date: params[:begin_date].strftime("%Y%m%d"),
          end_date: params[:end_date].strftime("%Y%m%d")
        })

        present response["list"]
      end

      desc "获取用户访问小程序日留存"
      params do
        optional :date, type: Date, desc: "查看数据时间，只能查看一天", default: Date.current.yesterday
      end
      get "daily_retain_info" do
        authorize! :retain_info, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappiddailyretaininfo, in_one_day)

        present response
      end

      desc "获取用户访问小程序月留存"
      params do
        optional :date, type: Date, desc: "当前月任意时间查询当前月数据", default: Date.current.last_month
      end
      get "monthly_retain_info" do
        authorize! :retain_info, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidmonthlyretaininfo, in_one_month)

        present response
      end

      desc "获取用户访问小程序周留存"
      params do
        optional :date, type: Date, desc: "当前周任意时间查询当前周数据", default: Date.current.last_week
      end
      get "weekly_retain_info" do
        authorize! :retain_info, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidweeklyretaininfo, in_one_week)

        present response
      end

      desc "获取用户访问小程序数据日趋势"
      params do
        optional :date, type: Date, desc: "查看数据时间，只能查看一天", default: Date.current.yesterday
      end
      get "daily_visit_trend" do
        authorize! :visit_trend, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappiddailyvisittrend, in_one_day)

        present response["list"]
      end

      desc "获取用户访问小程序数据月趋势"
      params do
        optional :date, type: Date, desc: "当前月任意时间查询当前月数据", default: Date.current.last_month
      end
      get "monthly_visit_trend" do
        authorize! :visit_trend, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidmonthlyvisittrend, in_one_month)

        present response["list"]
      end

      desc "获取用户访问小程序数据周趋势"
      params do
        optional :date, type: Date, desc: "当前周任意时间查询当前周数据", default: Date.current.last_week
      end
      get "weekly_visit_trend" do
        authorize! :visit_trend, "DataAnalyse"

        response = get_data_by_method(:getweanalysisappidweeklyvisittrend, in_one_week)

        present response["list"]
      end
    end
  end
end
