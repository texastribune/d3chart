
# configuration
FIXTURE = document.getElementById 'qunit-fixture'
DATA = []

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
