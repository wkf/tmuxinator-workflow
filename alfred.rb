require 'nokogiri'
require 'fuzzy_match'

module Alfred
  class Source
    def candidates
      []
    end

    def filter(seed)
      unless seed.empty?
        FuzzyMatch.new(candidates, :read => :title).find_all(seed)
      else
        candidates
      end
    end

    def default
    end
  end

  class << self
    attr_accessor :logger

    def register_source(name, source)
      @sources ||= {}
      @sources[name] = source
    end

    def filter(*sources, seed)
      builder = Nokogiri::XML::Builder.new do |x|
        x.items do
          sources.each do |s|
            candidates = @sources[s].new.filter(seed) || []
            candidates.each do |c|
              x.item :arg => "#{s}:#{c[:arg] || c[:title]}" do
                x.title c[:title]
                x.subtitle c[:subtitle]
                x.icon('/Applications/iTerm.app', :type => 'fileicon')
              end
            end
          end
        end
      end

      puts builder.to_xml
    end

    def action(action, target)
      s, arg = target.split ':'
      logger.info 'hello'

      @sources[s].new.send(action.to_sym, arg)
    end
  end
end
