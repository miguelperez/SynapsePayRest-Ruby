module SynapsePayRest
  # Ancestor of physical/social/virtual document types.
  # 
  # @todo refactor this as a mixin since it shouldn't be instantiated.
  class Document

    # @!attribute [rw] base_document
    #   @return [SynapsePayRest::BaseDocument] the base document to which the document belongs
    # @!attribute [rw] status
    #   @return [String] https://docs.synapsepay.com/docs/user-resources#section-document-status
    attr_accessor :base_document, :status, :id, :type, :value, :last_updated

    class << self
      # Creates a document instance but does not submit it to the API. Use
      # BaseDocument#create/#update/#add_physical_documents or related methods
      # to submit the document to the API.
      # 
      # @note This should only be called on subclasses of Document, not on 
      #   Document itself.
      # 
      # @param type [String]
      # @param value [String]
      # 
      # @return [SynapsePayRest::Document]
      # 
      # @see https://docs.synapsepay.com/docs/user-resources#section-physical-document-types physical document types
      # @see https://docs.synapsepay.com/docs/user-resources#section-social-document-types social document types
      # @see https://docs.synapsepay.com/docs/user-resources#section-virtual-document-types virtual document types
      def create(type:, value:)
        raise ArgumentError, 'type must be a String' unless type.is_a?(String)
        raise ArgumentError, 'value must be a String' unless type.is_a?(String)

        self.new(type: type, value: value)
      end

      # @note Do not call this method. It is used by child classes only.
      def from_response(data)
        self.new(
          type:         data['document_type'],
          id:           data['id'],
          status:       data['status'],
          last_updated: data['last_updated']
        )
      end
    end

    # @note Do not instantiate directly. User #create on subclasses.
    def initialize(type:, **options)
      @type         = type.upcase
      # only exist for created (not for fetched)
      @id           = options[:id]
      @value        = options[:value]
      # only exist for fetched data
      @status       = options[:status]
      @last_updated = options[:last_updated]
    end

    # Checks if two Document instances have same id (different instances of same record).
    def ==(other)
      other.instance_of?(self.class) && !id.nil? &&  id == other.id 
    end

    # Converts the document into hash format for use in request JSON.
    # @note You shouldn't need to call this directly.
    # 
    # @return [Hash]
    def to_hash
      {'document_value' => value, 'document_type' => type}
    end
  end
end
