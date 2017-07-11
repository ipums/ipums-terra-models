# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# encoding: UTF-8


module MarkupTransform

  def transform_markup(node)

    # special functions
    # PAGE_NUMBER_TAG = "pg";
    # FOOTNOTE_TAG = "fn";
    # FOOTNOTE_REF_TAG = "fnarg";
    # COMMENT = "comment";

    #insert_image is usa only.
    #insert_html example: ipumsi educkg
    #crvar is common in ihis

    # Whether a paragraph tag has been opened
    @markup_p_open = false
    @show_hider_count = 0

    return "" if node.nil? || node.empty?
    node.gsub!(/\r\n?/,"\n")
    doc = IpumsXmlParsing.build_xml_doc_from_fragment(node)
    "<p>#{parse_node(doc, default_text_handler)}</p>".html_safe
  end

  def default_text_handler
    Proc.new { |item| parse_text(item)}
  end

  def parse_node (node, text_handler)
    if node.children.nil?
      Rails.logger.warn "Node #{node.name} has no children"
      return ''
    end

    # svar isn't a formatting tag but includes an opening '\n'; get rid of it
    node.inner_html = node.inner_html.sub(/\n/, '') if node.name == 'svar'

    node.children.map do |e|
      e.text? ? text_handler.call(e) : parse_non_text_node(e, text_handler)
    end.join
  end

  def parse_non_text_node(e, text_handler)
    case e.name
      when 'insert_html'
        load_html_fragment(e[:id])
      when 'sample'
        ''
      when 'survey_section'
        ''
      when 'i1', 'i2', 'i3', 'title' # block styles
        "<div class=\"#{e.name}\">" + parse_node(e, text_handler) + "</div>"
      when 'b1', 'b2', 'b3' # list styles
        "<ul class=\"#{e.name}\">\n" + parse_list(e) + "\n</ul>"
      when 'em', 'pg', 'ital', 'lang', 'h1', 'h2', 'h3'  # inline styles
        "<span class=\"#{e.name}\">" + parse_node(e, text_handler) + "</span>"
      when 'insert_image'
        load_image(e[:id])
      when 'link'
        load_link(e[:id], e.inner_html)
      when 'svar', 'invar'
        link_target(e[:a],e[:v]) + parse_node(e, text_handler)
      when 'crvar'
        #"<a href=\"#{variable_path(e.inner_html.strip)}\">#{e.inner_html.strip}</a>"
        variable_path(e.inner_html.strip)
      when 'crcode'
        "<a href=\"#{codes_variable_path(e.inner_html.strip)}\">#{e.inner_html.strip}</a>"
      when 'code'
        "<div class=\"code\">Codes</div>"
      when 'topcode'
        "<div class=\"topcode\">Top codes:</div>"
      when 'bottomcode'
        "<div class=\"bottomcode\">Bottom codes:</div>"
      when 'more'
        more(e, text_handler)
      else
        attrs = e.attributes.map { |name, attr| name + (attr.value.empty? ? "" : "=\"#{attr.value}\"")}.join(" ")
        "<#{e.name} #{attrs}>" + parse_node(e, text_handler)  + "</#{e.name}>"
    end
  end

  def parse_list (node)
    out = node.children.map do |e|
  #    puts "Children are: #{e.inspect}"
      # Split lines into li's
       (e.text? ? parse_list_text(e) : parse_non_text_node(e, Proc.new {|item| parse_list_text(item) }))
    end.join
    out.gsub!(/\A\s*/, '')
    "<li>" + out +"</li>"
  end

  def parse_list_text (node)
    str = node.to_s
    str.gsub!(/\A\s*\z/, '') ## remove lines that are entirely whitespace
    str.gsub!(/\A(\s)?\s*/,'\1') ## Remove duplicate whitespace at the beginning
    str.gsub!(/\n\n+\s*/, "</li>\n\n<li>") ## break 2+ new lines into separate bullets, remove any extra whitespace
    #puts "Ret is #{str.inspect}"
    str
  end

  def parse_text (e)
    ### Svar is an enclosing tag, but we're moving it's contents outside the <a> tag for display.
    if e.parent.nil? || e.parent.xml? || e.parent.fragment? || e.parent.name == 'svar' || e.parent.name == 'more'
      format_in_paragraph e
    else
      format_not_in_paragraph e  ### This is already inside some kind of html (e.g. <div> or <ul>.)  We don't want paragraphs.
    end
  end

  def format_in_paragraph(e)
    text = e.to_s
    # puts "parsing text in paragraph '#{e.to_s}'"

    ## Remove leading double lines if the preceding tag was a block element
    previous_node = e.previous
    if block_element?(previous_node)
      text.gsub!(/\A\n+/m, '')
    end

    next_node = e.next

    # Remove leading newline if we are in a <more> tag
    text.gsub!(/\A\n/, '') if e.parent.name == 'more'

    # Remove trailing double line
    if block_element?(next_node)
      text.gsub!(/\n+\z/m, '')
    end

    start_tag = '<p class="paragraph">' # starting tag
    text = text.to_s.dup
    if text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
      @markup_p_open = true
    end

    text.gsub!(/((\A|[^\n])\n)((?=[^\n]|\z))/, '\1<br />')  # 1 newline   -> br

    #prev_node was a block node (ul, div, then start this <p>)
    if block_element?(previous_node) && !text.empty?
      text.insert 0, start_tag
      # valid because we could not have closed in text before this line.  If the logic changes above,
      #  then this may need to chagne as well
      @markup_p_open = true
    end

    #next_node is a block node (ul, div, then close this <p>)
    if block_element?(next_node) && !text.empty?
      text << "</p>\n"
      @markup_p_open = false
    end

    text
  end

  def block_element?(node)
    node && ['more', 'b1', 'b2', 'b3', 'li', 'i1', 'i2', 'i3', 'code', 'topcode', 'bottomcode'].include?(node.name)
  end

  def inside_ul?(node)
    node && node.parent && node.parent.name == 'ul'
  end

  def format_not_in_paragraph(e)
    # puts "parsing text NOT in paragraph '#{e.to_s}'"
    # puts "parent is #{e.parent.name}"
    text = e.to_s
    text.gsub!(/\n\n+/, "<br /><br />\n\n") unless inside_ul?(e) #2+ newline -> br br
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
    #text = "\n<br />" if text == "\n" # nothing but a single newline -> br
    text
  end

  def link_target (anchors, vars)
    unless anchors.nil?
      vars_to_anchor = anchors.downcase == "all" ? vars.split(/\s/) : anchors.split(/\s/)
      return vars_to_anchor.map{|v| "<a name=\"#{v}\"></a>"}.join('')
    else
      return ""
    end
  end

  def load_file(id)
    raise "Unused! Use load_html_fragment instead."
    return '' if Link.hash.empty?
    dir = IPUMS::project.config[:included_html_dir]
    path = dir + Link.hash[id]
    File.open(path).read
  end

  def load_image(id)
    href = Link.hash ? Link.hash[id] : ''
    "<img src=\"#{href}\"/>"
  end

  # Should replace load_file()
  def load_html_fragment(link_id)
    name = Link.hash[link_id]
    fragment = InsertHtmlFragment.find_by_name(name)
    if fragment.nil?
      raise "Could not find HTML fragment link ID #{link_id} with name #{name}."
    end

    fragment.content
  end

  def load_link(id, text)
    "<a href=\"#{Link.hash.empty? ? '' : Link.hash[id]}\">#{text}</a>"
  end

  def ensure_p_closed
    if @markup_p_open
      @markup_p_open = false
      return '</p>'
    end
    ''
  end

  def open_p
    @markup_p_open = true
    '<p>'
  end

  def more(e, text_handler)
    @show_hider_count += 1
    p_was_open = @markup_p_open
    result = "<a id=\"toggler-#{@show_hider_count}\" title=\"Toggle visibility\" class=\"show-hide-toggler\">&nbsp;</a>"
    result += ensure_p_closed
    result += "<div id=\"toggler-#{@show_hider_count}-target\">"
    result += open_p
    result += parse_node(e, text_handler)
    result += ensure_p_closed
    result += "</div><p></p>"
    if p_was_open
      result += open_p
    end
    result
  end
end
