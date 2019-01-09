# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_21_201348) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "otp_secret_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_time_setup_token"
  end

  create_table "alert_subscriptions", force: :cascade do |t|
    t.string "alertable_type", null: false
    t.bigint "alertable_id", null: false
    t.bigint "user_id", null: false
    t.string "event_kinds", default: [], array: true
    t.boolean "wants_daily_digest", default: false
    t.datetime "last_instant_at"
    t.datetime "last_daily_at"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "instant_count", default: 0
    t.integer "daily_count", default: 0
    t.index ["alertable_type", "alertable_id"], name: "index_alert_subscriptions_on_alertable_type_and_alertable_id"
    t.index ["user_id", "alertable_type", "alertable_id"], name: "index_alerts_u_a"
    t.index ["user_id"], name: "index_alert_subscriptions_on_user_id"
  end

  create_table "cosmos_accounts", force: :cascade do |t|
    t.string "address"
    t.bigint "chain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "validator_id"
    t.index ["address"], name: "index_cosmos_accounts_on_address"
    t.index ["chain_id"], name: "index_cosmos_account_on_chain"
  end

  create_table "cosmos_blocks", force: :cascade do |t|
    t.bigint "chain_id"
    t.string "id_hash", null: false
    t.bigint "height", null: false
    t.datetime "timestamp", null: false
    t.string "precommitters", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "validator_set", default: {}
    t.string "proposer_address"
    t.string "transactions", array: true
    t.index ["chain_id", "height", "timestamp"], name: "index_cosmos_b_on_c__h__t"
    t.index ["chain_id", "height"], name: "index_cosmos_b_on_c__h", unique: true
    t.index ["chain_id", "id_hash"], name: "index_cosmos_b_on_hash", unique: true
    t.index ["precommitters"], name: "index_cosmos_b_on_pc", using: :gin
  end

  create_table "cosmos_chains", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "testnet", null: false
    t.bigint "history_height", default: 0
    t.datetime "last_sync_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "primary", default: false
    t.string "slug", null: false
    t.string "gaiad_host"
    t.integer "rpc_port"
    t.integer "lcd_port"
    t.boolean "disabled", default: false
    t.jsonb "validator_event_defs", default: [{"kind"=>"voting_power_change", "height"=>0}, {"kind"=>"active_set_inclusion", "height"=>0}]
    t.integer "failed_sync_count", default: 0
    t.jsonb "governance", default: {}, null: false
    t.string "ext_id"
    t.datetime "halted_at"
    t.string "last_round_state", default: ""
    t.string "token_denom", default: "atom"
    t.bigint "token_factor", default: 0
  end

  create_table "cosmos_faucets", force: :cascade do |t|
    t.bigint "chain_id"
    t.boolean "disabled", default: false
    t.string "key_name", null: false
    t.string "address", null: false
    t.string "encrypted_password", null: false
    t.string "encrypted_password_iv", null: false
    t.integer "delay", default: 86400
    t.jsonb "tokens", default: {}
    t.string "account_number"
    t.string "current_sequence"
    t.index ["chain_id"], name: "index_cosmos_faucets_on_chain_id"
  end

  create_table "cosmos_governance_deposits", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "proposal_id"
    t.string "amount_denom"
    t.bigint "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_cosmos_deposit_on_account"
    t.index ["proposal_id"], name: "index_cosmos_deposit_on_proposal"
  end

  create_table "cosmos_governance_proposals", force: :cascade do |t|
    t.bigint "chain_id"
    t.bigint "chain_proposal_id"
    t.string "title"
    t.text "description"
    t.string "proposal_type"
    t.string "proposal_status"
    t.decimal "tally_result_yes"
    t.decimal "tally_result_abstain"
    t.decimal "tally_result_no"
    t.decimal "tally_result_nowithveto"
    t.datetime "submit_time"
    t.jsonb "total_deposit", default: {}
    t.datetime "voting_start_time"
    t.datetime "voting_end_time"
    t.bigint "cosmos_chain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id", "chain_proposal_id"], name: "index_cosmos_governance_proposals_on_chain_and_cp_id", unique: true
    t.index ["chain_id"], name: "index_cosmos_proposal_on_chain"
    t.index ["chain_proposal_id"], name: "index_cosmos_governance_proposals_on_chain_proposal_id"
    t.index ["cosmos_chain_id"], name: "index_cosmos_governance_proposals_on_cosmos_chain_id"
    t.index ["proposal_status"], name: "index_cosmos_governance_proposals_on_proposal_status"
    t.index ["proposal_type"], name: "index_cosmos_governance_proposals_on_proposal_type"
    t.index ["submit_time"], name: "index_cosmos_governance_proposals_on_submit_time"
    t.index ["voting_end_time"], name: "index_cosmos_governance_proposals_on_voting_end_time"
    t.index ["voting_start_time"], name: "index_cosmos_governance_proposals_on_voting_start_time"
  end

  create_table "cosmos_governance_votes", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "proposal_id"
    t.string "option"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_cosmos_vote_on_account"
    t.index ["proposal_id"], name: "index_cosmos_vote_on_proposal"
  end

  create_table "cosmos_validator_event_latches", force: :cascade do |t|
    t.bigint "chain_id"
    t.bigint "validator_id"
    t.string "event_definition_id"
    t.binary "state"
    t.boolean "held", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id", "validator_id", "event_definition_id"], name: "index_cosmos_vel_all"
    t.index ["chain_id"], name: "index_cosmos_validator_event_latches_on_chain_id"
    t.index ["validator_id"], name: "index_cosmos_validator_event_latches_on_validator_id"
  end

  create_table "cosmos_validator_events", force: :cascade do |t|
    t.string "type"
    t.datetime "timestamp"
    t.bigint "height"
    t.bigint "chain_id"
    t.bigint "validator_id"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "event_definition_id"
    t.index ["chain_id"], name: "index_cosmos_validator_events_on_chain_id"
    t.index ["type"], name: "index_cosmos_validator_events_on_type"
    t.index ["validator_id"], name: "index_cosmos_validator_events_on_validator_id"
  end

  create_table "cosmos_validators", force: :cascade do |t|
    t.bigint "chain_id"
    t.string "address", null: false
    t.bigint "current_voting_power", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "latest_block_height"
    t.jsonb "info", default: {}
    t.datetime "first_seen_at"
    t.bigint "total_precommits", default: 0
    t.decimal "current_uptime", default: "0.0"
    t.bigint "total_proposals", default: 0
    t.index ["address"], name: "index_cosmos_v_on_addr"
    t.index ["chain_id", "address"], name: "index_cosmos_v_on_c__addr", unique: true
    t.index ["chain_id"], name: "index_cosmos_v_on_c"
  end

  create_table "stats_average_snapshots", force: :cascade do |t|
    t.datetime "timestamp", null: false
    t.string "interval", null: false
    t.decimal "sum", null: false
    t.decimal "count", null: false
    t.string "kind", null: false
    t.string "scopeable_type"
    t.bigint "scopeable_id"
    t.bigint "chain_id"
    t.index ["chain_id", "interval", "kind", "scopeable_id", "scopeable_type"], name: "index_avg_c__i__k__s"
    t.index ["chain_id", "interval", "kind"], name: "index_avg_c__i__k"
    t.index ["timestamp"], name: "index_stats_average_snapshots_on_timestamp"
  end

  create_table "stats_daily_sync_logs", force: :cascade do |t|
    t.bigint "chain_id"
    t.datetime "date"
    t.integer "sync_count"
    t.decimal "total_sync_time"
    t.integer "fail_count"
    t.bigint "start_height"
    t.bigint "end_height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id"], name: "index_daily_sync_chain"
  end

  create_table "stats_faucet_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "faucet_id"
    t.bigint "user_id"
    t.string "ip", null: false
    t.string "address", null: false
    t.decimal "amount", null: false
    t.string "denomination", null: false
    t.datetime "created_at", null: false
    t.datetime "completed_at"
    t.jsonb "result_data"
    t.index ["faucet_id"], name: "index_stats_faucet_transactions_on_faucet_id"
    t.index ["user_id", "ip", "address"], name: "index_stats_faucet_transactions_on_user_id_and_ip_and_address"
    t.index ["user_id"], name: "index_stats_faucet_transactions_on_user_id"
  end

  create_table "stats_sync_logs", force: :cascade do |t|
    t.bigint "chain_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.bigint "start_height"
    t.bigint "end_height"
    t.datetime "failed_at"
    t.text "error"
    t.string "current_status"
    t.index ["chain_id"], name: "index_stats_sync_logs_on_chain_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "password_reset_token"
    t.boolean "deleted", default: false
    t.datetime "last_login_at"
    t.datetime "last_seen_at"
    t.string "ip_addresses", array: true
    t.string "user_agents", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "verification_token"
  end

  add_foreign_key "cosmos_blocks", "cosmos_chains", column: "chain_id"
  add_foreign_key "cosmos_governance_proposals", "cosmos_chains"
  add_foreign_key "cosmos_validators", "cosmos_chains", column: "chain_id"
end
