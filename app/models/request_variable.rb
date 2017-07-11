# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RequestVariable<ActiveRecord::Base

  belongs_to :variable
  belongs_to :extract_request
  belongs_to :attached_variable_pointer
    
  # Convenience methods:
  # The mnemonic of a request variable can be constructed from the requested variable but will be different if it's an
  # attached variable (variable.mnemonic + attached_pointer suffix.)
  def mnemonic       
    attached_variable_pointer ? variable.mnemonic + "_" + attached_variable_pointer.suffix : variable.mnemonic                  
  end
  
  def general?
    general_detailed_selection == 'G'
  end

  def detailed?
    general_detailed_selection == 'D'
  end
  
  def record_type
    variable.record_type
  end
  
  def data_type
    variable.data_type
  end
  
  def attached?
    !attached_variable_pointer.nil?
  end
  
  def attached_variable_pointer_mnemonic
    attached? ? attached_variable_pointer.mnemonic : nil
  end
  
  def household_variable?
    variable.household_variable?
  end
    
  def person_variable?
    variable.person_variable?
  end
  
  def width
    @computed_width || variable.width
  end
  
  def start
    @computed_start || variable.start
  end
  
  def start=(s)
    @computed_start = s
  end
  
  def width=(w)
    @computed_width = w
  end

  def long_mnemonic
    mnemonic = variable.long_mnemonic
    if detailed?
      mnemonic += "D"
    end
    unless attached_variable_pointer.nil?
      mnemonic += "_" + attached_variable_pointer.suffix
    end
    mnemonic
  end
  
  def full_label
    attached_variable_pointer ? label_for_attached : label_for_non_attached
  end
  
  def categories
    if general?
      variable.general_categories
    else
      variable.detailed_categories
    end
  end
  
  private

  def label_for_attached
    if detailed?
      return "#{variable.label} [of #{attached_variable_pointer.label}; detailed version]"
    elsif general?
      return "#{variable.label} [of #{attached_variable_pointer.label}; general version]"
    else
      return "#{variable.label} [of #{attached_variable_pointer.label}]"
    end
  end

  def label_for_non_attached
    if variable.is_general_detailed?
      return detailed? ? "#{variable.label} [detailed version]" : "#{variable.label} [general version]"
    else
      return variable.label
    end
  end
    
end