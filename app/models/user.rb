# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class User < ActiveRecord::Base


  store_accessor :data

  belongs_to :user_role
  has_many :extract_requests, dependent: :destroy

  attr_accessor :password

  validates :firstname, :lastname, presence: true
  validates :email, uniqueness: {case_sensitive: false}, format: {with: /\A[^@]+@[^@]+\.[^@]+\z/}

  validates :opt_in, :no_fees, :cite, :send_copy, :data_only, :good_not_evil, presence: true, on: :create
  validates :password, confirmation: true, length: {minimum: 8}, on: :create
  validates :password_confirmation, presence: true, on: :create

  validates :opt_in, :no_fees, :cite, :send_copy, :data_only, :good_not_evil, presence: true, on: :update, if: :has_invalid_agreement?


  def self.dump_all
    {
      'bare_users' => self.all.map { |user|
        user.attributes.delete_if { |attrb| attrb == 'id' }.map { |attrb, value|
          if attrb != 'user_role_id'
            {attrb => value}
          else
            {'user_role_id' => UserRole.find(value).role}
          end
        }.reduce({}, :merge)
      }
    }
  end


  def to_s
    "id: #{id.nil? ? '<not set>' : id}, email: #{email.nil? ? '<not set>' : email}, microdata_access_allowed: #{microdata_access_is_approved?}"
  end


  def firstname_lastname
    [firstname, lastname].reject(&:blank?).join(' ')
  end


  def owner_info(without_id = false)
    if without_id
      "#{firstname} #{lastname} <#{email}>"
    else
      "User[#{id}]: #{firstname} #{lastname} <#{email}>"
    end
  end


  def is_admin?
    admin_role = UserRole.find_by(role: :ADMIN)
    if admin_role.nil?
      false
    else
      user_role.id == admin_role.id
    end
  end


  def toggle_admin!
    if is_admin?
      set_user_role(:USER)
    else
      set_user_role(:ADMIN)
    end
    save
  end


  def ongoing_extract_requests
    extract_requests.joins(:extract_statuses).where(extract_statuses: {status: %w[completed enqueued processing email_sent]})
  end


  def get_ipumsi_user
    IpumsUser.find_by(email: self.email)
  end


  def set_ipumsi_authentication
    srand
    self.ipumsi_salt = Digest::SHA1.hexdigest(rand.to_s)
    self.ipumsi_crypted_password = Digest::SHA1.hexdigest("#{self.password}:YOURCHOICEOFWORDHERE:#{self.ipumsi_salt}")
  end


  def ipumsi_authentication_valid?
    !(self.ipumsi_salt.blank? || self.ipumsi_crypted_password.blank?)
  end


  def normalize_attributes
    self.firstname.strip!
    self.lastname.strip!
    self.email.strip!
    self.email.downcase!
    set_user_role(:USER) if self.user_role.nil?
    set_api_key if self.api_key.nil?
  end


  def set_user_role(role)
    self.user_role = UserRole.find_by(role: role)
  end


  def set_api_key
    hash = OpenSSL::Digest::SHA256.new
    salt = SecureRandom.random_bytes(hash.new.block_length)
    self.api_key = OpenSSL::HMAC.new(salt, hash).to_s
  end


  def has_valid_agreement?
    !!(self.opt_in && self.no_fees && self.cite && self.send_copy && self.data_only && self.good_not_evil)
  end


  def has_invalid_agreement?
    !has_valid_agreement?
  end


  def has_microdata_access?
    ipumsi_user = get_ipumsi_user
    !ipumsi_user.nil? && !ipumsi_user.get_ipumsi_registration.nil?
  end


  def microdata_access_is_denied?
    microdata_access_status == IpumsRegistration::STATUS[:denied]
  end


  def microdata_access_is_pending?
    microdata_access_status == IpumsRegistration::STATUS[:pending]
  end


  def microdata_access_is_incomplete?
    microdata_access_status == IpumsRegistration::STATUS[:incomplete]
  end


  def microdata_access_is_approved?
    !microdata_access_is_expired? && microdata_access_status == IpumsRegistration::STATUS[:approved]
  end


  def microdata_access_is_expired?
    ipumsi_user = get_ipumsi_user
    ipumsi_user.nil? and return true
    ipums_registration = ipumsi_user.get_ipumsi_registration
    ipums_registration.nil? ? true : ipums_registration.is_expired?
  end


  def microdata_access_expiration_date
    ipumsi_user = get_ipumsi_user
    ipumsi_user.nil? and return nil
    ipums_registration = ipumsi_user.get_ipumsi_registration
    ipums_registration.nil? ? nil : ipums_registration.expires_at
  end


  def fix_ipumsi_registration
    return if microdata_access_requested.nil?
    if !has_microdata_access? && microdata_access_requested && microdata_access_allowed
      ipumsi_user = get_ipumsi_user
      registration_data = {
        id: ipumsi_user.id,
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        address_line_3: address_line_3,
        city: city,
        state: state,
        zip_code: postal_code,
        country: registration_country,
        country_of_origin: country_of_origin,
        phone: personal_phone,
        department_id: fix_ipumsi_department_id(),
        academic_status_id: fix_ipumsi_academic_status_id(),
        anticipated_result_id: fix_ipumsi_anticipated_result_id(),
        institutional_affiliation: institutional_affiliation,
        why_no_institution: explain_no_affiliation,
        institution_name: institution,
        user_email_at_institution: inst_email,
        institution_url: inst_web,
        institution_email: inst_boss,
        institution_phone: inst_phone,
        has_safety_board: has_ethics,
        safety_board_name: ethical_board,
        research_description: research_description,
        health_research: health_research,
        research_funding_source: funder
      }
      ipums_registration = IpumsRegistration.new(registration_data)
      ipums_registration.set_default_creation_attributes
      ipums_registration.save(validate: false)
    end
    reset_microdata_access_info
  end



  private


  def microdata_access_status
    ipumsi_user = get_ipumsi_user
    ipumsi_user.nil? and return nil
    ipums_registration = ipumsi_user.get_ipumsi_registration
    ipums_registration.nil? ? nil : ipums_registration.approval_status
  end


  def fix_ipumsi_department_id
    return nil if field.nil?
    ipumsi_department = IpumsDepartment.find_by(label: ["academic_#{field}", field.split('_').reverse.join('_')])
    ipumsi_department.nil? ? nil : ipumsi_department.id
  end


  def fix_ipumsi_academic_status_id
    return nil if academic_status.nil?
    ipumsi_academic_status = IpumsAcademicStatus.find_by(web_text: [academic_status.split('_').first.capitalize, "#{academic_status.split('_').first.capitalize} #{academic_status.split('_').last}", "#{academic_status.split('_').first.capitalize}, #{academic_status.split('_').last}"])
    ipumsi_academic_status.nil? ? nil : ipumsi_academic_status.id
  end


  def fix_ipumsi_anticipated_result_id
    return nil if research_type.nil?
    ipumsi_research_type = IpumsAnticipatedResult.find_by(label: research_type) || IpumsAnticipatedResult.find_by(web_text: ["#{research_type.split('_').first.capitalize}, #{research_type.split('_').last}"]) || IpumsAnticipatedResult.find_by("web_text LIKE '#{research_type.split('_').first.capitalize}%'")
    ipumsi_research_type.nil? ? nil : ipumsi_research_type.id
  end


  def reset_microdata_access_info
    assign_attributes(Hash[ [
      :microdata_access_allowed, :microdata_access_requested,
      :microdata_access_requested_date, :microdata_access_approved_date,
      :ipumsi_user_id, :address_line_1, :address_line_2, :address_line_3,
      :city, :state, :postal_code, :registration_country, :country_of_origin,
      :personal_phone, :explain_no_affiliation, :institution, :inst_email,
      :inst_web, :inst_boss, :inst_address_line_1, :inst_address_line_2,
      :inst_address_line_3, :inst_city, :inst_state, :inst_postal_code,
      :inst_registration_country, :inst_phone, :has_ethics, :ethical_board,
      :field, :academic_status, :research_type, :research_description,
      :health_research, :funder, :no_redistribution, :learning_only,
      :non_commercial, :confidentiality, :secure_data, :scholarly_publication,
      :discipline, :ipumsi_request_email_sent_at, :institutional_affiliation,
      :microdata_access_expired_date
    ].product([nil]) ])
    save(validate: false)
  end


end
