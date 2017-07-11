# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataRasterVariableMnemonicLookup < ActiveRecord::Base

  has_many :area_data_raster_variable_mnemonic_lookups
  has_many :extract_requests, through: :area_data_raster_variable_mnemonic_lookups, dependent: :destroy
  
  def self.remap_description(desc)
    
    if desc.match(/total area \(binary\)\(binary\)$/)
      desc.gsub!(/\(binary\)$/, '(Square meters)')
    elsif desc.match(/total area \(binary\)\(not applicable\)$/)
      desc.gsub!(/\(not applicable\)$/, '(Square meters)')
    elsif desc.match(/num_classes\(not applicable\)$/)
      desc.gsub!(/\(not applicable\)$/, ' (Count)')
    elsif desc.match(/percent area \(areal\)\(Square Meters\)$/ )
      desc.gsub!(/\(Square Meters\)$/, '(Percentage)')
    elsif desc.match(/mode\(not applicable\)$/)
      desc.gsub!(/mode/, 'most common land cover ')
    elsif desc.match(/percent area \(binary\)\(binary\)$/)
      desc.gsub!(/\(binary\)/, '(Percentage)')
    end
    
    if desc.match(/mode/)
      desc.gsub!(/mode/, 'most common land cover')
    elsif desc.match(/num_classes/)
      desc.gsub!(/num_classes/, '# land cover classes')
    elsif desc.match(/(total_area_bin)|(total_area_areal)/)
      desc.gsub!(/(total_area_bin)|(total_area_areal)/, 'area')
    elsif desc.match(/(percent_area_bin)|(percent_area_areal)/)
      desc.gsub!(/(percent_area_bin)|(percent_area_areal)/, '% area')
    elsif desc.match(/\(Percentage\)\(Percentage\)$/)
      desc.gsub!(/\(Percentage\)$/, '')
    end    
    
    desc
  end
  
end
