# frozen_string_literal: true
module WechatThirdPartyPlatform::GrapeAPI
  class Applications < Grape::API
    include Grape::Kaminari

    wtpp_apis :index, :show do
      helpers do
        params :index_params do
          optional :appid_cont
          optional :principal_name_cont
        end
      end

      route_param :id do
        desc "上传代码"
        params do
          requires :template_id
          requires :user_desc
          requires :user_version
        end
        post :commit do
          authorize_and_run_member_action(:commit, {}, resource_params)
        end

        desc "上传最新版本代码"
        post :commit_latest_template do
          authorize_and_run_member_action(:commit_latest_template, { auth_action: :commit })
        end

        desc "提交审核"
        params do
          optional :auto_release, type: Boolean, default: false
        end
        post :submit_audit do
          authorize_and_run_member_action(:submit_audit, {}, auto_release: params[:auto_release])
        end

        desc "发布"
        post :release do
          authorize_and_run_member_action(:release)
        end

        unless Rails.env.production?
          desc "模拟提交审核"
          post :mock_submit_audit do
            authorize! :submit_audit, resource

            resource.update(audit_submition: WechatThirdPartyPlatform::Submition.create(resource.trial_submition.dup.attributes.merge("auditid" => Time.current.to_i)))

            response_resource
          end

          desc "模拟审核通过"
          post :mock_audit_success do
            authorize! :submit_audit, resource

            audit_result = {
              "ToUserName" => "gh_fb9688c2a4b2",
              "FromUserName" => "od1P50M-fNQI5Gcq-trm4a7apsU8",
              "CreateTime" => "1488856741",
              "MsgType" => "event",
              "Event" => "weapp_audit_success",
              "SuccTime" => "1488856741"
            }

            resource.audit_submition.update(audit_result: audit_result, state: :success)

            response_resource
          end

          desc "模拟审核不通过"
          post :mock_audit_fail do
            authorize! :submit_audit, resource

            audit_result = {
              "ToUserName" => "gh_fb9688c2a4b2",
              "FromUserName" => "od1P50M-fNQI5Gcq-trm4a7apsU8",
              "CreateTime" => "1488856591",
              "MsgType" => "event",
              "Event" => "weapp_audit_fail",
              "Reason" => "1:账号信息不符合规范:<br>(1):包含色情因素<br>2:服务类目\"金融业-保险_\"与你提交代码审核时设置的功能页面内容不一致:<br>(1):功能页面设置的部分标签不属于所选的服务类目范围。<br>(2):功能页面设置的部分标签与该页面内容不相关。<br>",
              "FailTime" => "1488856591",
              "ScreenShot" => "xxx|yyy|zzz"
            }

            resource.audit_submition.update(audit_result: audit_result, state: :fail)

            response_resource
          end

          desc "模拟审核延后"
          post :mock_audit_delay do
            authorize! :submit_audit, resource

            audit_result = {
              "ToUserName" => "gh_fb9688c2a4b2",
              "FromUserName" => "od1P50M-fNQI5Gcq-trm4a7apsU8",
              "CreateTime" => "1488856591",
              "MsgType" => "event",
              "Event" => "weapp_audit_delay",
              "Reason" => "为了更好的服务小程序，您的服务商正在进行提审系统的优化，可能会导致审核时效的增长，请耐心等待",
              "DelayTime" => "1488856591"
            }

            resource.audit_submition.update(audit_result: audit_result, state: :delay)

            response_resource
          end

          desc "模拟发布"
          post :mock_release do
            authorize! :submit_audit, resource

            resource.update(online_submition: resource.audit_submition, audit_submition: nil)

            response_resource
          end
        end

        desc "同步小程序基本信息"
        post :aynch_base_data do
          authorize! :update, resource

          resource.enqueue_set_base_data
          response_success
        end
      end
    end
  end
end
