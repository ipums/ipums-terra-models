# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Sample < ActiveRecord::Base


  has_many :sample_variables
  has_many :variables
  has_many :terrapop_samples
  has_many :sample_detail_values

  has_and_belongs_to_many :tags, join_table: :samples_tags

  belongs_to :country

  default_scope { where(is_old: false) }
  scope :visible, -> { where(hide_status: 0) }


  def api_attributes
    "TODO"
  end


  def label
    "#{country.full_name} #{year}"
  end


  def file
    #File.join(TerrapopConfiguration['application']['environments'][Rails.env]['source_data']['microdata'], data_file_name)
    File.join(TerrapopConfiguration.settings['source_data']['microdata'], data_file_name)
  end


  def short_country_name
    country.short_name.upcase
  end


  def short_year
    year.to_s[-2,2]
  end


  def offset_for_person
    @@person_offset ||= offset_for_rectype('P')
  end


  def offset_for_household
    @@household_offset ||= offset_for_rectype('H')
  end


  def offset_for_rectype(rectype)
    Variable.where(record_type: rectype, is_svar: false).maximum("column_start + column_width")
  end


  def microdata_filesize
    if filesize.nil? or filesize == 0
      _file = file
      if File.exist? _file
        filesize = File.size _file
        save
      elsif File.exist?("#{_file}.gz")
        filename = "#{_file}.gz"
        f = File.open(filename, 'rb')
        unless f.nil?
          f.seek(File.size(filename) - 4)
          a = f.readbyte
          b = f.readbyte
          c = f.readbyte
          d = f.readbyte
          filesize = (a << 24) | (b << 16) + (c << 8) + d;
          save
        end
      end
    end
    filesize
  end


end
