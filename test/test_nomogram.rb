require 'nomogram'

require 'test/unit'
require 'rubygems'
require 'ruby-debug'
require 'hpricot'

class TestNomogram < Test::Unit::TestCase
  def create_nomogram(options = {})
    Nomogram.new(File.dirname(__FILE__)+"/fixtures/data.yml", options)
  end

  def test_handles_points
    nom = create_nomogram
    field = nom.fields.first
    assert_equal 'Points', field.name
    assert_equal 0, field.offset
    assert_equal 800, field.width
    assert_equal [
      ['0', 0],
      ['10', 80],
      ['20', 160],
      ['30', 240],
      ['40', 320],
      ['50', 400],
      ['60', 480],
      ['70', 560],
      ['80', 640],
      ['90', 720],
      ['100', 800],
    ], field.ticks
  end

  def test_handles_age
    nom = create_nomogram
    field = nom.fields[1]
    assert_equal 'Age', field.name
    assert_equal 0, field.offset
    assert_equal 408, field.width
    assert_equal [
      ['40', 0],
      ['45', 68],
      ['50', 136],
      ['55', 204],
      ['60', 272],
      ['65', 340],
      ['70', 408]
    ], field.ticks
    assert field.continuous?
  end

  def test_handles_family_history_boolean
    nom = create_nomogram
    field = nom.fields[2]
    assert_equal 'Family history(allergy)', field.name
    assert_equal 0, field.offset
    assert_equal 209, field.width
    assert_equal [
      ['No', 0],
      ['Yes', 209]
    ], field.ticks
    assert !field.continuous?
  end

  def test_handles_total_points
    nom = create_nomogram
    field = nom.fields[-2]
    assert_equal 'Total Points', field.name
    assert_equal 0, field.offset
    assert_equal 800, field.width
    assert_equal [
      ['0', 0],
      ['50', 133],
      ['100', 266],
      ['150', 400],
      ['200', 533],
      ['250', 666],
      ['300', 800]
    ], field.ticks
  end

  def test_handles_probability
    nom = create_nomogram
    field = nom.fields[-1]
    assert_equal 'Probability of asthma', field.name
    assert_equal -11, field.offset
    assert_equal 727, field.width
    assert_equal [
      ['0.15', 0],
      ['0.25', 133],
      ['0.35', 234],
      ['0.45', 321],
      ['0.55', 405],
      ['0.65', 493],
      ['0.75', 594],
      ['0.85', 727]
    ], field.ticks
  end

  def test_field_slug
    nom = create_nomogram
    expected = %w{points age family-history-allergy ever-wheezing current-asthma-medication ever-asthma ever-allergic-rhinitis total-points probability-of-asthma}
    assert_equal expected, nom.fields.collect(&:slug)
  end

  def test_build
    nom = create_nomogram
    fields = nom.fields
    doc = Hpricot(nom.build)
    divs = doc / "div.field"
    assert_equal 9, divs.length
    divs.each_with_index do |field, i|
      assert_equal fields[i].slug, field['id']
      assert_equal fields[i].name, (field/"div.name").inner_html

      meter = field.at("div.meter")
      assert meter
      assert_equal "width: #{fields[i].width}px; margin-left: #{fields[i].offset}px;", meter['style']

      ticks = meter / "div.tick"
      assert_equal fields[i].ticks.count, ticks.count
      ticks.each_with_index do |tick, j|
        field_tick = fields[i].ticks[j]

        label = tick.at("div.label")
        assert label
        assert_equal field_tick[0], label.inner_html

        assert_equal "left: #{field_tick[1]}px;", tick['style']
      end
    end
    assert_equal 9, (doc / "div.clear").count
  end

  def test_build_layout
    nom = create_nomogram
    nom.title = "Adult Asthma Risk Calculator"
    doc = Hpricot(nom.build)
    assert_equal "Adult Asthma Risk Calculator", (doc/"h1").inner_html
  end
end
