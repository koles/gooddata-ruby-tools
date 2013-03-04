#!/usr/bin/env ruby
# 
# The script lists unused attributes and facts in given project

require 'rubygems'
require 'gooddata'
require 'gooddata/command'

project_id = ARGV.shift || raise("Usage: #{$0} project_id\n\nCall gooddata auth:store first.")
GoodData::Command.connect
GoodData.use 'emfcovv1rv0bsj13272dryzgptin2sd6'

unused_datasets = {}
unused_dates = {}
[ 'attributes', 'facts'].each do |col_type|
  puts "col_type = #{col_type}"
  list = GoodData.get(GoodData.project.md['query'] + "/#{col_type}")['query']['entries']
  list.each do |item|
    puts "\t#{item['link']}\t#{item['title']}"
    obj_id = item['link'].sub /^.*\//, ''
    used_by = GoodData.get("/gdc/md/#{project_id}/usedby/#{obj_id}")['usedby']['nodes']
    ms_and_rs = used_by.find_all { |n| [ 'report', 'metric'].include? n['category'] }
    puts "\t... found #{ms_and_rs.length} metrics or reports"
    ds = used_by.find { |n| n['category'] == 'dataSet' }
    if ds['title'] =~ /^Date \(.*\)/  # we want to list whole date dimensions
                                       # ... but individual columns of other data sets
      output = (unused_dates[ds['title']] ||= { :used => 0, :unused => 0 })
      output[ms_and_rs.empty? ? :unused : :used] += 1
    else
      if ms_and_rs.empty?
        ((unused_datasets[ds['title']] ||= {})[col_type] ||= []) << item
      end
    end
  end
end

unless unused_datasets.keys.empty?
  puts "UNUSED REGULAR COLUMNS"
  puts "======================"
end

unused_datasets.each do |ds, by_type|
  puts ds
  by_type.each do |col_type, items|
    puts "\t#{col_type}"
    items.each { |i| puts "\t\t#{i['link']}\t#{i['title']}" }
  end
  puts
end

unless unused_dates.keys.empty?
  puts "UNUSED DATE DIMENSIONS"
  puts "======================"
end

unused_dates.each do |ds, info|
  puts "#{ds}\n" if info[:used] == 0
end
