require 'rubygems'

require 'uri'
require 'pp'
require 'json'

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
  # @param value filtered value(s)
  def add(user_email, label_or_expression, value = nil)
    user_url = find_user user_email
    muf = prepare label_or_expression, value
    result = set_user_filter user_url, muf[:url]
    pp result
  end

  # Sends an invitation associated with a mandatory user filter
  # @param email user to be invited
  # @param label identifier of the filtered column
  # @param value filtered value(s)
  def invite(email, role, label_or_expression, value)
    muf = prepare label_or_expression, value

    invitation = {
      "invitations" => [ {
        "invitation" => {
          "content" => {
            "email" => email,
            "userFilters" => [ muf[:url] ],
            "role" => role
          }
        }
      } ]
    }
    pp invitation
    GoodData.post "/gdc/projects/#{@project_id}/invitations", invitation
  end

  def prepare(label_or_expression, value = nil)
    if value && (!value.is_a?(Array) || !value.empty?) then
      expression = build_simple_expression(label_or_expression, value)
      mufname    = "#{label_or_expression} = #{value}"
    else
      expression = parse_expression(label_or_expression)
      mufname    = label_or_expression
    end
    filter_resp = create_filter mufname, expression
    filter_url = filter_resp['uri']
    return { :url => filter_url, :name => mufname }
  end

  def build_simple_expression(label, value)
    lbl_obj  = GoodData::MdObject[label] or raise "No object found for identifier '#{label}'"
    attr_url = lbl_obj['content']['formOf'] rescue raise("Object '#{label} is not a label'")
    values = value.is_a?(Array) ? value : [ value ]
    value_urls = values.map { |v| value2uri(lbl_obj, v) }
    in_expr = value_urls.map { |u| "[#{u}]" }.join(',')
    "[#{attr_url}] IN (#{in_expr})"
  end

  def parse_expression(src)
    last_label = nil
    src.gsub( /`[^`]+`|"[^"]+"/ ).each do |i|
      if (match = i.match(/^`([^`]+)`$/)) then
        idtf = match.captures[0] or raise "No identifier found in #{i}"
        obj =  GoodData::MdObject[idtf] or raise "No object with identifier #{idtf} found"
        if obj['meta']['category'] == 'attributeDisplayForm'
          last_label = obj # future values use this label
          '[' + obj['content']['formOf'] + ']'
        elsif obj['meta']['category'] == 'attribute'
          last_label = nil # future values need a new label
          '[' + obj['meta']['uri'] + ']'
        else
          raise "Unexpected object category #{obj['meta']['category']} for identifier '#{idtf}'"
        end
      elsif (match = i.match(/^"([^"]+)"$/)) then
        value = match.captures[0] or raise "No value found in #{i}"
        raise "Unknown label for value '#{value}'" unless last_label
        '[' + value2uri(last_label, value) + ']'
      end
    end
  end

  private

  # Create a GoodData object holding the "key = value" filtering expression
  #
  # @param title human readable object name
  # @param expression MUF expression using URIs rather than human readable
  #         identifiers
  def create_filter(title, expression)
    filter = {
      "userFilter" => {
        "content" => {
          "expression" => expression
        },
        "meta" => {
          "category" => "userFilter",
          "title" => title
        }
      }
    }
    puts filter.to_json
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
      if user['content']['email'] == email
        return user['links']['self']
      end
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
