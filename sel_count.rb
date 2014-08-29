#!/usr/bin/env ruby
require 'colorize'
require 'fileutils'

module GrepResult
  class Match
    attr_reader :line_number
    attr_reader :file_path
    attr_reader :match_text

    def initialize(params)
      @line_number = params[:line_number]
      @file_path = params[:file_path]
      @match_text = params[:match_text]
    end
  end
end

BASE_GREP = 'grep --include=*.{css,scss,css.erb} -r'

search_path = ARGV[0] || '.'
selector_count = ARGV[1] || 3

sel_regex = '\([^ ,]\{2,\}\ \)\{' + selector_count.to_s + ',\}.*{$'

grep_results = `bash -c '#{BASE_GREP} -ne \"#{sel_regex}\" #{search_path}'`

matches = []

grep_results.each_line do |line|
  file_path = line.match(/^(.*)\:[0-9]+\:/)[1]
  line_number = line.match(/\:([0-9]+)\:/)[1]
  match_text = line.match(/\:[0-9]+\:(.*)$/)[1]
  
  arguments = { 
    :file_path => file_path,
    :line_number => line_number,
    :match_text => match_text
  }
  
  matches << GrepResult::Match.new(arguments)
end

grouped_matches = matches.group_by(&:file_path).sort_by{|match| match[1].count}.reverse
file_count = grouped_matches.count
instance_count = matches.count

output_strings = []
output_strings <<  "Found #{instance_count.to_s.bold.red} instances of #{selector_count.to_s.bold.magenta} or more in #{file_count.to_s.cyan.bold} files.\n"

grouped_matches.each do |gm|
  output_strings << "  #{gm[0].cyan.bold} (#{gm[1].count.to_s.green.bold} instances)"
  gm[1,].each do |m|
    output_strings << "    #{m.line_number.green}: #{m.match_text.bold.red}"
  end
end

output_string = output_strings.join('\n')
if instance_count != 0
  system("echo '#{output_string}' | less -R")
else
  puts output_string
end
