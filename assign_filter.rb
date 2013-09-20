#!/usr/bin/env ruby

require 'rubygems'

require 'uri'
require 'optparse'
require 'pp'

require File.expand_path(File.dirname(__FILE__) + '/permissions')

def usage(out = $stdout)
  out.puts "Usage: #{$0} project_id email label_idtf [ value [ value2 ... ] ]"
  out.puts
  out.puts " * project_id - project ID, e.g. d01480a4d1807af40a5d45cf57347041"
  out.puts " * email      - specifies the user whose permissions are restricted"
  out.puts " * label_idtf - the identifier of the label used in the data access"
  out.puts "                filtering expression."
  out.puts "                If the corresponding column in the XML data set"
  out.puts "                descriptor has ldmType 'ATTRIBUTE' and name 'xyz' and"
  out.puts "                the schema name is 'dataset', use 'label.dataset.xyz'."
  out.puts "                If the column is a label named 'xyz' pointing to the"
  out.puts "                attribute 'abc', use 'label.dataset.abc.xyz' instead."
  out.puts "                If value is missing, this parameter is interpreted as"
  out.puts "                a filtering expression. Strings within `` are replaced"
  out.puts "                with attribute URIs, string with \"\" are treated as"
  out.puts "                attribute values."
  out.puts " * value      - the value of label_idtf that can identify rows"
  out.puts "                accessible by the user"
  out.puts "To avoid being asked for credentials, run 'gooddata auth:store' first"
  out.puts "to make your GoodData credentials available to the Ruby gem via the"
  out.puts ".gooddata file in your home directory."
  out.puts
end

project_id = ARGV.shift
user_email = ARGV.shift
label_idtf = ARGV.shift
values     = ARGV

unless label_idtf then
  usage($stderr); exit 1
end

dp = DataPermissions.new project_id
begin
  dp.add user_email.downcase, label_idtf, values
rescue => e
  puts e.inspect
end
