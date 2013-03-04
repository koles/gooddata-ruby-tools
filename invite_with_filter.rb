#!/usr/bin/env ruby

require 'rubygems'

require 'uri'
require 'pp'

require 'permissions'

def usage(out = $stdout)
  out.puts "Usage: #{$0} project_id email role label_idtf value"
  out.puts
  out.puts " * project_id - project ID, e.g. d01480a4d1807af40a5d45cf57347041"
  out.puts " * email      - email address of a user to be invited"
  out.puts " * role       - a URI of the role of the invited user"
  out.puts " * label_idtf - the identifier of the label used in the data access"
  out.puts "                filtering expression."
  out.puts "                If the corresponding column in the XML data set"
  out.puts "                descriptor has ldmType 'ATTRIBUTE' and name 'xyz' and"
  out.puts "                the schema name is 'dataset', use 'label.dataset.xyz'."
  out.puts "                If the column is a label named 'xyz' pointing to the"
  out.puts "                attribute 'abc', use 'label.dataset.abc.xyz' instead."
  out.puts " * value      - the value of label_idtf that can identify rows"
  out.puts "                accessible by the user"
  out.puts
  out.puts "To avoid being asked for credentials, run 'gooddata auth:store' first"
  out.puts "to make your GoodData credentials available to the Ruby gem via the"
  out.puts ".gooddata file in your home directory."
  out.puts
end

project_id = ARGV.shift
user_email = ARGV.shift
role = ARGV.shift
label_idtf = ARGV.shift
values      = ARGV

unless values && !values.empty? then
  usage($stderr); exit 1
end

dp = DataPermissions.new project_id
begin
  dp.invite user_email.downcase, role, label_idtf, values
rescue => e
  puts e.inspect
end
