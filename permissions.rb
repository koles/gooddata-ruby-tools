#!/usr/bin/env ruby

require 'rubygems'

require 'uri'
require 'pp'

require 'gooddata'
require 'gooddata/command'

module GoodData
  class MdObject
    def [](key)
      @json[key]
    end
  end
end

class DataPermissions

  # @param project_id the ID of the project where we want to restrict someone's
  #        access to data
  def initialize(project_id)
    @project_id = project_id
    GoodData::Command.connect
    GoodData.use project_id
  end

  # Creates a data permission for the specified user or overwrites
  # an existing one.
  #
  # TODO: a more generic version with parameters user_email and expression
  #       where expression may be "{label.customer.id} = '12345'" or even
  #       "{label.customer.region} IN ('West', 'East')"
  #
  # @param user_email whose permissions are configured
  # @param label identifier of the filtered column
  # @param value filtered value
  def add(user_email, label, value)
    user_url = find_user user_email
    lbl_obj  = GoodData::MdObject[label]
    attr_url = lbl_obj['content']['formOf']
    values = value.is_a?(Array) ? value : [ value ]
    value_urls = values.map { |v| value2uri(lbl_obj, v) }
    filter_resp = create_filter "#{label} = #{value}", attr_url, value_urls
    result = set_user_filter user_url, filter_resp['uri']
    pp result
  end

  private

  # Create a GoodData object holding the "key = value" filtering expression
  #
  # @param title human readable object name
  # @param object_url the 'key' part of the filtering expression
  # @param value_url the 'value' part of the filtering expression
  def create_filter(title, object_url, value_urls)
    in_expr = value_urls.map { |u| "[#{u}]" }.join(',')
    filter = {
      "userFilter" => {
        "content" => {
          "expression" => "[#{object_url}] IN (#{in_expr})"
        },
        "meta" => {
          "category" => "userFilter",
          "title" => title
        }
      }
    }
    puts filter
    GoodData.post "/gdc/md/#{@project_id}/obj", filter
  end

  # Associate the referenced filter with the referenced user
  # @param user_url a reference to the user to be assigned a data permission filter
  # @param filter_url a reference to the filter object previously created in the
  #         create_filter method
  def set_user_filter(user_url, filter_url)
    user_filter = {
      "userFilters" => {
        "items" => [
          {
            "user" => user_url,
            "userFilters" => [ filter_url ]
          }
        ]
      }
    }
    GoodData.post "/gdc/md/#{@project_id}/userfilters", user_filter
  end

  # Returns a GoodData URI representing the user specified by the email
  # address.
  # @throw ArgumentError if the user is not the project member
  def find_user(email)
    url  = "/gdc/projects/#{@project_id}/users"
    resp = GoodData.get url
    resp['users'].each do |u|
      user = u['user']
      return user['links']['self'] if user['content']['email'] == email
    end
    raise ArgumentError.new "User '#{email}' is not a member of project '#{@project_id}'"
  end

  # Returns a GoodData URI representing the value of given label
  def value2uri(label, value)
    elements_url  = label['links']['elements']
    uri  = "#{elements_url}?filter=#{URI::encode value}"
    resp = GoodData.get uri
    elements = resp['attributeElements']['elements']
    if elements && !elements.empty?
      matching = resp['attributeElements']['elements'].find { |e| e['title'] == value }
      return matching['uri'] if matching
    end
    raise "Value '#{value}' not found for label '#{label}'"
  end
end

def usage(out = $stdout)
  out.puts "Usage: #{$0} project_id email label_idtf value"
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
label_idtf = ARGV.shift
values      = ARGV

unless values && !values.empty? then
  usage($stderr); exit 1
end

dp = DataPermissions.new project_id
dp.add user_email, label_idtf, values
