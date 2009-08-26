require 'erb'
require 'yaml'

class Nomogram
  class Field
    attr_reader :name, :ticks, :offset, :width, :slug

    def initialize(name, values, scale)
      @name = name
      @slug = name.downcase.gsub(/[\W]/, " ").strip.gsub(/\s+/, "-")
      @values = values
      @scale = scale
      @ticks = []
      @offset = 0
      @count = values.first[1].is_a?(Array) ? values.first[1].count : values.count

      create_ticks
      @width = @ticks.last[1]
    end

    private
      def create_ticks
        data = []
        @count.times do |i|
          label = label_for(i)
          label = case label
                  when "true" then "Yes"
                  when "false" then "No"
                  else label
                  end
          data << [label, offset_for(i)]
        end
        data.sort! { |a, b| a[1] <=> b[1] }

        data.each_with_index do |(label, offset), i|
          @offset = offset if i == 0
          @ticks << [label, offset - @offset]
        end
      end

      def label_for(i)
        @values.first[1][i].to_s
      end

      def offset_for(i)
        (@values.last[1][i] * @scale / 100).floor
      end

  end

  class Points < Field
    def initialize(scale)
      super("Points", (0..10).collect {|i| i*10}, scale)
    end

    private
      def label_for(i)
        @values[i].to_s
      end

      def offset_for(i)
        (@values[i] * @scale / 100).floor
      end
  end

  class TotalPoints < Field
    attr_reader :max_points

    def initialize(values, scale)
      super("Total Points", values, scale)
      @max_points = values.first[1].last
    end

    private
      def offset_for(i)
        (i * @scale / (@count - 1)).floor
      end
  end

  class Probability < Field
    def initialize(names, values, scale, max_points)
      @max_points = max_points
      super(names, values, scale)
    end

    private
      def offset_for(i)
        (@values.first[1][i] * @scale / @max_points).floor
      end

      def label_for(i)
        @values.last[1][i].to_s
      end
  end

  attr_reader :fields

  def initialize(config, options = {})
    @data  = YAML.load_file(config)
    @scale = options[:scale] || 800
    @fields = [ Points.new(@scale) ]

    prepare_fields
  end

  def build
    ERB.new(open(File.dirname(__FILE__)+"/../views/nomogram.html.erb").read, nil, "-").result(binding)
  end

  private
    def prepare_fields
      @data.each do |info|
        name, values = info
        next  if %w{abbrev lp}.include?(name)

        if values.has_key?('x')
          if name == "total.points"
            field = @total_points = TotalPoints.new(values, @scale)
          else
            field = @probability = Probability.new(name, values, @scale, @total_points.max_points)
          end
        else
          field = Field.new(name, values, @scale)
        end
        @fields << field
      end
    end
end