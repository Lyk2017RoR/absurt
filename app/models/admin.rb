# == Schema Information
#
# Table name: admins
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  name                   :string
#  surname                :string
#  is_active              :boolean
#  time_zone              :string
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

class Admin < ActiveRecord::Base
  # Virtual attributes
  attr_accessor :is_generated_password

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :async,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  # Helpers
  audited except: [:password]

  # Validations
  validates_presence_of :name, :email, :surname
  validates :email, uniqueness: true

  # Callbacks
  after_commit :send_login_info, on: :create
  before_validation :create_password, on: :create
  after_initialize do |obj|
    obj.is_generated_password = false
  end

  def active_for_authentication?
    super && self.is_active
  end

  def full_name
    "#{self.name} #{self.surname}"
  end

  private

  def create_password
    if self.password.nil?
      password                    = Devise.friendly_token.first(8)
      self.password               = password
      self.password_confirmation  = password
      self.is_generated_password  = true
    end
  end

  def send_login_info
    AdminMailer.login_info(self.id, self.password).deliver_later! if self.is_generated_password
  end

end
