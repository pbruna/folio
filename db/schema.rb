# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120417194213) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "rut"
    t.text     "address"
    t.string   "city"
    t.string   "industry"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain"
    t.integer  "admin_id"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "default_tax_id"
  end

  add_index "accounts", ["admin_id"], :name => "altered_accounts_admin_index"
  add_index "accounts", ["default_tax_id"], :name => "index_accounts_on_default_tax_id"

  create_table "comment_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.string   "subject"
    t.text     "body"
    t.integer  "invoice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.integer  "comment_type_id"
    t.boolean  "system"
    t.string   "notify_account_users"
    t.boolean  "notify_all_account_users"
  end

  create_table "contacts", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "contacts", ["account_id"], :name => "contacts_account_index"
  add_index "contacts", ["customer_id"], :name => "contacts_customer_index"

  create_table "customers", :force => true do |t|
    t.string   "name"
    t.string   "rut"
    t.text     "address",    :default => ""
    t.string   "city",       :default => ""
    t.string   "industry",   :default => ""
    t.string   "state",      :default => ""
    t.string   "country",    :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",        :default => ""
    t.string   "phone",      :default => ""
    t.string   "fax",        :default => ""
    t.integer  "account_id"
    t.string   "alias",      :default => ""
  end

  add_index "customers", ["account_id"], :name => "altered_customers_account_index"
  add_index "customers", ["name"], :name => "altered_customers_name_index"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "documents", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "invoice_id"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "original_file_name"
  end

  add_index "documents", ["account_id"], :name => "index_documents_on_account_id"
  add_index "documents", ["invoice_id"], :name => "index_documents_on_invoice_id"
  add_index "documents", ["user_id"], :name => "index_documents_on_user_id"

  create_table "expenses", :force => true do |t|
    t.integer  "account_id"
    t.integer  "user_id"
    t.integer  "vendor_id"
    t.integer  "category"
    t.integer  "total"
    t.integer  "attachment_category"
    t.integer  "receipt"
    t.string   "attachment_subject"
    t.string   "subject"
    t.text     "comment"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.datetime "attachment_updated_at"
    t.integer  "attachment_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "due_date"
    t.integer  "status_id",               :default => 2
    t.date     "close_date"
    t.integer  "payment_method",          :default => 1
    t.string   "payment_reference"
  end

  add_index "expenses", ["account_id"], :name => "altered_expenses_account_index"
  add_index "expenses", ["category"], :name => "altered_expenses_category_index"
  add_index "expenses", ["receipt"], :name => "altered_expenses_receipt_index"
  add_index "expenses", ["status_id"], :name => "expenses_status"
  add_index "expenses", ["user_id"], :name => "altered_expenses_user_index"
  add_index "expenses", ["vendor_id"], :name => "altered_expenses_vendor_index"

  create_table "indicadores_economicos", :force => true do |t|
    t.date     "date"
    t.float    "uf"
    t.float    "dolar"
    t.float    "utm"
    t.float    "euro"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "indicadores_economicos", ["date"], :name => "indicadores_econcomicos_date_index"

  create_table "invoice_items", :force => true do |t|
    t.integer  "product_id",  :limit => 255
    t.integer  "quantity"
    t.text     "description"
    t.integer  "price"
    t.integer  "total",                      :default => 0
    t.integer  "invoice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoice_items", ["invoice_id"], :name => "iitems_invoice_index"
  add_index "invoice_items", ["product_id"], :name => "iitems_product_index"

  create_table "invoices", :force => true do |t|
    t.integer  "number"
    t.decimal  "tax",         :default => 0.0
    t.decimal  "net",         :default => 0.0
    t.decimal  "total",       :default => 0.0
    t.integer  "customer_id"
    t.integer  "contact_id"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "taxed"
    t.date     "due"
    t.integer  "status_id"
    t.integer  "history_id"
    t.text     "comment"
    t.integer  "currency_id"
    t.date     "date"
    t.date     "close_date"
    t.string   "subject"
    t.integer  "tax_id"
    t.string   "tax_name"
    t.float    "tax_rate"
  end

  add_index "invoices", ["account_id"], :name => "altered_invoices_account_index"
  add_index "invoices", ["account_id"], :name => "altered_invoices_company_index"
  add_index "invoices", ["contact_id"], :name => "altered_invoices_contact_index"
  add_index "invoices", ["currency_id"], :name => "altered_invoices_currency_index"
  add_index "invoices", ["customer_id"], :name => "altered_invoices_customer_index"
  add_index "invoices", ["history_id"], :name => "altered_invoices_history_index"
  add_index "invoices", ["number"], :name => "altered_invoices_number_index"
  add_index "invoices", ["status_id"], :name => "altered_invoices_status_index"
  add_index "invoices", ["tax_id"], :name => "index_invoices_on_tax_id"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "taxes", :force => true do |t|
    t.string   "name"
    t.float    "value",      :default => 0.0
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taxes", ["account_id"], :name => "index_taxes_on_account_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "perishable_token",    :default => "",    :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "admin",               :default => false
    t.boolean  "active",              :default => true
  end

  add_index "users", ["account_id"], :name => "altered_users_account_index"
  add_index "users", ["account_id"], :name => "altered_users_company_index"
  add_index "users", ["perishable_token"], :name => "altered_users_ptoken_index"

end
