# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RemoveUnnecessaryFieldsFromTerrapopSample < ActiveRecord::Migration

  def change
    
    remove_column :terrapop_samples, :population_universe
    remove_column :terrapop_samples, :de_jure_or_de_facto
    remove_column :terrapop_samples, :enumeration_unit
    remove_column :terrapop_samples, :census_start_date
    remove_column :terrapop_samples, :census_end_date
    remove_column :terrapop_samples, :fieldwork_start_period
    remove_column :terrapop_samples, :fieldwork_end_period
    remove_column :terrapop_samples, :enumeration_forms
    remove_column :terrapop_samples, :type_of_fieldwork
    remove_column :terrapop_samples, :respondent
    remove_column :terrapop_samples, :coverage
    remove_column :terrapop_samples, :undercount
    remove_column :terrapop_samples, :undercount_notes
    remove_column :terrapop_samples, :microdata_source
    remove_column :terrapop_samples, :long_form_sample_design
    remove_column :terrapop_samples, :mpc_sample_design
    remove_column :terrapop_samples, :sample_unit
    remove_column :terrapop_samples, :sample_fraction
    remove_column :terrapop_samples, :sample_fraction_notes
    remove_column :terrapop_samples, :sample_size
    remove_column :terrapop_samples, :sample_weights
    remove_column :terrapop_samples, :sample_characteristics_notes
    remove_column :terrapop_samples, :sample_general_notes
    remove_column :terrapop_samples, :has_dwellings
    remove_column :terrapop_samples, :has_dwellings_note
    remove_column :terrapop_samples, :has_vacant_units
    remove_column :terrapop_samples, :has_vacant_units_note
    remove_column :terrapop_samples, :has_closed_units
    remove_column :terrapop_samples, :has_closed_units_note
    remove_column :terrapop_samples, :smallest_geography
    remove_column :terrapop_samples, :has_households
    remove_column :terrapop_samples, :has_households_note
    remove_column :terrapop_samples, :has_families
    remove_column :terrapop_samples, :has_families_note
    remove_column :terrapop_samples, :has_individuals
    remove_column :terrapop_samples, :has_individuals_note
    remove_column :terrapop_samples, :has_group_quarters
    remove_column :terrapop_samples, :has_group_quarters_note
    remove_column :terrapop_samples, :has_indigenous_pop
    remove_column :terrapop_samples, :has_indigenous_pop_note
    remove_column :terrapop_samples, :has_special_pop
    remove_column :terrapop_samples, :has_special_pop_note
    remove_column :terrapop_samples, :units_notes
    remove_column :terrapop_samples, :identification_general_notes
    remove_column :terrapop_samples, :unit_definition_household
    remove_column :terrapop_samples, :unit_definition_family
    remove_column :terrapop_samples, :unit_definition_dwelling
    remove_column :terrapop_samples, :unit_definition_group_quarters
    remove_column :terrapop_samples, :unit_definition_homeless_population
    remove_column :terrapop_samples, :unit_definition_institution
    remove_column :terrapop_samples, :unit_definition_institutional_population
    remove_column :terrapop_samples, :unit_definition_notes
    remove_column :terrapop_samples, :unit_definition_general_notes
    remove_column :terrapop_samples, :is_weighted
    
  end
end
