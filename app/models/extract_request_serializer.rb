# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'date'


class ExtractRequestSerializer
  #include ActiveModel::Model
  #include ExtractRequestAbstractSerializer

  ATTRIBUTES = [:user_unique_id, :id, :status, :number, :comments, :created_at, :updated_at, :boundary_files, :notes, :submitted, :revision_of_id, :file_type, :uuid, :raster_only, :send_to_irods, :extract_url, :request_url, :begin_extract_time, :finish_extract_time, :total_time, :revision_of, :commit, :origin, :processing, :extract_grouping, :data, :title, :extract_filename, :submitted_at, :tp_web_build_number, :tp_xtr_build_number]

  attr_accessor *ATTRIBUTES

  @@connection = nil

   def self.connection=(val)
     @@connection = val
   end

   def self.connection
     @@connection || Faraday.new(:url => Rails.configuration.tractor_api_base_url)
   end

  def initialize(extract_request)
    
    ATTRIBUTES.each{|attr|
      if extract_request.attributes.keys.include? attr.to_s
        self.send( "#{attr.to_s}=", extract_request.send(attr) )
      end
    }
    
    self.updated_at = Time.now.to_s
    
  end

  def self.find(id)
    response = self.connection.get do |req|
      req.url "/extract_request_jobs/#{id}"
      req.params['project'] = 'terrapop'
      req.headers['Content-Type'] = 'application/json'
    end
    create_from_response_hash(JSON.load(response.body))
  end

  def self.find_by_user_id(user_id)
    response = self.connection.get do |req|
      req.url '/extract_request_jobs'
      req.params['project'] = 'terrapop'
      req.params['user_id'] = user_id
      req.headers['Content-Type'] = 'application/json'
    end
    response_array = JSON.load(response.body)
    response_array.map { |response_hash| create_from_response_hash(response_hash) }.sort_by(&:number).reverse
  end

  def self.create_from_response_hash(response_hash)
    response_extract_request = Hash[response_hash["details"].to_a.select { |k, v| ATTRIBUTES.include?(k.to_sym) }]
    if response_extract_request["created_at"].present?
	    response_extract_request["created_at"] = DateTime.parse(response_extract_request["created_at"])
    end
    if response_extract_request["submitted_at"].present?
	    response_extract_request["submitted_at"] = DateTime.parse(response_extract_request["submitted_at"])
    end
    if response_extract_request["updated_at"].present?
	    response_extract_request["updated_at"] = DateTime.parse(response_extract_request["updated_at"])
    end
    new(response_extract_request.merge({user_unique_id: response_hash["user_unique_id"], id: response_hash["id"], status: response_hash["status"], number: response_hash["number"], comments: response_hash["comments"] }))
  end

  #def custom_attributes
  #  CUSTOM_ATTRIBUTES = [:boundary_files, :notes, :user_id, :submitted, :revision_of_id, :file_type, :uuid, :raster_only, :send_to_irods, :extract_url, :request_url, :begin_extract_time, :finish_extract_time, :total_time, :revision_of, :commit, :origin, :processing, :extract_grouping, :data, :title, :extract_filename, :submitted_at, :tp_web_build_number, :tp_xtr_build_number]
  #end
  
  def submit
    response = self.class.connection.post do |req|
      req.url '/extract_request_jobs'
      req.params['project'] = 'terrapop'
      req.headers['Content-Type'] = 'application/json'
      req.body = submission_json
    end
    response_hash = JSON.load(response.body)
    $stderr.puts "\n\n\n============================================="
    $stderr.puts response_hash.to_json
    $stderr.puts "=============================================\n\n\n"
    number = response_hash["number"]
    status = response_hash["status"]
    id = response_hash["id"]
  end

  def self.get_submitted_user_extracts(user_id)
    response = self.connection.get do |req|
      req.url '/extract_request_jobs'
      req.params['project'] = 'terrapop'
      req.params['user_id'] = user_id
      req.params['status'] != 'building_request'
      req.headers['Content-Type'] = 'application/json'
    end
    response_array = JSON.load(response.body)
    response_array.map { |response_hash| create_from_response_hash(response_hash) }.sort_by(&:number).reverse
  end

  def update_comments(new_comments)
    self.comments = new_comments
    self.class.connection.post do |req|
      req.url "/extract_request_jobs/#{id}/update_comments"
      req.params['project'] = 'terrapop'
      req.headers['Content-Type'] = 'application/json'
      req.body = submission_json
    end
  end
  
  def update_title(new_title)
    self.class.connection.post do |req|
      req.url "/extract_request_jobs/#{id}/update_title"
      req.params['project'] = 'terrapop'
      #req.header['Content-type'] = 'application/json'
      req.body = new_title
    end
  end

  def submission_json
    {details: self.as_json(except: ["id", "comments", "number", "created_at", "updated_at", "submitted_at"]), user_id: user_unique_id, comments: comments, number: number, id: id}.to_json
  end
end
