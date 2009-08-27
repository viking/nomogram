require 'erb'
require 'yaml'

class Nomogram
  class Field
    attr_reader :name, :ticks, :offset, :width, :slug, :points, :type

    def initialize(name, values, scale)
      @name = name
      @slug = name.downcase.gsub(/[\W]/, " ").strip.gsub(/\s+/, "-")
      @values = values
      @scale = scale
      @ticks = []
      @points = []
      @offset = 0
      @type = self.class.to_s.split(/::/).last.downcase
      @count = values.first[1].is_a?(Array) ? values.first[1].count : values.count

      create_ticks
      @width = @ticks.last[1]
    end

    def boolean?
      @boolean ||= @ticks.count == 2 && (%w{Yes No} - @ticks.collect{ |x| x[0] }).empty?
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
          points = points_for(i)
          data << [label, offset_for(points), points]
        end
        data.sort! { |a, b| a[2] <=> b[2] }

        data.each_with_index do |(label, offset, points), i|
          @offset = offset if i == 0
          @ticks << [label, offset - @offset]
          @points << points
        end
      end

      def label_for(i)
        @values.first[1][i].to_s
      end

      def points_for(i)
        @values.last[1][i]
      end

      def offset_for(points)
        (points * @scale / 100).floor
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

      def points_for(i)
        @values[i]
      end
  end

  class TotalPoints < Field
    attr_reader :max_points

    def initialize(values, scale)
      @max_points = values.first[1].last
      super("Total Points", values, scale)
    end

    private
      def points_for(i)
        @values.first[1][i] * 100 / @max_points
      end
  end

  class Probability < Field
    def initialize(names, values, scale, max_points)
      @max_points = max_points
      super(names, values, scale)
    end

    private
      def points_for(i)
        @values.first[1][i] * 100 / @max_points
      end

      def label_for(i)
        @values.last[1][i].to_s
      end
  end

  attr_reader :fields, :content_for_layout
  attr_accessor :title

  def initialize(config, options = {})
    @data  = YAML.load_file(config)
    @scale = options[:scale] || 800
    @fields = [ Points.new(@scale) ]

    prepare_fields
  end

  def build
    template = open(File.dirname(__FILE__)+"/../views/nomogram.html.erb").read
    layout   = open(File.dirname(__FILE__)+"/../views/layout.html.erb").read
    @content_for_layout = ERB.new(template, nil, "-").result(binding)
    ERB.new(layout, nil, "-").result(binding)
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
