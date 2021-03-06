class Invoice < ActiveRecord::Base
  acts_as_taggable
  before_create :set_as_draft
  before_save :calculate_tax

  # Associations
  belongs_to :customer
  belongs_to :contact
  belongs_to :account
  belongs_to :status
  has_many :invoice_items, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :documents, :dependent => :destroy

  # Extras
  accepts_nested_attributes_for :invoice_items, :allow_destroy => true
  #accepts_nested_attributes_for :comments, :allow_destroy => true

  # Validations
  validates_presence_of :net, :total, :customer_id, :subject, :date, :number
  validates_uniqueness_of :number, :scope => [:taxed, :account_id]

  validates_numericality_of :number, :only_integer => true, :greater_than => 0
  validates_numericality_of :net, :greater_than => 0
  validates_numericality_of :total, :greater_than => 0


  delegate :name, :state, :to => :status, :prefix => true
  delegate :name, :to => :customer, :prefix => true

  def has_tags?
    tags.map {|t| t.name}.size > 0
  end

  def ordered_tag_list
    tags.map {|t| t.name}.sort
  end

  def due_date_to_days
    ((due.to_time - date.to_time)/3600/24).to_i
  end

  def documents_reverse
    documents.reverse
  end

  def active!(user)
    unless active?
      update_attribute(:status_id, 2)
      comments.build(:subject => "Activación", :body => "Factura activada", :user_id => user.id,
                     :account_id => user.account_id, :comment_type_id => 7, :system => true)
      save
    else
      false
    end
  end

  def active?
    status_id == 2 ? true : false
  end

  def cancel!(user)
    unless cancelled?
      update_attribute(:status_id, 4)
      notify_users = last_comment_suscriptions[:users].keys.join(",")
      comments.build(:subject => "Anulación", :body => "La factura fue anulada", :user_id => user.id,
                     :account_id => user.account_id, :comment_type_id => 7, :system => true,
                     :notify_account_users => notify_users)
      save
    else
      false
    end
  end


  def cancelled?
    status_id == 4 ? true : false
  end

  def close!(user)
    unless closed?
      update_attribute(:status_id, 3)
      update_attribute(:close_date, Date.today)
      notify_users = last_comment_suscriptions[:users].keys.join(",")
      comments.build(:subject => "Pagada", :body => "Factura pagada", :user_id => user.id,
                     :account_id => user.account_id, :comment_type_id => 4, :system => true,
                     :notify_account_users => notify_users)
      save
    else
      false
    end
  end

  def closed?
    status_id == 3 ? true : false
  end

  def draft?
    status_id == 1 ? true : false
  end

  def cancellable?
    status_id == 2 || status_id == 5 ? true : false
  end

  def self.new_with_default_values
    self.new(:total => 0, :tax => 0, :net => 0)
  end

  def self.duplicate(id)
    invoice = find(id)
    invoice.date = Date.today
    invoice.number = nil
    invoice.status_id = 1
    invoice_new = invoice.clone()
    invoice_new.tag_list = invoice.tag_list
    invoice_new.invoice_items << invoice.duplicate_items
    invoice_new
  end

  def duplicate_items
    invoice_items_tmp = Array.new
    unless invoice_items.size < 0
      invoice_items.each_with_index do |line, index|
        invoice_items_tmp << line.clone()
      end
      invoice_items_tmp
    else
      false
    end
  end


  # Virtual attributes

  def tax_name
    if new_record?
      read_attribute("tax_name") || account.default_tax.name
    else
      read_attribute("tax_name") || "Impuesto"
    end
  end

  def tax_rate
    if new_record?
      read_attribute("tax_rate") || account.default_tax.value
    else
      read_attribute("tax_rate")
    end
  end

  def select_box_tax_id
    if new_record? && status_id == 1 && errors.size > 0# Check if duplicated
      return nil unless Tax.exists?(tax_id)
      tax_id
    elsif self.errors.size > 0
      return nil if tax_id.nil?
      tax_id
    elsif new_record? || taxed?
      tax_id || account.default_tax_id
    else
      nil
    end
  end

  def customer_name
    customer.name if customer
  end

  def self.find_by_status(status, eager = true)
    include_models = Array.new
    unless eager
      include_models = [:status]
    else
      include_models = [:status, :customer, :tags]
    end
    self.send("#{status}").scoped(:include => include_models)
  end

  # Arreglo con Tipos de Facturas
  @statuses = %w( draft active close due cancel )

  # Metaprocreamos metodos de totales
  @statuses.each do |v|
    method_name = ("#{v}_total").to_sym
    self.class.send(:define_method, method_name) do |account, *query|
      query = *query
      sum = 0
      if query.nil?
        invoices = self.send("#{v}").search(:account_id_equals => account).all.to_a
        sum = invoices.sum(&:total) unless invoices.size < 1
        sum
      else
        query.delete("status")
        query[:account_id_equals] = account.to_i
        result = self.send("#{v}").search(query)
        invoices = result.all
        sum = invoices.sum(&:total) unless invoices.size < 1
        sum
      end
    end
  end

  def last_comment_suscriptions
    suscriptions = {:users => {}, :all_users => false}
    unless comments.last.nil?
      begin
        comments.last.notify_account_users.split(",").each do |id|
          suscriptions[:users][id.to_i] = true
        end
        suscriptions[:all_users] = comments.last.notify_all_account_users
      rescue
        suscriptions
      end
    end
    suscriptions
  end
  
  def set_totals
    self.net = invoice_items.reject(&:marked_for_destruction?).sum(&:total)
    if self.taxed?
      self.tax = (self.net * self.tax_rate/100)
      self.total = self.net + self.tax
    else
      self.total = self.net
    end
    save
  end


  def self.totals(invoices)
    sum = 0
    sum = invoices.to_a.sum(&:total) unless invoices.size < 1
    sum
  end
  
  def self.total_per_invoice_status
    totals = Hash.new
    @statuses.each do |status|
      totals[status] = send(status).to_a.sum(&:total).to_i
    end
    totals
  end

  def self.iva_total(query = nil)
    sum = 0
    if query.nil?
      invoices = all_invoices.to_a
      sum = invoices.sum(&:tax) unless invoices.size < 1
      sum
    else
      query.delete("status")
      result = all_invoices.search(query)
      invoices = result.all
      sum = invoices.sum(&:tax) unless invoices.size < 1
      sum
    end
  end

  def self.close_index_total(account, query = nil)
    sum = 0
    if query.nil?
      sum = close_index.search(:account_id_equals => account).all.to_a.sum(&:total) unless close_index.to_a.size < 1
      sum
    else
      query.delete("status")
      query[:account_id_equals] = account.to_i
      result = close.search(query)
      invoices = result.all
      sum = invoices.sum(&:total) unless invoices.size < 1
      sum
    end
  end

  def status_id
    status_id = read_attribute(:status_id)
    due = read_attribute(:due)
    if status_id == 2 and due < Date.today
      5
    else
      status_id
    end
  end

  def state
    if self.status_id == 5
      "due"
    else
      self.status.state
    end
  end


  def due_days
    today = Time.now
    ((today - self.due.to_time)/86400).to_i
  end

  def self.due_dates
    dates = Array.new
    dates << Duedate.new(30, "30 días")
    dates << Duedate.new(45, "45 días")
    dates << Duedate.new(60, "60 días")
    dates << Duedate.new(120, "120 días")
    dates << Duedate.new(0, "Contado")
    dates
  end
  
  def self.date_filter
    dates = Array.new
    dates = [
      ["Este mes", 1.month.ago.to_date ],
      ["2 Meses", 2.month.ago.to_date ],
      ["6 Meses", 6.month.ago.to_date ]
      ]
  end
  
  def self.sorter_options(status)
    options = [["Fecha emisión", "date"], ["Número", "number"], ["Total", "total"]]
    sorter = case status
      when "active" then options.push(["Estado", "status_id"],["Fecha vencimiento", "due"]).sort
      when "due" then options.push(["Días de Atraso", "due"])
      when "close_index" then options.push(["Fecha de Pago", "close_date"])
      when "close" then options.push(["Fecha de Pago", "close_date"])
      when "cancel" then options.push(["Fecha de Anulación", "close_date"])
    end
  end
  
  def self.statuses
    @statuses
  end
  
  def self.per_page
    10
  end
  
  # Estado de Facturas
  scope_procedure :due, lambda { status_id_equals(2).due_lt(Date.today) }
  scope_procedure :active, lambda { status_id_equals(2).due_gte(Date.today) }
  scope_procedure :close, lambda { status_id_equals(3) }
  scope_procedure :close_index, lambda { status_id_equals(3).close_date_gte(1.month.ago.to_date) }
  scope_procedure :draft, lambda { status_id_equals(1) }
  scope_procedure :cancel, lambda { status_id_equals(4) }
  scope_procedure :all_invoices, lambda { number_gte(0) }
  scope_procedure :untaxed, lambda { taxed_equals(false) }
  scope_procedure :for_account, lambda {|account_id| account_id_equals(account_id) }
  scope_procedure :for_customer, lambda {|customer_id| customer_id_equals(customer_id) }
  scope_procedure :due_this_week, lambda {status_id_equals(2).due_gte(Date.today.beginning_of_week).due_lte(Date.today.end_of_week)}
  scope_procedure :date_in_between, lambda {|start_date,end_date| date_gte(start_date).date_lte(end_date)}
  scope_procedure :total_in_between, lambda {|total| total_gte(total.to_i - 1).total_lte(total.to_i + 1)}
  
  named_scope :not_draft_cancel, :conditions => ["status_id != 1 and status_id != 4"]
  
  
  private
  
  def set_as_draft
    self.status_id = 1
  end
  
  def calculate_total
    self.net = invoice_items.reject(&:marked_for_destruction?).sum(&:total)
  end
  
  def calculate_tax
    return if (status_id == 3 || status_id == 4)
    return if tax_id.nil?
    if self.taxed?
        tax_object = Tax.find(tax_id)
        self.tax_name = tax_object.name
        self.tax_rate = tax_object.value
        self.tax = (self.net * self.tax_rate/100)
        self.total = self.net + self.tax
    else
      self.tax = 0
      self.tax_name = nil
      self.tax_rate = 0
      self.tax_id = nil
    end
  end

end
