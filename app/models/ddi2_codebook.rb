# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# Renders a DDI 2 codebook for an extract request.

# In contrast with other codebooks, the DDI 2 codebook should be UTF-8 encoded.
require 'yaml'

class Ddi2Codebook
  include DdiHelper

  def initialize(extract_request)
    @er = extract_request

    begin
      @exclude_common  = Variable.derived_common_var.mnemonic
      @include_common  = Variable.primary_common_var.mnemonic
    rescue Exception => e
      begin
        common_variables = CommonVariable.all
        @exclude_common  = common_variables.select { |v| v.record_type != "household" }.map { |cv| cv.variable_name.upcase }
        @include_common  = common_variables.select { |v| v.record_type == "household" }.map { |cv| cv.variable_name.upcase }
      rescue Exception => ee
        @exclude_common = []
        @include_common = []
      end
    end
    
  end

  def generate_file
    path = @er.extract_file_path('xml')

    # Pre-encode the string, ignoring invalid or undefined source characters
    rendered_xml = to_xml.encode("UTF-8", :invalid => :replace, :undef => :replace)

    #tf = Tempfile.open('terrapop_ddi2codebook', "w:UTF-8")

    #path = tf.path

    File.open(path, "w:UTF-8") { |f| f.write(rendered_xml) }

    #tf.write(rendered_xml)

    #tf.path

    path
  end

  private

  def doc_id
    @codebook_id ||= "ddi2-#{@er.user_unique_id}_#{data_filename}-#{DNAME}"
  end

  def doc_subtitle
    TXT['docDscr_subTitl'] + " '#{data_filename}'"
  end

  def data_filename
    @data_filename ||= File.basename(@er.extract_file_path('dat'))
  end

  def date
    # we need to keep this around because the XML rendering could begin and
    # end on different days, but we want the codebook to have a consistent date
    @date ||= Date.today
  end

  def prod_date_eng
    @prod_date_eng ||=
        "#{Date::MONTHNAMES[date.month]} #{date.mday}, #{date.year}"
  end

  def prod_date_iso
    @prod_date_iso ||= @date.to_s
  end

  def study_subjects
    @study_subjects ||= @er.request_variables.map do |v|
      v.variable.variable_group.ddi2_subject
    end.uniq
  end

  # This code is largely duplicated from Codebook.rb which is a bad thing.  (Non-D.R.Y.)
  # However, for the moment I'd rather not change codebook.rb, which is working just fine.
  # TODO -- revisit this.
  def describe_case_selection(req_var)
    ranges = []
    req_var.request_case_selections.each do |this_case|
      categories = this_case.categories(req_var)

      low_cat  = categories.first
      high_cat = categories.last

      if low_cat && high_cat
        if low_cat == high_cat
          if req_var.general?
            ranges << low_cat.general_code + " " + (low_cat.syntax_label ? low_cat.syntax_label : low_cat.label)
          else
            ranges << low_cat.code + " " + low_cat.label
          end
        else
          ranges << low_cat.code + "-" + high_cat.code + " " + low_cat.label + "-" + high_cat.label
        end
      end
    end

    "Case selection#{(ranges.length > 1) ? 's' : ''}:  #{ranges.join(', ')}"
  end

  def stylesheet_url
    'ipums-ddi-xslt.xsl'
  end

  def to_xml
    result = ''
    xml    = Builder::XmlMarkup.new :target => result, :indent => 2

    xml.instruct! # <?xml version="1.0" encoding="UTF-8"?>
    xml.instruct!(:'xml-stylesheet', :type => 'text/xsl', :href => stylesheet_url)
    xml.codeBook TXT['codeBook_attrs'], :ID => doc_id do
      xml.docDscr do
        describe_document(xml)
      end

      xml.stdyDscr do
        describe_study(xml)
      end

      xml.fileDscr :ID => TXT['fileDscr_ID'] do
        describe_file(xml)
      end

      xml.dataDscr do
        @er.request_variables.each do |rv|
          describe_variable(rv, xml) unless exclude_rv?(rv)
        end
      end
    end
  end

  def exclude_rv?(rv)
    @exclude_common.include?(rv.variable.mnemonic)
  end

  def describe_document(xml)
    xml.citation do
      xml.titlStmt do
        xml.titl TXT['docDscr_titl']
        xml.subTitl doc_subtitle
        xml.IDNo doc_id
      end
      xml.rspStmt do
        xml.AuthEnty TXT['docDscr_rspStmt'],
                     {:affiliation => TXT['docDscr_rspStmt_affil']}
      end
      xml.prodStmt do
        xml.producer TXT['docDscr_producer'],
                     {:abbr        => TXT['docDscr_producer_abbr'],
                      :affiliation => TXT['docDscr_producer_affil'],
                      :role        => TXT['docDscr_producer_role']}
        xml.prodDate prod_date_eng,
                     {:date => prod_date_iso}
        xml.prodPlac TXT['docDscr_prodPlac']
      end
      xml.distStmt do
        xml.contact TXT['docDscr_distStmt'],
                    {:affiliation => TXT['docDscr_distStmt_affil'],
                     :URI         => TXT['docDscr_distStmt_URI']}
      end
    end
  end

  # Yes, this is duplicative of describe_document for common elements.
  #  It's a tradeoff between clarity and D.R.Y.
  def describe_study(xml)
    xml.citation do
      xml.titlStmt do
        xml.titl "User Extract #{data_filename}"
      end
      xml.rspStmt do
        xml.AuthEnty TXT['stdyDscr_rspStmt'],
                     {:affiliation => TXT['stdyDscr_rspStmt_affil']}
      end
      xml.prodStmt do
        xml.producer TXT['stdyDscr_producer'],
                     {:abbr        => TXT['stdyDscr_producer_abbr'],
                      :affiliation => TXT['stdyDscr_producer_affil'],
                      :role        => TXT['stdyDscr_producer_role']}
        xml.prodDate prod_date_eng,
                     {:date => prod_date_iso}
        xml.prodPlac TXT['stdyDscr_prodPlac']
      end
      xml.distStmt do
        xml.contact TXT['stdyDscr_distStmt'],
                    {:affiliation => TXT['stdyDscr_distStmt_affil'],
                     :URI         => TXT['stdyDscr_distStmt_URI']}
      end
      xml.verStmt do
        xml.version :date => date
      end
    end
    xml.stdyInfo do
      xml.subject do
        study_subjects.each do |subject|
          xml.topcClas subject, {:vocab => TXT['VOCAB']}
        end
      end
      @er.request_samples.each do |rs|
        describe_summary_data rs, xml
      end
      notes_for_all_samples(xml)
    end
    xml.dataAccs do
      xml.useStmt do
        xml.no_ws! do |out|
          out.confDec :required => TXT['confDec_req'] do
            out.cdata! TXT['confDec']
          end
        end
        xml.contact TXT['dataAccs_use_contact'],
                    {:affiliation => TXT['dataAccs_use_contact_affil'],
                     :URI         => TXT['dataAccs_use_contact_uri']}
        xml.no_ws! do |out|
          out.citReq do
            out.cdata! TXT['dataAccs_use_citReq']
          end
        end
        xml.no_ws! do |out|
          out.conditions do
            out.cdata! TXT['dataAccs_use_conditions']
          end
        end
        xml.disclaimer TXT['dataAccs_use_disclaimer']
      end
    end

    # Put it in CDATA because it is tainted.
    xml.optional_cdata! :notes, @er.ddi2_title

    describe_revision_of(xml) if @er.revision_of_id
  end

  def describe_revision_of(xml)
    revised_er = ExtractRequest.find_by_id(@er.revision_of_id)
    xml.notes "This extract is a revision of the user's previous extract, number #{revised_er.revision_of.to_i}."
  end

  def describe_file(xml)
    xml.fileTxt do
      xml.fileName data_filename
      xml.fileCont TXT['fileDscr_fileCont']
      xml.fileStrc :type => @er.ddi2_fileStrc_type do
        if @er.hierarchical?
          TXT['hierarchical_groups'].each do |grp|
            xml.recGrp grp['attrs'] do
              xml.labl grp['labl']
            end
          end
        end
      end
      xml.fileType TXT['fileDscr_fileType'], {:charset => TXT['fileDscr_charset']}
      xml.format TXT['fileDscr_format']
      xml.filePlac TXT['fileDscr_filePlac']
      # xml.software '', {:version => ''}  TODO-Ben
    end
  end

  def sdatref(sample)
    sample.nil? ? nil : "sdatref-#{sample.id}"
  end

  def describe_summary_data(req_sample, xml)
    if sample = req_sample.sample
      xml.sumDscr :ID => sdatref(sample) do

        xml.timePrd sample.year, {:event => 'single'}

        if country = sample.country
          xml.nation country.full_name, {:abbr => country.short_name}
        end
      end
    end
  end

  def notes_for_all_samples(xml)
    @er.request_samples.each do |request_sample|
      xml.optional_cdata! :notes, notes_for_a_sample(request_sample)
    end
  end

  # TODO-Ben -- this code is largely copied from Codebook.rb, and should be cleaned up.
  def notes_for_a_sample(request_sample)
    sample = request_sample.sample
    out    = 'Additional notes on a sample that is part of this study:  '
    #if IPUMS::project.has_custom_density
      if sample.long_description.blank?
        out += "#{sample.country.full_name} #{sample.year.to_s}\n"
      else
        out += sample.long_description + '\n'
      end
      if sample.note && !sample.note.empty?
        out += "            Note: #{sample.note}\n"
      end
      out += "            Density of the full data file:  #{request_sample.sample.density}%\n"
      out += "            Density of this extract: " +
          (request_sample.custom_percent_density == request_sample.sample.density ?
              request_sample.sample.density.to_s : "%.1f" % request_sample.custom_percent_density) +
          "%"
    #else

    #  display_name = sample.note

    #  out += display_name + '; '
    #  out += @er.use_small_samples? ? "small size" : "regular size"
    #end
    out += "\n"
    out
  end

  def describe_variable(req_var, xml)
    var = req_var.variable

    attrs = {:ID     => req_var.long_mnemonic,
             :files  => TXT['fileDscr_ID'],
             :name   => @er.mnemonic(req_var),
             :intrvl => var.ddi2_interval}
    attrs[:dcml] = var.implied_decimal_places if var.implied_decimal_places

    if @er.hierarchical?
      if @include_common.include?(var.mnemonic)
        attrs[:rectype] = 'H P'
      else
        attrs[:rectype] = var.record_type
      end
    end

    xml.var(attrs) do
      xml.location :StartPos => req_var.start, :width => req_var.width,
                   :EndPos   => (req_var.start + req_var.width - 1)
      xml.labl req_var.full_label

      if var.ddi2_has_qstn
        xml.no_ws! do |out|
          out.qstn do
            out.optional_cdata! :qstnLit, var.ddi2_qstn_lit
            out.optional_cdata! :ivuInstr, var.ddi2_ivu_instr
          end
        end
      end

      xml.optional! :universe, var.ddi2_universe, {:clusion => 'I'}

      xml.no_ws! do |out|
        out.txt do
          out.cdata! var.ddi2_txt
        end
      end

      if var.nontabulated
        xml.optional_cdata! :codInstr, var.ddi2_code_instr
      else
        req_var.ddi2_categories(@er).each do |cat|
          xml.catgry do
            xml.catValu cat[:valu]
            xml.labl cat[:labl]
            xml.optional! :txt, cat[:txt]
            if cat[:freq]
              xml.catStat(cat[:freq], {:type => 'freq'})
            end
          end
        end
      end

      xml.concept var.variable_group.ddi2_subject, {:vocab => TXT['VOCAB']}
      xml.varFormat :schema => 'other', :type => var.ddi2_format_type

      if req_var.variable.is_dq_flag?
        xml.notes 'This variable functions as a data quality flag.'
      end
      if req_var.wants_case_selection?
        xml.notes describe_case_selection(req_var)
      end
    end
  end

  def Ddi2Codebook.load_constant_text
    metadata_path     = "#{Rails.root}/lib/metadata2"
    common_filepath   = "#{metadata_path}/ddi_txt_common.yml"
    specific_filepath = "#{metadata_path}/ddi_txt_terrapop.yml"
    common_text       = YAML::load_file common_filepath
    specific_text     = YAML::load_file specific_filepath
    common_text.merge(specific_text)
  end

  DNAME = TerrapopConfiguration['application']['environments'][Rails.env]['ddi']['domain']
  TXT   = load_constant_text
end

########
###
###   FOLLOWING §:  MIX-INS to other models to support DDI.
###

VariableGroup.class_eval do
  def ddi2_subject
    "#{name} Variables -- #{rectype_long}"
  end
end

ExtractRequest.class_eval do
  def ddi2_fileStrc_type
    hierarchical? ? 'hierarchical' : 'rectangular'
  end

  def ddi2_title
    "User-provided title: #{title}"
  end

  def ddi2_freq_sample
    request_samples.first.sample
  end
end

RequestVariable.class_eval do
  def ddi2_categories(extract_request)
    return [] if variable.nontabulated

    freqs_sample = extract_request.ddi2_freq_sample
    freqs        = freqs_sample.present? ? variable.ddi2_get_freqs(freqs_sample) : nil

    return categories.map do |c|
      if !c.informational?
        cat_code  = extract_request.category_code(self, c)
        cat_label = (self.general? && c.general_label) ? c.general_label : c.formatted_label
        if cat_label && (cat_label.length > 255)
          lbl = cat_label[0, 250] + "[...]"
          txt = "Full label: " + cat_label
        else
          lbl = cat_label
          txt = nil
        end

        result = {:valu => cat_code, :labl => lbl}
        result[:txt] = txt if txt

        if freqs && !general? && cat_code
          frequency     = freqs[cat_code.strip]
          result[:freq] = frequency ? frequency.to_s : nil
        end
        result
      else
        nil # filter out merely informational categories
      end
    end.reject { |c| c.nil? }
  end
end

Variable.class_eval do
  def ddi2_get_freqs(this_sample)

    nil
  end

  def ddi2_format_type
    data_type == "alphabetical" ? "character" : "numeric"
  end

  def ddi2_code_instr
    if manual_codes_display.nil?
      result = "This is a #{column_width}-digit numeric variable"
      if implied_decimal_places
        result += " with #{implied_decimal_places} implied decimal places"
      end
    else
      result = ddi2_transform_markup(manual_codes_display)
    end
    result
  end

  def ddi2_transform_markup(s)
    return '' if s.nil?

    s.gsub!(/\r\n?/, "\n")    # CR(LF) -> LF

    doc = IpumsXmlParsing.build_xml_doc_from_fragment(s)
    doc.search('insert_image').each do |e|
      e.swap "[Image omitted from DDI.]"
    end
    doc.search('insert_html').each do |e|
      e.swap ddi2_insert_html(e[:id])
    end
    doc.search('link').each do |e|
      e.swap(e.inner_html + ' [URL omitted from DDI.]')
    end
    s = doc.to_s

    s.gsub!(/\n\n\n/, "\n\n") # Tighten up the text

    s.gsub(/<\/?[^>]*>/, '') # strip tags
  end

  def ddi2_insert_html(id)
#    dir  = IPUMS::project.config[:included_html_dir]
#    path = dir + Link.hash[id]
    #str  = File.open(path, "r:#{METADATA_FILE_ENCODING}:UTF-8") { |f| f.read }
    str = InsertHtmlFragment.find_by_name(id)
    if  str.nil?
      raise "Problem creating DDI codebook, no insert_html_fragment with name #{id}"
    end

    return ddi2_transform_markup(str) # transform the inserted HTML
  end

  def ddi2_universe
    if sample && (sv = SampleVariable.find_by_sample_id_and_variable_id(sample.id, id))
      univ = sv.universe
      return (univ ? univ.universe_statement : nil)
    end
    nil
  end

  def ddi2_has_qstn
    sample != nil
  end

  def ddi2_txt
    ddi2_transform_markup(description)
  end

  def ddi2_interval
    nontabulated? ? 'contin' : 'discrete'
  end

  def ddi2_qstn_lit
    #ddi2_transform_markup(enumeration_form_text(true))
    ddi2_transform_markup(nil)
  end

  def ddi2_ivu_instr
    #ddi2_transform_markup(enum_instruct_text(true))
    ddi2_transform_markup(nil)
  end
end

