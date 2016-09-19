require 'mime-types'
require 'base64'
require 'open-uri'

module SynapsePayRest
  # should maybe create User class
  class Users
    # Should refactor this to HTTPClient
    VALID_QUERY_PARAMS = [:query, :page, :per_page].freeze

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    # refactor to automate oauth
    def refresh(payload: raise("payload is required"))
      path = "/oauth/#{@client.user_id}"
      response = @client.post(path, payload)
      client.update_headers(oauth_key: response['oauth_key']) if response['oauth_key']
      response
    end

    # return an array of all users
    def all(per_page: nil)
      get(options: {per_page: per_page})['users']
    end

    # return a specific user hash
    def find(user_id:)
      get(user_id: user_id)
    end

    # return users by name/email substring match
    def search(query:, per_page: nil)
      get(options: {query: query, per_page: per_page})['users']
    end

    # if user_id is nil returns all users
    def get(user_id: nil, options: {})
      path = create_user_path(user_id: user_id)

      if options[:user_id]
        response = client.get(path)
        client.update_headers(user_id: response['_id']) if response['_id']
        return response
      end

      # Should factor this out into HTTPClient and separate args for paginate/search(name/email)/per_page
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      # Probably should use CGI or RestClient's param builder instead of
      # rolling our own, probably error-prone and untested version
      # https://github.com/rest-client/rest-client#usage-raw-url
      path += '?' + params.join('&') if params.any?
      client.get(path)
    end

    def update(payload: raise("payload is required"))
      path = create_user_path(user_id: client.user_id)
      client.patch(path, payload)
    end

    # supports payload directly (base API use) or keyword args
    # works differently from other methods to support same method name for two different strategies
    def create(payload: {}, **args)
      payload = create_payload_from_kwargs(args) if payload.empty?

      path = create_user_path
      response = client.post(path, payload)
      client.update_headers(user_id: response['_id']) if response['_id']
      response
    end

    # deprecate
    def add_doc(payload: raise("payload is required"))
      path = create_user_path(user_id: client.user_id)
      client.patch(path, payload)
    end

    # deprecate
    def answer_kba(payload: raise("payload is required"))
      path = create_user_path(user_id: client.user_id)
      client.patch(path, payload)
    end

    # deprecate?
    def attach_file(file_path: raise("file_path is required"))
      warn caller.first + "DEPRECATION WARNING: the method SynapsePayRest::Users##{__method__} is deprecated. Use SynapsePayRest::Users::update instead."

      file_contents = open(file_path) { |f| f.read }
      content_types = MIME::Types.type_for(file_path)
      file_type = content_types.first.content_type if content_types.any?
      if file_type.nil?
        raise("File type not found. Use attach_file_with_file_type(file_path: <file_path>, file_type: <file_type>)")
      else
        attach_file_with_file_type(file_path: file_path, file_type: file_type)
      end
    end

    # deprecate
    def attach_file_with_file_type(file_path: raise("file_path is required"), file_type: raise("file_type is required"))
      path = create_user_path(user_id: @client.user_id)
      file_contents = open(file_path) { |f| f.read }
      encoded = Base64.encode64(file_contents)
      mime_padding = "data:#{file_type};base64,"
      base64_attachment = mime_padding + encoded

      payload = {
        'doc' => {
          'attachment' => base64_attachment
        }
      }
      client.patch(path, payload)
    end

    private

    def create_user_path(user_id: nil)
      path = ['/users']
      path << user_id if user_id
      path.join('/')
    end

    # needed to support both types of input for create due to method name sharing
    def create_payload_from_kwargs(email:, phone_numbers:, legal_names:, **options)
      payload = {
        'logins' => [
          {
            'email' => email
          }
        ],
        'phone_numbers' => phone_numbers,
        'legal_names' => legal_names,
        'extra' => {}
      }
      optional_fields = ['supp_id', 'note', 'is_business', 'cip_tag']
      optional_fields.each {|field| payload['extra'][field] = options[field.to_sym] if options[field.to_sym]}
      payload
    end
  end
end