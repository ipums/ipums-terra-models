# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ExtractRequestJob < ActiveRecord::Base

  

  # Connection information for connecting to the tractor_jobs db
  @@connection_name = "#{Rails.env}_tractor_jobs"
  establish_connection @@connection_name.to_sym
  
  def self.table_name_prefix
    ""
  end

  # Method called by Delayed::Job when job starts
  def perform
    extract_request = ExtractRequest.extract_request_from_job(self)
    
    log = Logger.new(File.join(Rails.root,"/log/extract.log"))
    
    tps = TerrapopSetting.find_by(name: 'server_name')
    uuid = nil
    url = base_url = nil

    unless tps.nil?
      begin
        base_url = tps.value.gsub(/\'/, '')
        url = 'https://' + base_url + '/api/system/heartbeats'
        response = RestClient.post(url, {content_type: :json, accept: :json})
        uuid = JSON.parse(response)['uuid'] if response.code == 200
      rescue Exception => exception
        $stderr.puts exception
      end
    end
    
    unless uuid.nil?
      begin
        RestClient.put('https://' + base_url + '/api/system/heartbeats/' + uuid, {content_type: :json, accept: :json})
      rescue Exception => exception
        # do nothing, just chill
      end
    end

    log.info "===> Extract Code Base: #{Rails.configuration.gitcommit}"
    log.info "Processing extract request #{extract_request.id}"

    extract_request_user = extract_request.get_user
    if not extract_request_user.valid?
      # the extract_request doesn't have a user, nobody will care about it, make the extract_request as fail and move on
      extract_request.failed
      log.info "No user associated with extract."
      raise "No user associated with extract[#{extract_request.uuid}]"
    end
    
    extract_request.commit = Rails.configuration.gitcommit
    log.info "Extract belongs to #{extract_request_user.owner_info}"
    log.info "Extract submitted at #{extract_request.updated_at}"
    log.info "Microdata Size: #{extract_request.microdata_size_in_bytes.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} bytes"

    force_extract_fail = TerrapopSetting.find_by(name: 'force_extract_fail')
    force_extract_fail_email = TerrapopSetting.find_by(name: 'force_extract_fail_email')

    if !force_extract_fail.nil? and !force_extract_fail_email.nil? and force_extract_fail.value == 'true' and !force_extract_fail_email.value.blank?
      users = force_extract_fail_email.value.split(',').map{ |email| email.strip }
      if users.include?(extract_request_user.email)
        log.info "Extract FORCE FAILED id: #{extract_request.id}"
        extract_request.failed
        Notifier.extract_failed(extract_request_user, extract_request).deliver
        next
      end
    end

    begin
      extract_builder = TerrapopExtractEngine::Build.new(extract_request)
      extract_request.begin_processing
      #extract_builder.zip_bundle_filename # set the final extract zip file name -- needed in codebooks
      extract_builder.extract
    rescue Exception=>exception
      log.error "Extract FAILED with exception #{exception.to_s} and backtrace #{exception.backtrace}"
      log.error "Extract Request inspect: #{extract_request.inspect}"
      extract_request.failed
      Notifier.extract_failed(extract_request_user, extract_request).deliver
      raise exception
    end

    if extract_builder.has_failures?
      log.error "Extract #{extract_request.id} failed."
      extract_request.failed
      Notifier.extract_failed(extract_request_user, extract_request).deliver
      next
    end

    unless extract_request.raster_only
      log.info "Completed extract for #{extract_request.id}"
      extract_builder.build_zip_bundle
      log.info "Zipped up output for #{extract_request.id}"
      extract_request.completed
    end

    zipfile = extract_request.download_path + "_bundle." + TerrapopConfiguration['application']['output']['zipfile']['extension']
    abs_path = File.join(Rails.root.to_s, 'public', zipfile)
    extract_available = true
    is_bundled = false
    needs_bundling = false

    unless extract_request.extract_grouping.nil?
      is_bundled = true
      if ExtractRequest.extract_group_count(extract_request.extract_grouping) == 0
        needs_bundling = true
      end
    end

    if extract_request.send_to_irods and !is_bundled
      base_url = extract_request.request_url
      unless base_url.nil?
        url = base_url + '/api/data/extract/v1/irods'
        begin
          response = RestClient.post(url, {uuid: extract_request.uuid}, {content_type: :json, accept: :json})
          extract_available = response.code == 200
          extract_request.extract_url = JSON.parse(response)['extract_url']
        rescue Exception => exception
          # do nothing, just chill
        end
      end
    else
      extract_request.extract_url = extract_request.request_url + zipfile
    end

    extract_request.save

    if extract_available and !is_bundled
      Notifier.extract_ready(extract_request_user, extract_request).deliver
    elsif !extract_available
      Notifier.send_extract_failure("Failed to push Extract to IRODS", extract_request).deliver
    end

    if needs_bundling
      extracts = ExtractRequest.where(extract_grouping: extract_request.extract_grouping).where.not(finish_extract_time: nil)

      zipfile_name = File.join(Rails.root.to_s, 'public', 'extracts', DateTime.now.to_s.gsub(/ +/, '_') + ".zip")

      extracts.each do |extract|
        path = URI.parse(extract.extract_url).path
        abs_path = File.join(Rails.root.to_s, 'public', path)

        Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|

          basename = File.basename(abs_path)
          if zipfile.find_entry(basename).nil?
            zipfile.add(basename, abs_path)
          end

        end

      end

      FileUtils.chmod 0644, zipfile_name

      Notifier.super_extract_ready(extract_request.user, extract_request.request_url, zipfile_name).deliver

    end

    log.info "Completed processing extract at #{Time::now.to_s}"
    
  end

  def add_detail(name, value)
    self.details[name] = value
    self.save
  end

  # Method called by Delayed::Job when job failed
  def failure(job)
    if job.last_error.include? "execution expired"
      self.status = {name: ExtractStatus.timed_out.name, message: ""}
      self.save
      Rails.logger.info "**** timed out extract ****** id -- #{id}"
      #NotificationMailer.extract_timed_out(self).deliver unless Rails.env=="test"
    else
      self.status = {name: ExtractStatus.failed.name, message: job.last_error}
      self.save
      #NotificationMailer.extract_problem(self, job.last_error).deliver unless Rails.env=="test"
      #NotificationMailer.extract_failed(self, job.last_error).deliver unless Rails.env=="test"
    end
  end
end