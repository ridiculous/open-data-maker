module DataMagic
  module QueryBuilder
    class << self
      # Creates query from parameters passed into endpoint
      def from_params(params, options, config)
        per_page = params.delete(:per_page) || config.page_size
        page = params.delete(:page).to_i || 0
        query_hash = {
          from:   page * per_page.to_i,
          size:   per_page.to_i
        }
        query_hash[:query] = generate_squery(params, config).to_search
        query_hash[:fields] = get_restrict_fields(options) if options[:fields] && !options[:fields].empty?
        query_hash[:sort] = get_sort_order(options) if options[:sort]
        query_hash
      end

      private

      def generate_squery(params, config)
        squery = Stretchy.query(type: 'document')
        squery = search_location(squery, params)
        search_fields_and_ranges(squery, params)
      end

      def get_restrict_fields(options)
        options[:fields].map { |field| field.to_s }
      end

      def get_sort_order(options)
        key, value = options[:sort].split(':')
        return { key => { order: value } }
      end

      def to_number(value)
        value =~ /\./ ? value.to_f : value.to_i
      end

      def search_fields_and_ranges(squery, params)
        params.each do |field, value|
          if match = /(.+)__(range|ne|not)\z/.match(field)
            var_name, operator = match.captures.map(&:to_sym)
            if operator == :ne or operator == :not  # field negation
              squery = squery.where.not(var_name => value)
            else  # field range
              squery = squery.filter({
                or: build_ranges(var_name, value.split(','))
              })
            end
          else # field equality
            squery = squery.where(field => value)
          end
        end
        squery
      end

      def build_ranges(var_name, range_strings)
        range_strings.map do |range|
          min, max = range.split('..')
          values = {}
          values[:gte] = to_number(min) if !min.empty?
          values[:lte] = to_number(max) if max
          {
            range: {
              var_name => values
            }
          }
        end
      end

      # Handles location (currently only uses SFO location)
      def search_location(squery, params)
        distance = params[:distance]
        if distance && !distance.empty?
          location = { lat: 37.615223, lon:-122.389977 } #sfo
          squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
          params.delete(:distance)
          params.delete(:zip)
        end
        squery
      end

    end

  end

end
