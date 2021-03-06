class Account < ActiveRecord::Base
  acts_as_tagger
  
  # Filters
  before_validation :downcase_subdomain
  after_save :add_admin, :if => :admin_null?
  before_save :randomize_file_name

  # Associations
  authenticates_many :user_sessions
  has_many :invoices, :dependent => :destroy
  has_many :users, :uniq => true, :dependent => :destroy
  accepts_nested_attributes_for :users
  has_many :customers, :dependent => :destroy
  has_many :contacts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :documents, :dependent => :destroy
  has_many :taxes, :dependent => :destroy
  has_many :open_invoice_items, :source => :invoice_items ,:through => :invoices, :conditions => ["status_id = ?", 2]
  has_many :invoice_items, :through => :invoices, :conditions => ["status_id != ?", 4]
  alias_attribute :user_id, :admin_id

  # Validations
  validates_presence_of :name, :subdomain
  validates_presence_of :rut, :on => :update
  validates_uniqueness_of :subdomain, :case_sensitive => false
  validates_format_of :subdomain, :with => /^[\w\d]+$/, :on => :create
  
  has_attached_file :avatar,
    :url => "/images/uploads/accounts/avatars/:id/:style/:basename.:extension",
    :path => ":rails_root/public/images/uploads/accounts/avatars/:id/:style/:basename.:extension",
    :styles => {:medium => "100x100>", :thumb => "48x48"}

  def deliver_welcome_email!(password = nil)
    user = User.find(self.admin_id)
    UserMailer.deliver_welcome_email(user, self, password)
  end
  
  def have_logo?
    !self.avatar_file_name.blank?
  end
  
  def logo_url
    avatar.url
  end
  
  def have_invoices?
    self.invoices.size > 0 ? true : false
  end
  
  def have_customers?
    self.customers.size > 0 ? true : false
  end
  
  def invoice_tags
    invoices.tag_counts.map {|t| t.name}.sort
  end
  
  def has_invoice_tags?
    invoice_tags.size > 0
  end
  
  def has_invoices?
    invoices.for_account(self.id).size > 0
  end
  
  def has_taxes?
    taxes.size > 0
  end
  
  def default_tax_id
    read_attribute("default_tax_id") || nil
  end
  
  def default_tax
    begin
      tax = Tax.find(self.default_tax_id)
    rescue Exception => e
      Tax.new(:name => "", :value => 0)
    end
  end
  
  def invoices_due_this_week
    invoices.due_this_week.to_a
  end
  
  def total_this_year
    sum_invoices(sales.to_a)
  end
  
  def sales
    invoices.not_draft_cancel.date_in_between(Date.parse("01/01/#{Date.today.year}"),Date.today)
  end
  
  def total_last_year
    sales = invoices.not_draft_cancel.date_in_between(Date.parse("01/01/#{Date.today.year-1}"),Date.today.years_ago(1))
    sum_invoices(sales.to_a)
  end
  
  def active_users
    users.active
  end
  
  def monthly_sales_agregate(months_ago = 12)
    months = Tools::last_months_from_today(months_ago)
    results = Array.new
    months.each do |m|
      start_date = m.beginning_of_month
      end_date = m.end_of_month
      commodity_sales = total_of_commodities_between_dates(start_date, end_date)
      service_sales = total_of_services_between_dates(start_date, end_date)
      month_sales = invoices.not_draft_cancel.sum(:total, :conditions => {:date => (start_date..end_date)})
      tax_difference = month_sales - (commodity_sales + service_sales)
      results << {
        :month => m,
        :month_sales => month_sales,
        :commodity_sales => commodity_sales,
        :service_sales => service_sales,
        :tax_difference => tax_difference
                }
    end
    results
  end
  
  def segregate_totals
    
  end
  
  def total_amount_of_commodity_for_open_invoices
    open_invoice_items.commodity.sum(:total)
  end
  
  def total_amount_of_service_for_open_invoices
    open_invoice_items.service.sum(:total)
  end
  
  def total_of_services_between_dates(date_start = Date.today.at_beginning_of_year, date_end = Date.today.at_end_of_year)
    sales = invoices.not_draft_cancel.date_in_between(date_start, date_end)
    sales.map {|i| i.invoice_items}.flatten.reject {|item| item.commodity?}.map{|i| i.total}.sum()
  end
  
  def total_of_commodities_between_dates(date_start = Date.today.at_beginning_of_year, date_end = Date.today.at_end_of_year)
    sales = invoices.not_draft_cancel.date_in_between(date_start, date_end)
    sales.map {|i| i.invoice_items}.flatten.reject {|item| item.service?}.map{|i| i.total}.sum()
  end
 
  private
  def randomize_file_name
    return if avatar_file_name.nil?
    extension = File.extname(avatar_file_name).downcase
    if avatar_file_name_changed?
      self.avatar.instance_write(:file_name, "#{ActiveSupport::SecureRandom.hex(16)}#{extension}")
    end
  end

  protected

    def sum_invoices(array)
      sum = 0
      sum = array.sum(&:total) unless array.size < 1
      sum
    end

    def admin_null?
      true if self.admin_id.nil?
    end

    def downcase_subdomain
      self.subdomain.downcase! if attribute_present?("subdomain")
    end

    def add_admin
      self.update_attribute(:admin_id, self.users.first.id)
    end

end
