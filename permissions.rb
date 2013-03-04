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
  # @param value filtered value(s)
  def add(user_email, label, value)
    user_url = find_user user_email
    filter_url = prepare label, value
    result = set_user_filter user_url, filter_url
    pp result
  end

  # Sends an invitation associated with a mandatory user filter
  # @param email user to be invited
  # @param label identifier of the filtered column
  # @param value filtered value(s)
  def invite(email, role, label, value)
    filter_url = prepare label, value
    invitation = {
      "invitations" => [ {
        "invitation" => {
          "content" => {
            "email" => email,
            "userFilters" => [ filter_url ],
            "role" => role
          }
        }
      } ]
    }
    pp invitation
    GoodData.post "/gdc/projects/#{@project_id}/invitations", invitation
  end

  # Prepares the mandatory user filter object for an assignment to a user
  # or an invitation. Returns the URI of a created user filter object.
  #
  # @param label identifier of the filtered column
  # @param value filtered value(s)
  def prepare(label, value)
    lbl_obj  = GoodData::MdObject[label]
    attr_url = lbl_obj['content']['formOf']
    values = value.is_a?(Array) ? value : [ value ]
    value_urls = values.map { |v| value2uri(lbl_obj, v) }
    filter_resp = create_filter "#{label} = #{value}", attr_url, value_urls
    return filter_resp['uri']
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
