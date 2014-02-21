module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    settings YAML.load_file("#{Rails.root.to_s}/config/elasticsearch.yml")

    # Override model name
    index_name    "employees"
    document_type "employee"

    mappings dynamic: 'false' do
      indexes :username, analyzer: 'simple'
      indexes :displayname, analyzer: 'simple'
      indexes :name_suggest, index_analyzer: 'displayname_index', search_analyzer: 'displayname_search'
      indexes :phone, analyzer: 'phone_number'
      indexes :cell_phone, analyzer: 'phone_number'
      indexes :company_short, analyzer: 'simple'
      indexes :department, analyzer: 'simple'
    end
  end

  def as_indexed_json(options={})
    {
      id: id,
      username: username,
      displayname: displayname,
      company_short: company_short,
      department: department,
      phone: phone,
      cell_phone: cell_phone,
      name_suggest: "#{first_name}#{last_name} #{last_name}#{first_name} #{username}"
    }.as_json
  end

  module ClassMethods
    def suggest(query)
      query = sanitize_query(query)
      __elasticsearch__.search({
        size: 10,
        fields: [
          "displayname",
          "username",
          "department",
          "company_short"
        ],
        query: {
          multi_match: {
            fields: [
              "name_suggest"
            ],
            query: query,
            fuzziness: 2,
            prefix_length: 0
          }
        }
      })
    end

  private

    # NOTE: The sanitizer does not allow grouping and operators in the query
    def sanitize_query(query)
      # Remove Lucene reserved characters
      query.gsub!(/([#{Regexp.escape('\\+-&|!(){}[]^~*?:/"\'')}])/, '')

      # Remove Lucene operators
      query.gsub!(/\s+\b(AND|OR|NOT)\b/i, '')
      query
    end
  end
end
