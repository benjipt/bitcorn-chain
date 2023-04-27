# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_04_27_010302) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", primary_key: "address", id: { type: :string, limit: 255 }, force: :cascade do |t|
    t.bigint "cornlet_balance", default: 0, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.check_constraint "cornlet_balance >= 0", name: "valid_balance"
  end

  create_table "transactions", id: :serial, force: :cascade do |t|
    t.string "from_address", limit: 255, null: false
    t.string "to_address", limit: 255, null: false
    t.integer "cornlet_amount", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.check_constraint "cornlet_amount > 0", name: "valid_amount"
  end

  add_foreign_key "transactions", "addresses", column: "from_address", primary_key: "address", name: "transactions_from_address_fkey"
  add_foreign_key "transactions", "addresses", column: "to_address", primary_key: "address", name: "transactions_to_address_fkey"
end
