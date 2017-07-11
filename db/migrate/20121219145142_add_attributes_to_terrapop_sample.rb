# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddAttributesToTerrapopSample < ActiveRecord::Migration

  def change

    # Census characteristics
    add_column :terrapop_samples, :local_title,             :text
    add_column :terrapop_samples, :census_agency,           :text
    add_column :terrapop_samples, :population_universe,     :text
    add_column :terrapop_samples, :de_jure_or_de_facto,     :text   # ? Can be either or both (see brazil 1960)
    add_column :terrapop_samples, :enumeration_unit,        :text   # (could maybe abstract to a list, not sure of all possible types. Dwelling, 
    add_column :terrapop_samples, :census_start_date,       :date
    add_column :terrapop_samples, :census_end_date,         :date
    add_column :terrapop_samples, :fieldwork_start_period,  :date   # ? have start and end dates?
    add_column :terrapop_samples, :fieldwork_end_period,    :date
    add_column :terrapop_samples, :enumeration_forms,       :text
    add_column :terrapop_samples, :type_of_fieldwork,       :text
    add_column :terrapop_samples, :respondent,              :text
    add_column :terrapop_samples, :coverage,                :float    # with null - null indicates "no official estimate"?
    add_column :terrapop_samples, :undercount,              :float    # : same as coverage
    add_column :terrapop_samples, :undercount_notes,        :text
    
    # Microdata sample characteristics
    add_column :terrapop_samples, :microdata_source,              :text
    add_column :terrapop_samples, :long_form_sample_design,       :text
    add_column :terrapop_samples, :mpc_sample_design,             :text
    add_column :terrapop_samples, :sample_unit,                   :text
    add_column :terrapop_samples, :sample_fraction,               :float
    add_column :terrapop_samples, :sample_fraction_notes,         :text
    add_column :terrapop_samples, :sample_size,                   :bigint
    add_column :terrapop_samples, :sample_weights,                :text
    add_column :terrapop_samples, :sample_characteristics_notes,  :text
    add_column :terrapop_samples, :sample_general_notes,          :text

    # Units identified
    add_column :terrapop_samples, :has_dwellings,           :boolean
    add_column :terrapop_samples, :has_dwellings_note,      :text
    add_column :terrapop_samples, :has_vacant_units,        :boolean
    add_column :terrapop_samples, :has_vacant_units_note,   :text
    add_column :terrapop_samples, :has_closed_units,        :boolean
    add_column :terrapop_samples, :has_closed_units_note,   :text
    add_column :terrapop_samples, :smallest_geography,      :text
    add_column :terrapop_samples, :has_households,                  :boolean
    add_column :terrapop_samples, :has_households_note,             :text
    add_column :terrapop_samples, :has_families,                    :boolean
    add_column :terrapop_samples, :has_families_note,               :text
    add_column :terrapop_samples, :has_individuals,                 :boolean
    add_column :terrapop_samples, :has_individuals_note,            :text
    add_column :terrapop_samples, :has_group_quarters,              :boolean
    add_column :terrapop_samples, :has_group_quarters_note,         :text
    add_column :terrapop_samples, :has_indigenous_pop,              :boolean
    add_column :terrapop_samples, :has_indigenous_pop_note,         :text
    add_column :terrapop_samples, :has_special_pop,                 :boolean
    add_column :terrapop_samples, :has_special_pop_note,            :text
    add_column :terrapop_samples, :units_notes,                     :text
    add_column :terrapop_samples, :identification_general_notes,    :text
    
    # Unit definitions
    add_column :terrapop_samples, :unit_definition_household,                 :text
    add_column :terrapop_samples, :unit_definition_family,                    :text
    add_column :terrapop_samples, :unit_definition_dwelling,                  :text
    add_column :terrapop_samples, :unit_definition_group_quarters,            :text
    add_column :terrapop_samples, :unit_definition_homeless_population,       :text
    add_column :terrapop_samples, :unit_definition_institution,               :text
    add_column :terrapop_samples, :unit_definition_institutional_population,  :text
    add_column :terrapop_samples, :unit_definition_notes,                     :text
    add_column :terrapop_samples, :unit_definition_general_notes,             :text

  end
end
