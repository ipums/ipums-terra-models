# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'ipumsi_database'


class IpumsRegistration < IpumsiActiveRecord::Base
  self.table_name = :registrations
  self.primary_key = :id

  attr_accessor :allow_emails, :ownership, :use, :restriction, :confidentiality, :security, :appropriate_citation, :violations, :notify_errors

  validates :id, presence: true, uniqueness: true
  validates :address_line_1, :city, :state, :zip_code, :country, :country_of_origin, :phone, :approval_status, :expires_at, :last_renewed_at, presence: true
  validates :allow_emails, :ownership, :use, :restriction, :confidentiality, :security, :appropriate_citation, :violations, :notify_errors, acceptance: true
  validates :institutional_affiliation, :health_research, inclusion: {in: [true, false]}
  validates :department_id, inclusion: {in: IpumsDepartment.for_web.ids }
  validates :department_text, presence: true, if: :department_is_other?
  validates :academic_status_id, inclusion: {in: IpumsAcademicStatus.for_web.ids }
  validates :academic_status_text, presence: true, if: :academic_status_is_other?
  validates :anticipated_result_id, inclusion: {in: IpumsAnticipatedResult.for_web.ids }
  validates :anticipated_result_text, presence: true, if: :anticipated_result_is_other?
  validates :why_no_institution, presence: true, unless: :institutional_affiliation?
  validates :institution_name, presence: true, if: :institutional_affiliation?
  validates :has_safety_board, inclusion: {in: [true, false], message: "must be selected"}, if: :institutional_affiliation?
  validates :safety_board_name, presence: {message: "can't be blank if your institution have an Institutional Review Board (IRB), or Office for Human Subject Protections, Professional Conduct or similar committee"}, if: [:institutional_affiliation?, :has_safety_board?]
  validates :research_description, length: {minimum: 75, tokenizer: lambda { |str| str.split(/\s+/) }, too_short: "Research Description must have at least %{count} words"}

  STATUS = {approved: "approved", denied: "denied", pending: "pending", incomplete: "incomplete"}


  def set_default_creation_attributes
    set_as_renewed
    self.approval_status  = Rails.env.live? ? STATUS[:pending] : STATUS[:approved]
    self.max_extract_size = 20480
  end


  def set_as_renewed
    now = DateTime.now
    self.expires_at      = now + 1.year - 1.day
    self.last_renewed_at = now
  end


  def is_expired?
    expires_at.nil? || DateTime.now > expires_at
  end


  private



  def department_is_other?
    department_id.blank? and return false
    department = IpumsDepartment.find_by(id: department_id)
    !department.nil? && ['academic_other', 'nonacademic_other'].include?(department.label)
  end


  def academic_status_is_other?
    academic_status_id.blank? and return false
    academic_status = IpumsAcademicStatus.find_by(id: academic_status_id)
    !academic_status.nil? && ['other_academic_other', 'nonacademic'].include?(academic_status.label)
  end


  def anticipated_result_is_other?
    anticipated_result_id.blank? and return false
    anticipated_result = IpumsAnticipatedResult.find_by(id: anticipated_result_id)
    !anticipated_result.nil? && anticipated_result.label == 'other'
  end


end
