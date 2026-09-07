#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "open3"

ATTRIBUTE_TO_PLACEHOLDER = {
  "confidential-label" => "CONFIDENTIAL_LABEL",
  "document-number" => "DOCUMENT_NUMBER",
  "product-name" => "PRODUCT_NAME",
  "cover-footer-text" => "COVER_FOOTER_TEXT",
  "date" => "FIELD_1_VALUE",
  "revision" => "FIELD_2_VALUE"
}.freeze

def read_adoc_attributes(path)
  File.readlines(path, chomp: true, encoding: "UTF-8").each_with_object({}) do |line, attributes|
    match = line.match(/^:([a-z0-9_-]+):(?:\s+(.*))?$/)
    attributes[match[1]] = match[2] || "" if match
  end
end

def git_output(document, *arguments)
  output, status = Open3.capture2e("git", "-C", File.dirname(document), *arguments)
  abort "revision is GITHASH, but the Git commit hash could not be determined" unless status.success?

  output
rescue Errno::ENOENT
  abort "revision is GITHASH, but Git is not installed"
end

def resolve_revision(value, document)
  return value unless value == "GITHASH"

  revision = git_output(document, "rev-parse", "--short=12", "HEAD").strip
  status = git_output(document, "status", "--porcelain", "--untracked-files=no")
  status.empty? ? revision : "#{revision}-dirty"
end

def resolve_date(value)
  return value unless value == "BUILDDATE"

  today = Date.today
  "#{Date::MONTHNAMES[today.month]} #{today.day}, #{today.year}"
end

def main
  unless ARGV.length == 4 && ARGV[2] == "--adoc"
    abort "usage: render_cover.rb TEMPLATE OUTPUT --adoc DOCUMENT"
  end

  template, output, _, document = ARGV
  source = File.read(template, encoding: "UTF-8")
  attributes = read_adoc_attributes(document)
  attributes["date"] = resolve_date(attributes.fetch("date", ""))
  attributes["revision"] = resolve_revision(attributes.fetch("revision", ""), document)
  replacements = {"FIELD_1_LABEL" => "DATE", "FIELD_2_LABEL" => "REVISION"}
  ATTRIBUTE_TO_PLACEHOLDER.each do |attribute, placeholder|
    replacements[placeholder] = attributes.fetch(attribute, "")
  end
  replacements.each do |placeholder, value|
    source = source.gsub("@#{placeholder}@", CGI.escapeHTML(value))
  end
  File.write(output, source, encoding: "UTF-8")
end

main if $PROGRAM_NAME == __FILE__
