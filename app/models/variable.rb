# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'set'


class Variable < ActiveRecord::Base
  include MarkupTransform

  has_many :frequencies
  has_many :categories
  has_many :sample_variables
  has_many :samples, through: :sample_variables
  has_many :area_data_variable_constructions
  has_many :area_data_variables, through: :area_data_variable_constructions
  has_many :general_categories, -> { where.not(general_label: '').order(:metadata_id) }, :class_name => 'Category'
  has_many :detailed_categories, -> { order(:metadata_id) }, :class_name => 'Category'
  has_many :sample_geog_levels, foreign_key: 'geolink_variable_id'
  has_many :country_comparabilities, -> { order('countries.full_name').includes(:country) }
  has_many :variable_availability_caches

  has_and_belongs_to_many :topics

  belongs_to :variable_group
  belongs_to :sample

  scope :alphabetical, -> { order(mnemonic: :asc) }
  scope :preselected, -> { where(preselect_status: 1, is_old: false) }
  scope :not_preselected, -> { where.not(preselect_status: 1).where(is_old: false) }
  scope :is_common_var, -> { where("is_common_var is not null") }
  scope :primary_common_var, -> { self.is_common_var.where(is_common_var: "primary") }
  scope :derived_common_var, -> { self.is_common_var.where(is_common_var: "derived") }
    
  alias_attribute :len, :column_width
  alias_attribute :width, :column_width
  alias_attribute :name, :mnemonic
  alias_attribute :dataset_ids, :sample_ids
  alias_attribute :variable_category_id, :variable_group_id
  alias_attribute :preselected, :preselected?


  def preselected?
    preselect_status == 1 and is_old == false
  end


  def included_in?(sample)
    samples.include? sample
  end


  def samples_universes
    tuples = {}
    sample_variables.joins(sample: :terrapop_samples).includes(:sample, :universe).find_each{ |sample_variable|
      tuples[sample_variable.sample.name] = {description: sample_variable.sample.long_description, universe_statement: sample_variable.universe.nil? ? "" : sample_variable.universe.universe_statement}
    }
    tuples
  end

  def source_variables_for_samples
    samples = Sample.where(id: dataset_ids)
    source_vars = []
    samples.each do |s|
      source_vars << VariableSource.where("sample_variables.variable_id = ? and sample_variables.sample_id = ?", id, s.id).joins(:makes)
    end
    source_vars.flatten!

    #sort @source_variables
    source_vars.sort! { |a, b| [a.is_made_of.variable.is_svar? ? a.is_made_of.variable.sample.name : a.is_made_of.sample.name, a.is_made_of.variable.mnemonic] <=> [b.is_made_of.variable.is_svar? ? b.is_made_of.variable.sample.name : b.is_made_of.sample.name, b.is_made_of.variable.mnemonic] }
  end

  def start
    if is_svar
      # belongs to only one sample
      # Could use the "sample_id" on the variables table but I don't know if the ID in the Samples table is preserved in Terrapop.
      s = samples.first
      offset = household_variable? ?  s.offset_for_person : s.offset_for_household
      column_start + offset
    else
      column_start
    end
  end


  def person_variable?
    record_type == 'P'
  end


  def household_variable?
    record_type == 'H'
  end


  def record_type_name
    household_variable? ? :household : :person
  end


  def data_table_key
    record_type_name.to_s.pluralize.to_sym
  end


  # returns array of Samples
  def availability_by_sample
    samples.select("samples.*, countries.full_name AS country_full_name, UPPER(countries.short_name) AS short_country_name, UPPER(countries.short_name) || lpad((year % 100)::text, 2, '0') AS short_country_name_year").joins("INNER JOIN countries ON samples.country_id = countries.id")
  end


  def availability_by_country
    cache = variable_availability_caches.first
    if cache.nil?
      store = {}
      _availability_by_country = {}
      samples.select("samples.*, countries.full_name AS country_full_name").joins("INNER JOIN terrapop_samples ON terrapop_samples.sample_id = samples.id LEFT OUTER JOIN countries ON countries.id = samples.country_id").each do |sample|
        country_code = sample.country_full_name
        store[country_code] ||= []
        store[country_code]<< sample.year
      end
      store.each { |key, val| _availability_by_country[key] = val.sort }
      obj = VariableAvailabilityCach.create(variable_id: id, json: _availability_by_country.to_json)
      JSON.parse(obj.json)
    else
      JSON.parse(cache.json)
    end
  end


  def country_comparability_for_samples(them_samples)
    country_comparabilities.where("country_id in (?)", (samples & them_samples).map { |s| s.country }.uniq)
  end


  def description_html
    transform_markup(description)
  end


  def country_comparability_html(visible_samples)
    country_comparability_for_samples(visible_samples).to_a
  end


  def general_comparability_html
    transform_markup(general_comparability)
  end


  def variable_path(str)
    "<a href='#' class='cross_reference_variables' id='cross_reference_variable_#{str}' data-mnemonic='#{str}'>#{str}</a>"
  end


end
