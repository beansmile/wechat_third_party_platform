# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_24_022202) do

  create_table "wechat_third_party_platform_submitions", force: :cascade do |t|
    t.string "template_id"
    t.json "ext_json", default: {}
    t.json "audlt_result", default: {}
    t.string "user_version"
    t.string "user_desc"
    t.integer "state", default: 0
    t.integer "application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["application_id"], name: "index_wechat_third_party_platform_submitions_on_application_id"
    t.index ["template_id"], name: "index_wechat_third_party_platform_submitions_on_template_id"
  end

  create_table "wechat_third_party_platform_templates", force: :cascade do |t|
    t.string "template_id"
    t.string "user_version"
    t.string "user_desc"
    t.integer "draft_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "wechat_third_party_platform_testers", force: :cascade do |t|
    t.string "wechat_id"
    t.string "userstr"
    t.integer "application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["application_id"], name: "index_wechat_third_party_platform_testers_on_application_id"
  end

end
