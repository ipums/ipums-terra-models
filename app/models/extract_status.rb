# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'status_definition'


class ExtractStatus < ActiveRecord::Base

  # see data/static_data.yml for the available status_definitions
  belongs_to :extract_request
  scope :extracts, -> {includes(:extract_request)}

  scope :current, -> {where("(extract_statuses.id, extract_statuses.extract_request_id) in (select max(extract_statuses.id) as max_id, extract_request_id from extract_statuses group by extract_request_id)")}

  def self.define_consts

    @@status_definitions = []

    @@status_definitions = status_definitions = StatusDefinition.where({})

    status_definitions.each { |status_definition|
      status = status_definition.status

      unless status.nil?
        status = status.downcase
        self.const_set status.upcase, status
        scope status, -> {where(:status => status)}
      else
        raise "Your database maybe in an unknown state; ExtractStatus' status is nil"
      end
    }

  end

  def self.const_missing(name)
    name.downcase.to_s
  end

  def self.status_definitions
    @@status_definitions
  end

  def self.dump_all
    {
      self.to_s.underscore.pluralize => self.where(["status <> 'building_request'"]).map{|es|
        unless es.extract_request.user_unique_id.nil?
          {
            'extract_request_id' => es.extract_request.uuid,
            'status'             => es.status
          }
        end
      }.reject{|x| x.nil? }
    }
  end


end

ExtractStatus.define_consts
