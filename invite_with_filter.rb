#!/usr/bin/env ruby

# Copyright (c) 2014, GoodData Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice, this list of conditions and
#        the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
#        and the following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of the GoodData Corporation nor the names of its contributors may be used to endorse
#        or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'rubygems'

require 'uri'
require 'pp'

require File.expand_path(File.dirname(__FILE__) + '/permissions')

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

unless label_idtf then
  usage($stderr); exit 1
end

dp = DataPermissions.new project_id
begin
  dp.invite user_email.downcase, role, label_idtf, values
rescue => e
  puts e.inspect
end
