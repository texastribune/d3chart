# Homepage:
# [github.com/texastribune/d3chart](https://github.com/texastribune/d3chart)
#
# # Examples
#
# * [Trivial Empty Chart](http://bl.ocks.org/3805925)
# * [Stacked Bar Chart](http://bl.ocks.org/3802316)
do ($=jQuery, d3=d3, exports=window) ->

  # # Configuration

  # These are the default options that get overriden when initialized.
  defaultOptions =
    # By default, any colors needed will be taken from `d3.scale.category10()`.
    # For convenience, you can also pass in an array of values like:
    # `['#000', '#333', '#c3c', '#3cc']`.
    # If you need more, like reading colors from a hash, you can override
    # `getLayerFillStyle` to get that functionality.
    colors: d3.scale.category10()
    # Margin is space between the edge of the plot and the containing element.
    # TODO: this is really more like padding, and needs to play with axes better.
    margin:
      top: 10
      right: 0
      bottom: 30
      left: 50

    # You can define custom accessors to match the input data
    accessors:
      # How to get bar data from the layer data
      bars: (d) -> d
      # If you set a color accessor, your color above should be an Object
      colors: undefined

    # Tooltips currently rely on a version bootstrap's tooltips hacked to
    # work with SVG.
    # TODO: make this logic look more like d3 and allow different tooltip
    # libraries
    tooltip:
      enabled: false
      format: ->
        d = @__data__
        d.title || d.y
    # Control the display of the x-axis.
    # If you need a custom format, specify it like:
    #
    #     format: function(d) { return d3.format(".2f")(d) + "%"; }
    xAxis:
      enabled: false
      title: ""
      format: undefined
    # Control the display of the y-axis.
    # Same parameters as the x-axis.
    yAxis:
      enabled: false
      title: ""
      format: undefined
      min: undefined
      max: undefined
    # If you want to display a legend, you need to enable this and
    # also specify a valid DOM element to generate the legend in.
    legend:
      enabled: false
      element: undefined  # can be a DOM element, jQuery element, or string to the ID
      reversed: false  # bottom-to-top, or top-to-bottom
      titleAccessor: undefined  # function that takes (d, i) and returns a string
      # Events that can be attached to the legend.
      # The arguments the handler receives are documented to the right.
      click: undefined  # (d, i, this)
      postRender: undefined  # (DOM Node)
    # Event: If you need to execute something after `render`
    postRender: undefined


  # ## Helper Util: Data processor

  # Normalize data so that at position `idx`, the value is 100%
  # and all other values are scaled relative to that value.
  # TODO needs to be repackage into a utils library.
  exports.normalizeFirst = (data, idx) ->
    data = $.extend(true, [], data)  # make a deep copy of data
    idx = idx || 0
    max_value = Math.max.apply(null, data.map((d) -> return d[idx].y))
    for series in data
      factor = max_value / series[idx].y
      for set_j in set
        set_j.y *= factor / max_value * 100
    data;

  # private functions from
  # https://raw.github.com/mbostock/d3/master/src/layout/stack.js
  # for re-ordering data
  d3_layout_stackReduceSum = (d) -> d.reduce(d3_layout_stackSum, 0)
  d3_layout_stackSum = (p, d) -> p + d[1]

  # Similar to python's any. Returns `true` if any of the elements in an
  #   array are truthy.
  any = (arr) -> arr.reduce((a, b) -> a || b)

  # # Base D3Chart class

  #
  exports.D3Chart = class D3Chart
    # set up the DOM element the chart is associated with
    # and then call main
    constructor: (el, data, options) ->
      if el.jquery
        @elem = el[0]
        @$elem = el
      else if (typeof el == "string")
        @elem = document.getElementById(el)
        @$elem = $(@elem)
      else
        @elem = el
        @$elem = $(@elem)
      if !@elem
        console.warn("missing element")
        return false

      # D3Chart can take a url as data. When that happens, it sends off an
      # ajax request, expecting json, and then resumes constructing the chart
      if (typeof data == "string")  # if data is url
        self = this
        d3.json(data, (new_data) ->
          self.main.call(self, new_data, options)
        )
      else
        @main(data, options)
      return this

    main: (data, options) ->
      @setUp options
      @_data = @initData data
      @plotSetUp()
      @render()
      @postRender()


    # ## Step 1: Grab user options
    #
    setUp: (options) ->
      # Set up box dimensions based on the containing element.
      # The actual pixels don't matter since we're using viewBox,
      # but the aspect ratio *is* important.
      defaultOptions.height = @$elem.height()
      defaultOptions.width = @$elem.width()

      # Merge user options and default options.
      @options = $.extend(true, {}, defaultOptions, options || {})

      # Allow an array of hex values for convenience.
      if $.isArray(@options.colors)
        @options.colors = d3.scale.ordinal().range(@options.colors)

      # Pre-calculate plot box dimensions.
      @options.plotBox =
        width: @options.width - @options.margin.left - @options.margin.right
        height: @options.height - @options.margin.top - @options.margin.bottom

      # cache bar data accessor
      @_barsDataAccessor = @options.accessors.bars

      # Indicate the current state by adding the "loading" class to the container.
      @$elem.addClass "loading"

    # ## Step 2: cleaning data
    # d3 expects data in a certain format, which is probably different from
    # how your data comes in. You can put any logic you need to transform
    # your data in `initData`
    initData: (data) -> data

    # ## Step 3: set up accessors
    plotSetUp: (data) -> data

    # ## Step 4: Render
    render: ->
      # Setup svg DOM.
      @svg = d3.select(@elem)
              .append("svg")
              .attr("width", "100%")
              .attr("height", "100%")
              .attr("viewBox", [0, 0, @options.width, @options.height].join(" "))
              .attr("preserveAspectRatio", "xMinYMin meet")

      # Setup plot DOM.
      @plot = @svg
               .append("g")
               .attr("class", "plot")
               .attr("width", @options.plotBox.width)
               .attr("height", @options.plotBox.height)
               .attr("transform", "translate(#{@options.margin.left}, #{@options.margin.top})")

      @$elem.removeClass('loading')  # use jquery version for convenience

    # A postRender event is provided if you need to do anything after the
    # chart has been rendered.
    postRender: -> @options.postRender?.call(this)

    # ## Methods

    # Get or set data.
    data: (new_data) ->
      if new_data?
        @_data = @initData(new_data)
        @refresh()
        return this
      @_data

    # Get or set option.
    option: (name, newvalue) ->
      if newvalue?
        @options[name] = newvalue;
        return this
      @options[name]

    # Refresh.
    refresh: () -> @  # PASS


  # # Base Bar Chart Class

  #
  exports.D3BarChart = class D3BarChart extends D3Chart
    # ## plotSetUp: step 3
    plotSetUp: () ->
      @layerFillStyle = @getLayerFillStyle()

      # Setup x scale.
      @xScale = @getXScale()
      @XAxis = null
      @x = @getX()

      # Setup y scales. There is a separate scale for `y` values and `h` height values.
      plotBox = @options.plotBox
      @hScale = d3.scale.linear().range([0, plotBox.height])
      @yScale = d3.scale.linear().range([plotBox.height, 0])
      @yAxis = null
      @y = @getY()
      @h = @getH()

      # Setup bar width. Unlike `x` and `y`, the bar width is not a function
      # since it is extremly rare that your bar widths vary.
      @bar_width = @getBarWidth()

    # ## render: step 4
    # Extend D3Chart's `render`
    render: () ->
      super()

      self = this
      @rescale(@getYDomain())

      @_layers = @getLayers()
      @getBars()

      if @options.tooltip.enabled and $.fn.tooltip
        $('rect.bar', @svg[0]).tooltip({
          # This is wrapped so that you can change the tooltip
          # after the chart has already been initialized.
          title: () -> self.options.tooltip.format.call(this)
        })

      # Let's draw axes!
      if @options.xAxis.enabled
        @xAxis = d3.svg.axis()
          .orient("bottom")
          .scale(@xScale)
          .tickSize(6, 1, 1)
        if @options.xAxis.format
          @xAxis.tickFormat(@options.xAxis.format)
        @svg.append("g")
          .attr("class", "x axis")
          .attr("title", @options.xAxis.title)  # TODO render this title
          .attr("transform", "translate(#{@options.margin.left}, #{(@options.height - @options.margin.bottom)})")
          .call(@xAxis)

      if @options.yAxis.enabled
        @yAxis = d3.svg.axis()
           .scale(self.yScale)
           .orient("left")
        if @options.yAxis.format
          @yAxis.tickFormat(@options.yAxis.format)
        @svg.append("g")
          .attr("class", "y axis")
          .attr("title", @options.yAxis.title)  # TODO render this title
          .attr("transform", "translate(#{@options.margin.left}, #{@options.margin.top})")
          .call(@yAxis)

      if @options.legend.enabled
        @renderLegend(@options.legend.elem)
        @postRenderLegend(@options.legend.elem)

    # ## Refresh
    # This is a stripped down version of `render()` that only re-draws.
    refresh: () ->
      # reset height ceiling
      @rescale(@getYDomain())

      # update layers data
      @_layers.data(@_data)

      # update bars data
      @_layers.selectAll("rect.bar")
        .data((d) -> d)
        .transition()
          .attr("y", @y)
          .attr("height", @h)

      if @yAxis  # should only exist if @optionx.yAxis.enabled anyways
        @svg.select('.y.axis').transition().call(@yAxis)

      return this

    # Get the appropriate [d3 ordinal scale](https://github.com/mbostock/d3/wiki/Ordinal-Scales#wiki-ordinal)
    # for the data.
    getXScale: () ->
      d = @_data.map(@_barsDataAccessor)
      min_x = d3.min(d, (d) -> d3.min(d, (d) -> d.x))
      max_x = d3.max(d, (d) -> d3.max(d, (d) -> d.x))
      return d3.scale.ordinal()
          .domain(d3.range(min_x, max_x + 1))
          .rangeRoundBands([0, @options.plotBox.width], 0.1, 0.1)

    # Figure out the y extents of the data. We're assuming we start at 0,
    # so there's no need to a @getMinY. If you don't want an automatic
    # y scale, you can do something like:
    #
    #     getYDomain: () -> [0, 10000]
    #
    # or
    #
    #     getMaxY: () -> 10000
    getYDomain: ->
      min = if @options.yAxis.min? then @options.yAxis.min else 0
      max = if @options.yAxis.max? then @options.yAxis.max else @getMaxY(@_data)
      [min, max]

    # Function for how to find the the largest value for `y` in the data.
    getMaxY: (d) ->
      _d = d.map(@_barsDataAccessor)
      d3.max(_d, (d) -> d3.max(d, (d) -> d.y))

    # Return a function that decides how to color the bars based on the layer.
    getLayerFillStyle: ->
      opts = @options
      if opts.accessors.colors?
        return (d, i) -> opts.colors[opts.accessors.colors(d, i)]
      return (d, i) -> opts.colors(i)

    # How to get the attribute of the data element into `xScale`.
    getX: () ->
      self = this
      return (d) -> self.xScale(d.x)

    # How to get the attribute of the data element into `yScale`.
    getY: () ->
      self = this
      return (d) -> self.yScale(d.y)

    # How to get the attribute of the data element into `hScale`.
    getH: () ->
      self = this
      return (d) -> self.hScale(d.y)

    # Given some extent like `[0, 1]`, set the domains for the two scales
    # that control how to vertically place things onto the chart.
    rescale: (extent) ->
      @hScale.domain([0, extent[1] - extent[0]])
      @yScale.domain(extent)
      return this

    # ## getLayers: Process Layers/Series
    # Set up a layer for each series as a SVG group.
    getLayers: () ->
      @plot.selectAll("g.layer")
        .data(@_data)
        .enter().append("g")
          .attr("class", "layer")
          .style("fill", @layerFillStyle)

    # ## getBars: Turn data into bars
    # Setup a bar for each point in a series as a SVG rect.
    getBars: () ->
      @._layers.selectAll("rect.bar")
        .data(@_barsDataAccessor)
        .enter().append("rect")
          .attr("class", "bar")
          .attr("width", @bar_width * 0.9)
          .attr("x", @x)
          .attr("y", @options.plotBox.height)  # start bars at the bottom
          .attr("height", 0)  # start bars with no height so they grow to their final height
          .transition()
            .delay((d, i) -> i * 10)
            .attr("y", @y)  # final position of the bottom of the bar
            .attr("height", @h)  # final height of the bar

    # Bar_width is an outer width, so it's actually more like bar space.
    getBarWidth: () ->
      len_x = @xScale.range().length;
      @options.plotBox.width / len_x;


    # ## Legend

    # How to transform the data for a layer into text
    getLegendSeriesTitle: (d, i) -> "#{i}"

    # Build the DOM for the legend
    renderLegend: (el) ->
      if el.jquery  # todo what about things like zepto?
        @$legend = el
        @legend = el[0]
      else if typeof el == "string"
        @legend = document.getElementById el
      else
        @legend = el
      # Bars are built bottom-up, so build the legend the same way using `legend.reversed`.
      # Use `null` to make `d3.insert` behave like `d3.append`.
      #
      # * [d3.insert ref](https://github.com/mbostock/d3/wiki/Selections#wiki-insert)
      # * [dom insertBefore's null convention](http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#ID-952280727)
      legendStackOrder = if @options.legend.reversed then ":first-child" else null

      items = d3.select(@legend).append("ul")
        .attr("class", "nav nav-pills nav-stacked")
        .selectAll("li")
          .data(@_data)
          .enter()
            .insert("li", legendStackOrder)
              .attr('class', 'inactive')
              .append('a').attr("href", "#")
      items
        .append("span").attr("class", "legend-key")
        .html("&#9608;").style("color", @layerFillStyle)  # TODO use an element that can be controlled with CSS better but is also printable
      if @options.legend.titleAccessor?
        items
          .append("span").attr("class", "legend-value")
          .text(@options.legend.titleAccessor)
      else
        items
          .append("span").attr("class", "legend-value")
          .text(@getLegendSeriesTitle)
      self = this  # need a reference to `this`
      items.on("click", (d, i) ->
        d3.event.preventDefault()
        self.options.legend.click?(d, i, this)
      )
      return this

    # If you want to customize the legend, it may be easier to alter the legend
    # created by `renderLegend` instead of making your own.
    postRenderLegend: (el) ->
      @options.legend.postRender?.call(this, el);
      return this

  #
  # # Stacked Bar Chart
  #

  #
  exports.D3StackedBarChart = class D3StackedBarChart extends D3BarChart

    setUp: (options) ->
      super(options)
      if @options.stackOrder
        if @options.stackOrder == "big-bottom"
          @options.stackOrder = (d) ->
            n = d.length
            sums = d.map(d3_layout_stackReduceSum)
            stackOrder = d3.range(n).sort((a, b) -> sums[b] - sums[a])
            @_stackOrder = stackOrder  # hold onto this order for later
            return stackOrder
      return this

    #
    initData: (new_data) ->
      # Process add stack offsets using d3's layout helper.
      stack = d3.layout.stack()
      if @options.stackOrder
        stack.order(@options.stackOrder)

      data = stack.values(@_barsDataAccessor)(new_data)

      if @_stackOrder  # stack order was cached
        # If you don't sort the data too, the legend will be in the wrong order.
        data = @_stackOrder.map((x) -> data[x])
      return data


    # We need to customize this because instead of taking `y`, we need to
    # consider `y0` too to get the total height of all the stacked bars.
    getMaxY: (d) ->
      _d = d.map(@_barsDataAccessor)
      d3.max(_d, (d) -> d3.max(d, (d) -> d.y + d.y0))

    # We need to offset `y` by `y0` when drawing the bars.
    getY: () ->
      self = this
      (d) -> self.yScale(d.y + d.y0)


  #
  # # Grouped Bar Chart
  #

  #
  exports.D3GroupedBarChart = class D3GroupedBarChart extends D3BarChart
    # Add a custom method so `getLayers` knows how much to shift each layer by.
    getLayerOffset: (d, i) -> @bar_width * 0.9 * i

    # Shift each series so the bars are adjacent to each other.
    getLayers: () ->
      self = this
      layers = super()
      layers
        .attr("transform", (d, i) ->
          "translate(#{self.getLayerOffset(d, i)}, 0)";
        )

    # Sub-divide the bar width by the number of series so we can fit multiple
    # bars into the same space.
    getBarWidth: () ->
      bar_width = super()
      len_series = @_data.length
      bar_width / len_series

#
# # Staggered Bar Chart
#
# Very similar to a Grouped Bar Chart, but the bars overlap each other.
#   To set up the amount of overlap, pass in the option: `barSpacing`.
#   It can be a number or a percent.

#
  exports.D3StaggeredBarChart = class D3StaggeredBarChart extends D3BarChart
    getLayerOffset: (d, i) ->
      if @_staggerMode  # HACK
        return @_staggerMode - @_barSpacing * i
      @_barSpacing * i # Assume `@_barSpacing` is set

    # This is the same as D3GroupedBarChart's `getLayers`.
    getLayers: () ->
      self = this
      layers = super()
      layers
        .attr("transform", (d, i) ->
          "translate(#{self.getLayerOffset(d, i)}, 0)";
        )

    # Reduce `super`'s bar width.
    getBarWidth: () ->
      bar_width = super()

      @_barSpacing = @_staggerMode = 0
      if typeof @options.barSpacing == "string"  # percent "5%"
        @_barSpacing = bar_width * parseFloat(@options.barSpacing) / 100;
      else if @options.barSpacing
        @_barSpacing = @options.barSpacing
      # If `barSpacing` is negative, reverse the direction of the stagger.
      if @_barSpacing < 0
        @_barSpacing = -@_barSpacing
        @_staggerMode = @_barSpacing * @_data.length
      return bar_width - @_barSpacing * @_data.length

# # Tests
#
# Tests are written in QUnit and can be run/viewed [here](../tests/).
#
# # TODOs
#
# * Give D3Chart children their own defaults
# * Allow sorting series for Grouped and Staggered Bar Charts
# * Fix left aligned bars
# * Better control for bar width
# * Better handling of colors when data is an array of objects

# # The End
  ""  # keep coffeescript from returning the statement above.

