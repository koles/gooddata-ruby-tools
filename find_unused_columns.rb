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
 
# The script lists unused attributes and facts in given project

require 'rubygems'
require 'gooddata'
require 'gooddata/command'
require 'pp'

project_id = ARGV.shift || raise("Usage: #{$0} project_id\n\nCall gooddata auth:store first.")
GoodData::Command.connect
GoodData.use project_id

NO_DATASET = 'NO DATASET'

unused_datasets = {}
unused_dates = {}
[ 'attributes', 'facts'].each do |col_type|
  list = GoodData.get(GoodData.project.md['query'] + "/#{col_type}")['query']['entries']
  list.each do |item|
    obj_id = item['link'].sub /^.*\//, ''
    used_by = GoodData.get("/gdc/md/#{project_id}/usedby/#{obj_id}")['usedby']['nodes']
    dependants = used_by.find_all { |n| [ 'report', 'metric', 'projectDashboard' ].include? n['category'] }
    ds = used_by.find { |n| n['category'] == 'dataSet' }
    unless ds
      warn "#{item['link']} ('#{item['title']}') is not a part of any dataset"
      ds = { 'title' => NO_DATASET }   # let's make up a fake placeholder
    end
    if ds['title'] =~ /^Date \(.*\)/   # we want to list whole date dimensions
                                       # ... but individual columns of other data sets
      output = (unused_dates[ds['title']] ||= { :used => 0, :unused => 0, :link => ds['link'] })
      output[dependants.empty? ? :unused : :used] += 1
    else
      if dependants.empty?
        ((unused_datasets[ds['title']] ||= { :link => ds['link'] })[col_type] ||= []) << item
      end
    end
  end
end

uris = []
unused_datasets.each do |ds, cols|
  uris << cols[:link]
  [ 'attributes', 'facts' ].each do |col_type|
    uris.concat cols[col_type].map { |c| c['link'] } if cols[col_type]
  end
end
unused_dates.each { |title,info| uris << info[:link] }

idtf_resp = GoodData.post GoodData.project.md['instance-identifiers'], { "uriToIdentifier" => uris }
identifiers = {}
idtf_resp['identifiers'].each { |i| identifiers[ i['uri'] ] = i['identifier'] }

unless unused_datasets.keys.empty?
  puts "UNUSED REGULAR COLUMNS"
  puts "======================"
end

unused_datasets.each do |ds, info|
  puts "#{ds}\t#{info[:link]}\t#{identifiers[info[:link]]}"
  [ 'attributes', 'facts' ].each do |col_type|
    items = info[col_type]
    if items
      puts "\t#{col_type}"
      items.each { |i| puts "\t\t#{i['link']}\t#{i['title']}\t#{identifiers[i['link']]}" }
    end
  end
  puts
end

unless unused_dates.keys.empty?
  puts "UNUSED DATE DIMENSIONS"
  puts "======================"
end

unused_dates.each do |ds, info|
  puts "\t\t#{info[:link]}\t#{ds}\t#{identifiers[info[:link]]}\n" if info[:used] == 0
end
