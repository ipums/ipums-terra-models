# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'etc'

require 'fileutils'
require 'extract_type'
require 'chronic_duration'

class ExtractRequest < ActiveRecord::Base
  include ActiveModel::Validations

  class ExtractTypeConst
    # see data/static_data.yml for the available status_definitions
    # [:RASTER, :AREA, :UNKNOWN, :MICRODATA]

    #def self.const_missing(name)
      #abort("Unable to find [#{name.to_s}]")
    #end

    def self.define_consts
      @@extract_types = ExtractType.all
      # magic constant injections!
      @@extract_types.each do |extract_type|
        label = extract_type.label
        raise "Your database maybe in an unknown state; ExtractType's label is nil" if label.nil?
        label = label.downcase.gsub(/ /, '_')
        self.const_set(label.upcase, label)
        parent.scope(label, -> { parent.where(status: label) })
      end
    end


    def self.const_missing(name)
      name.downcase.to_s
    end

  end


  class NewuiExtractValidator < ActiveModel::Validator

    def validate(record)
      record.errors[:base] << 'Undefined User' if record.user_unique_id.blank?
      record.errors[:base] << 'Undefined Extract' if record.data.blank?
      record.errors[:base] << 'Unknown Extract Type' if record.data["type"].blank?
      record.errors[:base] << 'Wrong Extract Type' unless ["arealevel", "microdata", "raster"].include?(record.data["type"])
      record.errors[:base] << 'Unknown Extract Title' if record.data["title"].blank?
      record.errors[:base] << "Wrong value in 'Include boundary files'" unless !!record.data["boundary"] == record.data["boundary"]
      record.errors[:base] << "Wrong value in 'Send Extract to data grid'" unless !!record.data["datagrid"] == record.data["datagrid"]
      case record.data["type"]
      when "arealevel"
        validate_arealevel(record)
      when "microdata"
        validate_microdata(record)
      when "raster"
        validate_raster(record)
      end
    end


    private

    def validate_arealevel(record)
      if record.data["arealevel_variables"].empty? && record.data["arealevel_datasets"].empty?
        record.errors[:base] << "'Georgraphic Level' for 'Area-Level Data' shouldn't be here" unless record.data["arealevel_geographic_levels"].empty?
        if record.data["raster_variables"].empty? && record.data["raster_datasets"].empty?
          record.errors[:base] << "Both 'Area-Level Data' and 'Raster Data' are empty"
        else
          record.errors[:base] << "Missing 'Georgraphic Level' for 'Raster Data'" if record.data["raster_geographic_levels"].empty?
          record.errors[:base] << "Missing 'Operations' for 'Raster Data'" if record.data["raster_operations"].empty?
        end
      else
        record.errors[:base] << "Missing 'Georgraphic Level' for 'Area-Level Data'" if record.data["arealevel_geographic_levels"].empty?
        record.errors[:base] << "'Georgraphic Level' for 'Raster Data' shouldn't be here" unless record.data["raster_geographic_levels"].empty?
        record.errors[:base] << "Missing 'Operations' for 'Raster Data'" if !(record.data["raster_variables"].empty? || record.data["raster_datasets"].empty?) && record.data["raster_operations"].empty?
      end
    end


    def validate_microdata(record)
      record.errors[:base] << "'Microdata Data' is empty" if record.data["microdata_variables"].empty? || record.data["microdata_datasets"].empty?
      if record.data["arealevel_variables"].empty? && record.data["arealevel_datasets"].empty?
        record.errors[:base] << "'Georgraphic Level' for 'Area-Level Data' shouldn't be here" unless record.data["arealevel_geographic_levels"].empty?
        if record.data["raster_variables"].empty? && record.data["raster_datasets"].empty?
          record.errors[:base] << "'Georgraphic Level' for 'Raster Data' shouldn't be here" unless record.data["raster_geographic_levels"].empty?
        else
          record.errors[:base] << "Missing 'Georgraphic Level' for 'Raster Data'" if record.data["raster_geographic_levels"].empty?
          record.errors[:base] << "Missing 'Operations' for 'Raster Data'" if record.data["raster_operations"].empty?
        end
      else
        record.errors[:base] << "Missing 'Georgraphic Level' for 'Area-Level Data'" if record.data["arealevel_geographic_levels"].empty?
        record.errors[:base] << "'Georgraphic Level' for 'Raster Data' shouldn't be here" unless record.data["raster_geographic_levels"].empty?
        record.errors[:base] << "Missing 'Operations' for 'Raster Data'" if !(record.data["raster_variables"].empty? || record.data["raster_datasets"].empty?) && record.data["raster_operations"].empty?
      end
    end


    def validate_raster(record)
      if record.data["arealevel_variables"].empty? && record.data["arealevel_datasets"].empty?
        if record.data["raster_variables"].empty? && record.data["raster_datasets"].empty?
          record.errors[:base] << "Both 'Area-Level Data' and 'Raster Data' are empty"
        else
          record.errors[:base] << "Missing 'Raster Country' for 'Raster Data'" if record.data["raster_countries"].empty?
        end
      else
        record.errors[:base] << "Missing 'Raster Country' for 'Raster Data'" if !(record.data["raster_variables"].empty? || record.data["raster_datasets"].empty?) && record.data["raster_countries"].empty?
      end
    end

  end


  has_many :extract_statuses, dependent: :destroy
  has_many :extract_request_submissions, dependent: :destroy
  # For creating the request incrementally and for reporting, you need these directly
  has_many :request_area_data_variables, dependent: :destroy
  # You may pass these to the extract engine, if no extra attributes of the requested variables are required on a per request basis.
  has_many :area_data_variables, -> { uniq }, through: :request_area_data_variables, dependent: :destroy
  has_many :request_variables, dependent: :destroy
  has_many :variables, -> { uniq }, through: :request_variables, dependent: :destroy
  has_many :request_raster_variables, dependent: :destroy
  has_many :raster_variables, -> { uniq }, through: :request_raster_variables, dependent: :destroy
  has_many :request_geog_units, dependent: :destroy
  has_many :geog_units, -> { uniq }, through: :request_geog_units, dependent: :destroy
  has_many :request_terrapop_samples, dependent: :destroy
  has_many :terrapop_samples, -> { uniq }, through: :request_terrapop_samples, dependent: :destroy
  has_many :request_samples, dependent: :destroy
  has_many :samples, -> { uniq }, through: :request_samples, dependent: :destroy
  has_many :request_raster_datasets, dependent: :destroy
  has_many :raster_datasets, -> { uniq }, through: :request_raster_datasets, dependent: :destroy
  has_many :request_raster_timepoints, dependent: :destroy
  has_many :raster_timepoints, -> { uniq }, through: :request_raster_timepoints, dependent: :destroy
  has_many :request_sample_geog_levels, dependent: :destroy
  has_many :sample_geog_levels, -> { order(id: :desc).uniq }, through: :request_sample_geog_levels, dependent: :destroy
  has_many :extract_request_error_events, dependent: :destroy
  has_many :error_events, through: :extract_request_error_events, dependent: :destroy
  has_many :derivatives, class_name: "ExtractRequest", foreign_key: "revision_of_id", dependent: :nullify
  has_many :extract_request_area_data_raster_variable_mnemonic_lookups, dependent: :destroy
  has_many :area_data_raster_variable_mnemonic_lookups, through: :extract_request_area_data_raster_variable_mnemonic_lookups, dependent: :destroy

  has_and_belongs_to_many :labels, join_table: "extract_requests_labels"

  has_many :extract_data_artifacts

  belongs_to :user
  belongs_to :derivative, class_name: "ExtractRequest", foreign_key: "revision_of_id"
  belongs_to :extract_request_format

  scope :submissions, -> { where(submitted: true) }
  scope :unsubmitted, -> { where(submitted: false) }
  scope :recent, -> { where("created_at > ?", Time.now - 7.day) }
  scope :queued, -> { where(finish_extract_time: nil).joins(:extract_statuses).where(extract_statuses: {status: 'enqueued'}) }
  scope :get_submitted_user_extracts, ->(user_unique_id) { distinct.where(user_unique_id: user_unique_id, extract_grouping: nil).joins(:extract_statuses).where.not(extract_statuses: {status: 'building_request'}).order(:created_at) }

  validates_with NewuiExtractValidator, on: :create, if: :from_newui?

  after_create :normalize_attributes


  def self.dump_all
    {
      self.to_s.underscore.pluralize => self.where.not(user_unique_id: nil).find_each.map { |extract|
        #micro_variable_mnemonics  = extract.variables.select(:mnemonic).map(&:mnemonic)
        #area_variable_mnemonics   = extract.area_data_variables.select(:mnemonic).map(&:mnemonic)
        #raster_dataset_mnemonics  = extract.raster_datasets.select(:mnemonic).map(&:mnemonic)
        #terrapop_sample_mnemonics = extract.terrapop_samples.select(:label).map(&:label)
        sample_names              = extract.samples.select(:name).map(&:name)
        {
          'boundary_files'         => extract.boundary_files,
          'title'                  => extract.title,
          'notes'                  => extract.notes,
          'user_unique_id'         => extract.user_unique_id,
          'uuid'                   => extract.uuid,
          'submitted'              => extract.submitted,
          'created_at'             => extract.created_at,
          'updated_at'             => extract.updated_at,
         #'derivative'             => extract.uuid,
          'file_type'              => extract.file_type,
          'raster_only'            => extract.raster_only,
          'send_to_irods'          => extract.send_to_irods,
          'extract_url'            => extract.extract_url,
          'request_url'            => extract.request_url,
          'begin_extract_time'     => extract.begin_extract_time,
          'finish_extract_time'    => extract.finish_extract_time,
          'total_time'             => extract.total_time,
          'data'                   => extract.data
        }
      }.compact
    }
  end


  def from_newui?
    self.origin == 'newui'
  end


  def most_recent_submitted_at
    mrsa = self.extract_request_submissions.most_recent.first
    mrsa.submitted_at unless mrsa.nil?
  end


  def hierarchical?
    self.file_type == "hierarchical"
  end


  def name
    "terrapop_extract_#{id.to_s}"
  end


  # Public path in URL, can't get from terrapop.yml
  def extract_file_path(ext = nil)
    path = File.join(location, name)
    path += ".#{ext}" unless ext.nil?
    path
  end


  # Public path in URL, can't get from Terrapop.yml
  def download_path
    #"/extracts/#{user_directory()}/#{extract_directory()}"
    File.join('/extracts', user_directory, extract_directory)
  end


  def boundary_file_stub
    "boundaryfiles_#{id.to_s}"
  end


  def boundary_file_name(sample_geog_level)
    "#{boundary_file_stub}_#{sample_geog_level.internal_code.to_s}"
  end


  def boundary_file_names
    sample_geog_levels.map{ |sgl| boundary_file_name(sgl) }
  end


  def boundary_file_bundle
    "#{boundary_file_stub}.zip"
  end


  def boundary_file_bundle_path
    File.join(location, boundary_file_bundle)
  end


  def data_file_summaries
    str = []
    extract_data_artifacts.each do |eda|
      eda.nil? && next
      str << "Data File: " + eda.variables_description['filename']
      str << "Boundary Shapefile: " + eda.variables_description['boundary_filename'] if boundary_files
      str << "Country: " + eda.variables_description['country']
      str << "Data Year(s): " + eda.variables_description['years']
      str << "Geographic Level: " + eda.variables_description['geog_unit'] + ": " + eda.variables_description['country_level']
      str << ""
    end
    str.join("\n")
  end


  def data_dictionaries
    str = []
    extract_data_artifacts.each do |eda|
      str << "Data File: " + eda.variables_description['filename']
      eda.variables_description['columns'].each do |column|
        adrvml = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", column.downcase]).first
        str << column.to_s + ": " + (adrvml.nil? ? "N/A" : adrvml.description)
      end
      str << ""
    end
    str.join("\n")
  end


  # Need an area data variable for every sample_geog_level+ area data variable combination.
  def expanded_request_area_data_variables
    request_area_data_variables.map { |variable|
      sample_geog_levels.map do |sg|
        request_variable = RequestAreaDataVariable.new
        request_variable.area_data_variable = variable.area_data_variable
        request_variable.extract_request = variable.extract_request
        request_variable.sample_geog_level = sg
        request_variable
      end
    }.flatten
  end


  def expanded_request_raster_variables

    rrv = {}

    raster_dataset_buckets = request_raster_datasets.map{|rrd| {rrd.raster_dataset_id => Set.new([])}}.reduce Hash.new, :merge

    request_raster_timepoints.each do |rrt|
      
      raster_dataset_buckets[rrt.raster_timepoint.raster_dataset_id] ||= []
      raster_dataset_buckets[rrt.raster_timepoint.raster_dataset_id] << rrt.raster_timepoint.id
      
    end

    raster_dataset_buckets.each do |rdb_i, timepoints|
      request_raster_variables.each do |r|
        if rdb_i == r.raster_dataset_id
          k = "#{r.raster_variable_id}|#{r.extract_request_id}|#{r.raster_operation_id}|#{r.raster_dataset_id}"
        
          if timepoints.count == 0
            timepoints = ["_"]
          end
          
          timepoints.each do |time_point|
            
            kk = "#{k}|#{time_point}"
            
            unless rrv.has_key? kk
              rrv[kk] = {request_raster_variable_id: r.id, raster_timepoint_id: time_point}
            end
          
          end
          
        end
      end
    end
    
    rrv.map { |key, info|
      
      request_raster_variable_id = info[:request_raster_variable_id]
      raster_timepoint_id        = info[:raster_timepoint_id]
      raster_timepoint           = nil
      
      if raster_timepoint_id == "_"
        raster_timepoint_id = nil
      end
      
      variable = RequestRasterVariable.find(request_raster_variable_id)
      
      sample_geog_levels.map do |sg|
        request_variable = RequestRasterVariable.new
        request_variable.raster_variable   = variable.raster_variable
        request_variable.raster_operation  = variable.raster_operation
        request_variable.extract_request   = variable.extract_request
        request_variable.raster_dataset    = variable.raster_dataset
        request_variable.sample_geog_level = sg
        request_variable.raster_timepoint  = raster_timepoint_id.nil? ? nil : RasterTimepoint.find(raster_timepoint_id)
        request_variable
      end
      
    }.flatten

    # OUTPUT ==> An array of RequestRasterVariables

  end


  def has_area_data_variables?
    area_data_variables.count > 0
  end


  def has_microdata_variables?
    variables.count > 0
  end


  def has_raster_variables?
    raster_variables.count > 0
  end


  def has_variables?
    has_area_data_variables? || has_microdata_variables? || has_raster_variables?
  end


  def is_empty?
    !has_variables?
  end


  def variables_count
    area_data_variables.count + variables.count + raster_variables.count
  end


  def datasets_count
    terrapop_samples.count + samples.count + raster_datasets.count
  end


  def has_area_data_variable?
    area_data_variables.exists?(mnemonic: mnemonic)
  end


  def has_microdata_variable?(mnemonic)
    variables.exists?(mnemonic: mnemonic)
  end


  def has_raster_variable?(mnemonic)
    raster_variables.exists?(mnemonic: mnemonic)
  end


  def has_variable?(mnemonic, type)
    case type
    when ExtractTypeConst::AGGREGATE
      has_area_data_variable?(mnemonic)
    when ExtractTypeConst::MICRODATA
      has_microdata_variable?(mnemonic)
    when ExtractTypeConst::RASTER
      has_raster_variable?(mnemonic)
    else
      false
    end
  end


  def extract_type
    if (has_raster_variables? || has_area_data_variables?) && has_microdata_variables?
      ExtractTypeConst::AGGREGATE_ATTACHED_TO_MICRODATA
    elsif has_microdata_variables?
      ExtractTypeConst::MICRODATA
    elsif has_area_data_variables? && !raster_only
      ExtractTypeConst::AGGREGATE
    elsif has_area_data_variables? && raster_only
      ExtractTypeConst::RASTER
    elsif has_raster_variables? && !raster_only
      ExtractTypeConst::AGGREGATE
    elsif has_raster_variables? && raster_only
      ExtractTypeConst::RASTER
    else
      ExtractTypeConst::NO_DATA
    end
  end


  def submit
    # Changing the submitted setting first captures the idea that the extract is intended to be created and the user wants the data
    # requested. This will be set even if the documentation / syntax file step or the
    # enqueueing step fails.
    #update_attribute(:processing, false)
    update_attribute(:submitted_at, DateTime.now())
    update_attribute(:submitted, true)
    #update_attribute(:processing, false)
    
    if self.terrapop_samples.count == 0 || self.samples.count == 0
      import
    end
    
    begin
      tp_web_build = Rails.configuration.build_number
      tp_web_build = -1 unless tp_web_build.to_s.is_i?
    rescue
      tp_web_build = -1
    end

    update_attribute(:tp_web_build_number, tp_web_build)
    enqueue
  end


  def completed
    add_status(ExtractStatus::COMPLETED)
  end


  def failed
    add_status(ExtractStatus::FAILED)
  end


  def enqueue
    ers = ExtractRequestSubmission.new
    ers.submitted_at = Time.new
    ers.save
    self.extract_request_submissions << ers
    #update_attribute(:processing, false)

    add_status(ExtractStatus::ENQUEUED, {processing: false})

    if tractor_enabled?
      ers = ExtractRequestSerializer.new(self)
      ers.submit
    end

  end


  ### Duplicate Code - See TerrapopExtractEngine::QueueManagement ###
  def tractor_enabled?
    enable_tractor = TerrapopSetting.find_by(name: :enable_tractor)
    enable_tractor.nil? ? false : enable_tractor.value.to_bool
  end
  ####################################################################


  def begin_processing
    ### This method usually only gets called by the extract engine.
    add_status(ExtractStatus::PROCESSING)

    begin
      tp_xtr_build = Rails.configuration.build_number
      tp_xtr_build = -1 unless tp_xtr_build.to_s.is_i?
    rescue
      tp_xtr_build = -1
    end

    update_attribute(:tp_xtr_build_number, tp_xtr_build)
  end


  def waiting
    add_status(ExtractStatus::WAITING)
  end


  def stopped
    add_status(ExtractStatus::STOPPED)
  end


  def email_sent
    add_status(ExtractStatus::EMAIL_SENT)
  end


  def building_request
    add_status(ExtractStatus::BUILDING_REQUEST)
  end


  def should_stop
    add_status(ExtractStatus::SHOULD_STOP)
  end


  def current_status
    extract_statuses.order(:updated_at).last
  end


  def is_completed?
    current_status.status == ExtractStatus::COMPLETED
  end


  def is_failed?
    current_status.status == ExtractStatus::FAILED
  end


  def is_enqueued?
    current_status.status == ExtractStatus::ENQUEUED
  end


  def is_processing?
    current_status.status == ExtractStatus::PROCESSING
  end


  def is_waiting?
    current_status.status == ExtractStatus::WAITING
  end


  def is_stopped?
    current_status.status == ExtractStatus::STOPPED
  end


  def is_email_sent?
    current_status.status == ExtractStatus::EMAIL_SENT
  end


  def is_building_request?
    current_status.status == ExtractStatus::BUILDING_REQUEST
  end


  def should_stop?
    current_status.status == ExtractStatus::SHOULD_STOP
  end


  def can_be_resubmitted?
    (is_completed? || is_failed? || is_stopped? || is_email_sent?) || false
  end


  # This is efficient for getting the current statuses where that status
  # is "enqueued".  Otherwise we'd have to use includes(:extract_status) on
  # lots of extract_requests and filter. If this is slow check for indexing on extract_statuses.
  def self.enqueued
    ExtractStatus.current.enqueued.extracts.map { |status| status.extract_request }
  end


  def self.extract_group_count(group_str)
    ExtractStatus.current.enqueued.extracts.joins("INNER JOIN extract_requests er ON er.id = extract_statuses.extract_request_id").where("extract_requests.extract_grouping" => group_str).count
  end


  def self.get_next_in_queue(extract_variety=nil)
    ActiveRecord::Base.transaction {
      tmp_extract_ids = ExtractStatus.current.enqueued.extracts.map { |status| status.extract_request_id }

      extract_ids = ExtractRequest.where(id: tmp_extract_ids).where(extract_variety: extract_variety).map{|e| e.id}

      found = false
      e = nil
      while extract_ids.count > 0 and found == false
        extract_id = extract_ids.shift

        sql = "SELECT id FROM extract_requests WHERE id = #{extract_id} AND processing = false FOR UPDATE"
        results = ActiveRecord::Base.connection.execute(sql).first
        unless results.nil?
          extract_id = results['id']
          sql = "UPDATE extract_requests SET processing = true WHERE id = #{extract_id}"
          ActiveRecord::Base.connection.execute(sql)
          found = true
          $stderr.puts "Found Extract of Variety '#{extract_variety.nil? ? 'General' : extract_variety}'"
          e = ExtractRequest.find(extract_id)
        end
      end
      e
    }
  end


  def self.num_extracts_in_queue(extract_variety=nil)

    tmp_extract_ids = ExtractStatus.current.enqueued.extracts.map { |status| status.extract_request_id }

    ExtractRequest.where(id: tmp_extract_ids).where(extract_variety: extract_variety).map{|e| e.id}.count

    #ExtractStatus.current.enqueued.extracts.count
  end


  def mnemonic(request_variable)
    use_long_svar_mnemonic?(request_variable.variable) ? request_variable.long_mnemonic : request_variable.mnemonic
  end


  def use_long_svar_mnemonic?(variable)
    variable.is_svar? && !variable.long_mnemonic.blank? # && use_long_svar_names?
  end


  def category_code(request_variable, category)
    request_variable.general? ? category.code[0..request_variable.width - 1] : category.code
  end


  def self.duplicate(id_or_extract)
    if extract = ExtractRequest.find(id_or_extract)
      new_extract = ExtractRequest.create
      new_extract.area_data_variables = extract.area_data_variables
      new_extract.terrapop_samples = extract.terrapop_samples
      new_extract.variables = extract.variables.where(preselect_status: 0)
      new_extract.samples = extract.samples
      extract.request_raster_variables.each do |variable|
        new_extract.request_raster_variables.create({raster_variable: variable.raster_variable, raster_operation: variable.raster_operation, raster_dataset: variable.raster_dataset})
      end
      new_extract.raster_datasets = extract.raster_datasets
      new_extract.geog_units = extract.geog_units
      new_extract.sample_geog_levels = extract.sample_geog_levels #quickfix that may have complications!
      new_extract.boundary_files = extract.boundary_files
      new_extract.send_to_irods = extract.send_to_irods
      new_extract.file_type = extract.file_type
      new_extract.raster_only = extract.raster_only
      new_extract.title = "Revision of Extract #{extract.id}" + ((!extract.title.blank? && " - #{extract.title}") || '')
      new_extract.revision_of_id = extract.id
      new_extract.user_unique_id = extract.user_unique_id
      new_extract.save
      new_extract.reload
    end
  end


  def microdata_size_in_bytes
    total = 0
    samples.each do |sample|
      h_records = sample.h_records
      p_records = sample.p_records
      t_h = 0
      t_p = 0
      variables.each do |variable|
        size = variable.column_width
        if variable.record_type == 'H'
          t_h += (size * h_records)
        elsif variable.record_type == 'P'
          t_p += (size * p_records)
        end
      end
      total += t_h + t_p
    end
    total
  end


  def extract_zip_file
    file = nil
    if !self.extract_url.nil? && is_completed?
      begin
        file = File.join(Rails.root.to_s, "public", URI(self.extract_url).request_uri)
      rescue Exception => e
        Rails.logger.debug e
      end
    end
    file
  end


  def extract_zip_exists?
    file = self.extract_zip_file
    file.nil? ? false : File.exist?(file)
  end


  def extract_zip_size
    self.extract_zip_exists? ? File.size(self.extract_zip_file) : nil
  end


  def extract_zip_readable_size
    self.extract_zip_exists? ? "#{('%.2f' % ((self.extract_zip_size).to_f / 2**20)).to_f} MB" : ''
  end

  def is_downloadable?
    if self.extract_zip_exists?
      true
    else
      if self.send_to_irods and self.is_completed?
        true
      else
        false
      end
    end
  end

  # Puts all variables together in a list in the order they should appear in the extract
  def variables_in_extract
    layout_variables = variables + expanded_request_area_data_variables + expanded_request_raster_variables
    if extract_type == ExtractRequest::ExtractTypeConst::AGGREGATE
      #$stderr.puts "======> sample_geog_levels: " + sample_geog_levels.inspect
      raise "There were no sample_geog_levels, extract FAILED!!" if sample_geog_levels.first.nil?
      layout_variables = sample_geog_levels.first.variables_for_area_data_extracts + layout_variables
    end
    layout_variables.sort{ |a,b| a.mnemonic<=>b.mnemonic }
  end


  # helper method to get all the years covered by the extract request
  def years
    yrs = terrapop_samples.pluck(:year)
    yrs += samples.pluck(:year)
    yrs.uniq!
    years = Hash[ yrs.map { |year| [year, true] } ]
    years[:count] = yrs.length
    years
  end


  # helper method to get all the countries covered by the extract request
  def countries
    cntries = terrapop_samples.pluck(:short_country_name)
    cntries += samples.find_each.map { |sample| sample.short_country_name }
    cntries.uniq!
    countries = Hash[ cntries.map { |country| [country, true] } ]
    countries[:count] = cntries.length
    countries
  end


  def add_preselected_variables
    if !self.raster_only && self.variables.count > 0
      preselected_variables = Variable.preselected.map{ |v| {v => false} }.reduce({}, :merge)
      self.samples.each do |s|
        preselected_variables.each do |var, v|
          if v == false and var.included_in?(s)
            preselected_variables[var] = true
          end
        end
      end
      self.variables.concat preselected_variables.reject{ |k, v| v == false }.keys
    end
  end


  def self.new_extract_grouping
    str = SecureRandom::hex(8)
    while ExtractRequest.where(extract_grouping: str).count > 0
      str = SecureRandom::hex(8)
    end
    str
  end


  def import
    self.title = self.data["title"]
    self.notes = self.data["notes"]
    self.boundary_files = self.data["boundary"]
    self.send_to_irods = self.data["datagrid"]
    case self.data["type"]
    when "arealevel"
      import_arealevel
    when "microdata"
      import_microdata
    when "raster"
      import_raster
    end
  end


  def export
    {}
  end


  def submitted_date_time
    submitted_at.nil? ? "N/A" : submitted_at.strftime('%D - %r')
  end


  def total_time_human_readable
    total_time.nil? ? "- minutes" : ChronicDuration.output((total_time / 1000.0), :format => :long)
  end


  def extract_type_human_readable
    extract_type == 'aggregate' ? 'AREA-LEVEL' : extract_type.upcase
  end


  def can_be_revised?
    origin != 'newui'
  end


  def include_boundary_files_human_readable
    boundary_files ? "Yes" : "No"
  end


  def create_directories
    create_directory(root_path)
    [user_path, location].each do |path|
      create_directory(path)
      set_permissions(path)
    end
  end


  def location
    File.join(user_path, extract_directory)
  end


  def is_microdata_extraction_allowed?
    samples.none?{|sample| sample.restricted} || (!user_unique_id.nil? && get_user.microdata_access_is_approved?)
  end


  def get_user
    TerrapopUma::user_from(user_unique_id)
  end


  def self.extract_request_from_job(job)
    #  new_extract = ExtractRequest.create
    #  new_extract.area_data_variables = extract.area_data_variables
    #  new_extract.terrapop_samples = extract.terrapop_samples
    #  new_extract.variables = extract.variables.where(preselect_status: 0)
    #  new_extract.samples = extract.samples
    #  extract.request_raster_variables.each do |variable|
    #    new_extract.request_raster_variables.create({raster_variable: variable.raster_variable, raster_operation: variable.raster_operation, raster_dataset: variable.raster_dataset})
    #  end
    #  new_extract.raster_datasets = extract.raster_datasets
    #  new_extract.geog_units = extract.geog_units
    #  new_extract.sample_geog_levels = extract.sample_geog_levels #quickfix that may have complications!
    #  new_extract.boundary_files = extract.boundary_files
    #  new_extract.send_to_irods = extract.send_to_irods
    #  new_extract.file_type = extract.file_type
    #  new_extract.raster_only = extract.raster_only
    #  new_extract.title = "Revision of Extract #{extract.id}" + ((!extract.title.blank? && " - #{extract.title}") || '')
    #  new_extract.revision_of_id = extract.id
    #  new_extract.user_id = extract.user_id
    #  new_extract.save
    #  new_extract.reload
    #self.extract_request_job = job
    #self.user = User.find(job.user_id)

    #self.notes = job.comments || ""
    #details = job.details.with_indifferent_access

    #self.boundary_files = details[:boundary_files] || "false"
    #self.revision_of_id = details[:revision_of_id] || nil
    #self.file_type = details[:file_type] || "csv"
    #self.uuid = details[:uuid] || ""
    #self.raster_only = details[:raster_only] || false
    #self.send_to_irods = details[:send_to_irods] || "false"
    #self.extract_url = details[:extract_url] || nil
    #self.request_url = details[:request_url] || ""
    #self.begin_extract_time = details[:begin_extract_time] || nil
    #self.finish_extract_time = details[:finish_extract_time] || nil
    #self.total_time = details[:total_time] || nil
    #self.revision_of = details[:revision_of] || nil
    #self.commit = details[:commit] || ""
    #self.origin = details[:origin] || ""
    #self.processing = details[:processing] || false
    #self.extract_grouping = details[:extract_grouping] || ""
    #self.title = details[:title] || ""
    #self.data = details[:data] || {}
    #self.extract_filename = details[:extract_filename] || ""
    #self.submitted_at = details[:submitted_at] || nil
    #self.tp_web_build_number = details[:tp_web_build_number] || -1
    #self.save!

    details = job.details.with_indifferent_access

    #ExtractRequest.find(details[:id])

    ExtractRequest.where(uuid: details["uuid"]).first

  end


  private


  def create_directory(path)
    FileUtils.mkdir_p(path) unless File.directory?(path)
  end


  def set_permissions(path)
    begin
      if !(Etc.getgrnam('terrapop').nil? || Rails.env.test?)
        FileUtils.chown_R(nil, 'terrapop', path)
        FileUtils.chmod_R("g=rwx", path)
      end
    rescue Exception => e
      $stderr.puts "==> Possible Issue with Group/Permissions (#{path})"
      $stderr.puts e.backtrace
    end
  end


  def user_directory
    self.user_unique_id || raise("ExtractRequest[" + id.to_s + "] - Cannot determine extract location without user id")
  end


  def extract_directory
    self.id.nil? && raise("Cannot determine extract location without id")
    self.id.to_s
  end


  def root_path
    TerrapopConfiguration["application"]["environments"][Rails.env]["extracts"]
  end


  def user_path
    File.join(root_path, user_directory)
  end


  def add_status(status_string, extra_fields = {})
    extract_status = ExtractStatus.new
    extract_status.status = status_string
    extract_status.extract_request = self

    sd = StatusDefinition.where(status: status_string.downcase).first

    extract_status.status_definition_id = sd.id unless sd.nil?

    extract_status.save
    self.extract_statuses << extract_status

    extra_fields.each{ |k,v| self.send("#{k}=", v) }

    self.save
  end


  def normalize_attributes
    self.uuid ||= SecureRandom.uuid
    building_request if self.extract_statuses.empty?
  end


  def import_arealevel
    self.raster_only = false
    self.file_type = 'csv' #maybe a case on the self.data["type"]

    self.area_data_variables = AreaDataVariable.where(mnemonic: self.data["arealevel_variables"])
    self.terrapop_samples = TerrapopSample.where(id: self.data["arealevel_datasets"])

    geographies = []

    if self.data["arealevel_geographic_levels"] and self.data["arealevel_geographic_levels"].is_a? Array
      geographies |= self.data["arealevel_geographic_levels"]
    end

    if self.data["raster_geographic_levels"] and self.data["raster_geographic_levels"].is_a? Array
      geographies |= self.data["raster_geographic_levels"]
    end

    self.sample_geog_levels = SampleGeogLevel.where(id: geographies )

    if self.terrapop_samples.empty?
      self.terrapop_samples = TerrapopSample.where(id: self.sample_geog_levels.map{|sgl| sgl.terrapop_sample_id})
    end
    
    #binding.pry

    #if self.samples.count > 0 and self.data["raster_operations"].count > 0
    #  if self.samples.count > self.terrapop_samples.count
        # this is a simple indication that we might need to add more terrapop_samples
        # this should only be the case when there are:
        #
        # (1) multiple years of microdata samples for the same country
        # (2) Raster Summarizations requested
        # (3) fewer matching terrapop_samples to samples
        # (4) terrapop_samples being added should be for harmonized geographies only
        #
        #diff_ids = (self.samples.map{|sample| sample.terrapop_samples.map{|tps| tps.id}}.flatten.uniq) - self.terrapop_samples.map{|tps| tps.id}

        #self.terrapop_samples |= TerrapopSample.find(diff_ids)

        #associated_maps = self.sample_geog_levels.map{|sgl| {sgl.id => Map.where(country_level_id: sgl.country_level_id, terrapop_sample_id: sgl.terrapop_sample_id).first.source_file} }.reduce Hash.new, :merge

        #$stderr.puts associated_maps



        #diff_ids.each do |terrapop_sample_id|
        #  terrapop_sample = TerrapopSample.find(terrapop_sample_id)
        #  available_maps = terrapop_sample.maps.map{|m| m.source_file}.flatten.uniq

          #$stderr.puts available_maps.inspect

        #  associated_maps.each do |sgl,val|

        #    if available_maps.include? val
        #      $stderr.puts "ExtractRequest::import_area => Need to Add SampleGeogLevel(#{sgl})"
        #      self.sample_geog_levels |= [SampleGeogLevel.find(sgl)]
        #      self.terrapop_samples |= [terrapop_sample]
        #    end
        #  end
        #
        #end

        #end
    #end

    self.geog_units = self.sample_geog_levels.map{ |sgl| sgl.geog_unit }.uniq

    self.raster_datasets = RasterDataset.where(mnemonic: self.data["raster_datasets"])
    
    self.raster_timepoints = []
    
    self.data["raster_timepoints"].each do |dataset_mnemonic, array_of_timethingies|
      
      unless array_of_timethingies.nil?
      
        ids = array_of_timethingies.map do |rec|
          rec['id']
        end
      
        self.raster_timepoints << RasterTimepoint.where(id: ids)
      end
      
    end
    
    #self.raster_timepoints = RasterTimepoint.where(timepoint: self.data["raster_timepoints"].map { |dataset, timepoints| timepoints.map { |prop, value| prop['timepoint'] } }.flatten)

    self.data["raster_operations"].each do |variable_mnemonic, operation_opcodes|
      raster_variable = RasterVariable.find_by(mnemonic: variable_mnemonic)
      unless raster_variable.nil?
        raster_variable.raster_datasets.where(mnemonic: data["raster_datasets"]).each do |raster_dataset|
          RasterOperation.where(opcode: operation_opcodes).each do |operation|
            raster_operations = []
            raster_operations.push(operation.children.size > 0 ? (operation.children & raster_variable.raster_data_type.raster_operations).first : operation).flatten.uniq!
            raster_operations.each do |raster_operation|
              self.request_raster_variables.create({raster_variable: raster_variable, raster_operation: raster_operation, raster_dataset: raster_dataset})
            end
          end
        end
      end
    end
  end


  def import_microdata
    self.variables = Variable.where(mnemonic: self.data["microdata_variables"])
    self.samples = Sample.where(id: self.data["microdata_datasets"])
    import_arealevel
  end


  def import_raster
    self.raster_only = true
    self.file_type = 'tiff' #maybe a case on the self.data["type"]
    self.raster_variables = RasterVariable.where(mnemonic: self.data["raster_variables"])
    self.raster_datasets = RasterDataset.where(mnemonic: self.data["raster_datasets"])
    #self.raster_timepoints = RasterTimepoint.where(timepoint: self.data["raster_timepoints"])

    self.raster_timepoints = []
    
    self.data["raster_timepoints"].each do |dataset_mnemonic, array_of_timethingies|
      
      unless array_of_timethingies.nil?
      
        ids = array_of_timethingies.map do |rec|
          rec['id']
        end
      
        self.raster_timepoints << RasterTimepoint.where(id: ids)
      end
    end

    if self.data["arealevel_variables"].empty?
      self.sample_geog_levels = Country.where(id: self.data["raster_countries"]).map{ |country| country.country_year_and_highest_geography[:sample_geog_level] }
    else

      self.area_data_variables = AreaDataVariable.where(mnemonic: self.data["arealevel_variables"])
      self.terrapop_samples = TerrapopSample.where(id: self.data["arealevel_datasets"])
      self.sample_geog_levels = self.terrapop_samples.map{ |tps| tps.lowest_sample_geog_level }
    end

    self.geog_units = self.sample_geog_levels.map{ |sgl| sgl.geog_unit }.uniq
  end


end

ExtractRequest::ExtractTypeConst.define_consts
