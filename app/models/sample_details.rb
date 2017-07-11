# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleDetails


  class Collection
    def initialize(samples, groups, fields, values)
      @samples = samples.to_a
      @countries = @samples.map { |s| s.country }.uniq.sort { |a, b| a.full_name <=> b.full_name }
      @groups = groups.to_a.sort { |a, b| a.order <=> b.order }
      @fields = fields.to_a
      @values = values.to_a

      sample_map = Hash[@samples.map { |s| [s.id, s] }]
      @value_sample_map = {}
      @group_sample_map = {}

      @values.each do |v|
        s = sample_map[v.sample_id]
        g = v.sample_detail_field.sample_detail_group
        (@value_sample_map[s] ||= []) << v
        (@group_sample_map[s] ||= {})[g] = nil
      end

      @group_sample_map.each { |s, v| @group_sample_map[s] = v.keys }
    end

    def countries
      @countries
    end

    def samples(for_country = nil)
      if for_country
        @samples.select { |s| s.country == for_country }
      else
        @samples
      end
    end

    def groups(used_by_sample = nil)
      if used_by_sample
        @group_sample_map[used_by_sample] || []
      else
        @groups
      end
    end

    def fields(for_group = nil, exclude_summary_only = false)
      if for_group
        data = @fields.select { |f| f.sample_detail_group == for_group }
      else
        data = @fields
      end

      if exclude_summary_only
        data.reject { |f| f.summary_only }
      else
        data
      end
    end

    def value(sample, field)
      field = case field
                when SampleDetailField
                  field
                when String
                  @fields.detect { |f| f.name == field }
                else
                  nil
              end

      return nil unless sample && field

      list = @value_sample_map[sample] || []
      list.detect { |v| v.sample_detail_field_id == field.id }
    end

  end

  # Returns a SampleDetails::Collection object for the given samples (which should be a relation or list of AR Sample objects)
  # optionally, if detail_fields are specified, only those details fields will be returned (expects a list of strings)
  def self.for(samples, detail_fields = [])
    fields = SampleDetailField.eager_load(:sample_detail_group).order(:order)
    values = SampleDetailValue.preload({:sample_detail_field => :sample_detail_group}).where(sample_id: samples)

    if detail_fields && !detail_fields.empty?
      fields = fields.where(name: detail_fields)
      values = values.where(sample_detail_field_id: fields)
    end

    Collection.new(samples, fields.map { |f| f.sample_detail_group }.uniq, fields, values)
  end
end