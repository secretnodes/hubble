class InitialStructure < ActiveRecord::Migration[5.2]
  def change
    enable_extension "plpgsql"
    enable_extension "btree_gin"
    enable_extension "pgcrypto"

    create_table "administrators" do |t|
      t.string "name"
      t.string "email"
      t.string "password_digest"
      t.string "otp_secret_key"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "one_time_setup_token"
    end

    create_table "alert_subscriptions" do |t|
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

    create_table "cosmos_blocks" do |t|
      t.bigint "chain_id"
      t.string "id_hash", null: false
      t.bigint "height", null: false
      t.datetime "timestamp", null: false
      t.string "precommitters", default: [], array: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "raw_block"
      t.text "raw_commit"
      t.jsonb "validator_set", default: {}
      t.index ["chain_id", "height", "timestamp"], name: "index_cosmos_b_on_c__h__t"
      t.index ["chain_id", "height"], name: "index_cosmos_b_on_c__h", unique: true
      t.index ["chain_id", "id_hash"], name: "index_cosmos_b_on_hash", unique: true
      t.index ["precommitters"], name: "index_cosmos_b_on_pc", using: :gin
    end

    create_table "cosmos_chains" do |t|
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
    end

    create_table "cosmos_faucets" do |t|
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

    create_table "cosmos_validator_event_latches" do |t|
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

    create_table "cosmos_validator_events" do |t|
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

    create_table "cosmos_validators" do |t|
      t.bigint "chain_id"
      t.string "address", null: false
      t.integer "current_voting_power"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "latest_block_height"
      t.jsonb "info", default: {}
      t.datetime "first_seen_at"
      t.bigint "total_precommits", default: 0
      t.index ["address"], name: "index_cosmos_v_on_addr"
      t.index ["chain_id", "address"], name: "index_cosmos_v_on_c__addr", unique: true
      t.index ["chain_id"], name: "index_cosmos_v_on_c"
    end

    create_table "stats_average_snapshots" do |t|
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

    create_table "stats_daily_sync_logs" do |t|
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

    create_table "stats_faucet_transactions", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
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

    create_table "stats_sync_logs" do |t|
      t.bigint "chain_id"
      t.datetime "started_at"
      t.datetime "completed_at"
      t.bigint "start_height"
      t.bigint "end_height"
      t.datetime "failed_at"
      t.text "error"
      t.index ["chain_id"], name: "index_stats_sync_logs_on_chain_id"
    end

    create_table "users" do |t|
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
    add_foreign_key "cosmos_validators", "cosmos_chains", column: "chain_id"
  end
end
