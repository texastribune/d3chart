
# configuration
FIXTURE = document.getElementById 'qunit-fixture'
DATA = [[]]

$FIXTURE = $ FIXTURE

module "D3Chart"


test "SVG element created", ->
  testChart = new D3Chart(FIXTURE, DATA)
  ok $FIXTURE.find('svg').length, "Fixture element should contain a SVG element."

test "Variable has basic properties", ->
  testChart = new D3Chart(FIXTURE, DATA)
  ok testChart.svg, ".svg"
  ok testChart.plot, ".plot"

test "Default options loaded when none provided", ->
  testChart = new D3Chart(FIXTURE, DATA)
  ok testChart.option('margin')

test "Provided options override defaults", ->
  options =
    margin:
      top: 0
      left: 0
  testChart = new D3Chart(FIXTURE, DATA, options)
  equal testChart.option('margin').top, options.margin.top
  equal testChart.option('margin').bottom, 30, "Assuming the default is 30,
    it's a private variable so we can't automatically pull it out to compare."

test "postRender is called", ->
  options =
    postRender: -> throw "poop"
  block = -> new D3Chart(FIXTURE, DATA, options)
  throws(block, "poop")


module "D3BarChart"

test "plot has same number of layers as number of series", ->
  testChart = new D3BarChart(FIXTURE, [[], [], [], [], []])
  equal testChart.plot.selectAll('g.layer')[0].length, 5


$legend = null
DATA = [[]]
module "Legend Tests",
  setup: ->
    $legend = $("<div/>").appendTo($FIXTURE)
  # teardown: ->
  #   del $legend

test "legend made", ->
  options =
    legend:
      enabled: true
      elem: $legend
  testChart = new D3BarChart(FIXTURE, DATA, options)
  ok testChart.legend, "Legend attribute is truthy"

test "legend titleAccessor is called", ->
  options =
    legend:
      enabled: true
      elem: $legend
      titleAccessor: -> throw "poop"
  block = -> new D3BarChart(FIXTURE, DATA, options)
  throws(block, "poop")

test "legend postRender is called", ->
  options =
    legend:
      enabled: true
      elem: $legend
      postRender: -> throw "poop"
  block = -> new D3BarChart(FIXTURE, DATA, options)
  throws(block, "poop")

test "legend order is normal", ->
  options =
    legend:
      enabled: true
      elem: $legend
  testChart = new D3BarChart(FIXTURE, [[], [], []], options)
  equal testChart.$legend.find('.legend-value').text(), "012"

test "legend color order is normal", ->
  options =
    legend:
      enabled: true
      elem: $legend
  testChart = new D3BarChart(FIXTURE, [[], [], []], options)
  should_be = testChart.option('color')(0)
  actually_is = testChart.$legend.find('.legend-key:first').css('color')
  equal d3.rgb(should_be).toString(), d3.rgb(actually_is).toString()

test "legend order can be reversed", ->
  options =
    legend:
      enabled: true
      reversed: true
      elem: $legend
  testChart = new D3BarChart(FIXTURE, [[], [], []], options)
  equal testChart.$legend.find('.legend-value').text(), "210"

test "legend color order is reversed when order is reversed", ->
  options =
    legend:
      enabled: true
      reversed: true
      elem: $legend
  testChart = new D3BarChart(FIXTURE, [[], [], []], options)
  should_be = testChart.option('color')(2)
  actually_is = testChart.$legend.find('.legend-key:first').css('color')
  equal d3.rgb(should_be).toString(), d3.rgb(actually_is).toString()

