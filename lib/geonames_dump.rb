require "geonames_dump/version"
require "geonames_dump/blocks"
require "geonames_dump/railtie" if defined?(Rails)

module GeonamesDump
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = self.name
      end
    end
  end

  def self.search(query, options = {})
    ret = nil
    type = options[:type] || :auto
    begin
      case type
      when :auto # return an array of features
        # city name
        ret = GeonamesCity.search(query)
        # alternate name
        ret = GeonamesAlternateName.search(query).map { |alternate| alternate.feature }.compact  if ret.blank?
        # admin1
        ret = GeonamesAdmin1.search(query) if ret.blank?
        # admin2
        ret = GeonamesAdmin2.search(query) if ret.blank?
        # feature
        ret = GeonamesFeature.search(query) if ret.blank?
      else # country, or specific type
        model = "geonames_#{type.to_s}".camelcase.constantize
        ret = model.search(query)
      end
    rescue NameError => e
      raise $!, "Unknown type for GeonamesDump, #{$!}", $!.backtrace
    end
    ret
  end

  # Search best city matches based on population and the Jaro-Winkler distance
  def self.smart_city_search(q, options = {})
    require 'amatch'
    include Amatch

    max_size = options[:max_size] || 25
    debug = options[:debug] == true

    begin
      # 1) search name in features
      ret = GeonamesCity.search(q.downcase).compact.uniq
      # 2) add search name in alternate_names & remove duplicates and nils
      ret += GeonamesAlternateName.search(q.downcase).map { |alternate| alternate.feature }.compact.uniq
      # 3) order for population desc and remove if name too distant (JaroWinkler)
      m = JaroWinkler.new(q.downcase)
      sorted = ret.map{ |r| [ r.population.to_i, m.match(r.name.downcase), r.id, r.name ] }.sort_by{|a| [-a[0]] }
      # 4) limit to top (max_size)
      small = sorted[0,max_size]
      # 5) remove too distant names (JaroWinkler < 0.75)
      small.reject!{|s| s[1] < 0.75}
      # 6) remove results that are also country (searching name in countries)
      small.reject!{|s| GeonamesCountry.find_by(country: s[-1])}
      # log small results if requested with options debug: true
      logger.info(small) if debug
      # respond with objects collection
      ids = small.map{|s| s[2]}
      GeonamesFeature.where(id: ids).sort_by{|gf| ids.index(gf.id)}
    rescue NameError => e
      raise $!, "GeonamesDump.smart_search, #{$!}", $!.backtrace
    end
  end
end
