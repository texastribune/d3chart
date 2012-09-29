do ($=jQuery, d3=d3, exports=window) ->

  # CONFIGURATION
  # these are the available options
  defaultOptions =
    color: d3.scale.category10()
    height: 300
    width: 940
    margin:
      top: 10
      right: 0
      bottom: 30
      left: 50
    tooltip:
      enabled: false
      format: ->
        d = @__data__
        d.title || d.y
    xAxis:
      enabled: false
      title: ""
      # tickFormat: (a) -> a
    yAxis:
      enabled: false
      title: ""
      # tickFormat: (a) -> a`
    legend:
      enabled: false
      element: undefined  # required an existing DOM element
      stackOrder: "btt"  # bottom to top (btt), or top to bottom (ttb)
      # OPTIONAL EVENTS
      #   click: (d, i, this) ->
      #   postRenderLegend: (legend.element)


  # data processor
  # TODO move awaaaaay
  # normalize data so that at position `idx`, the value is 100%
  # and all other values are scaled relative to that value
  exports.normalizeFirst = (data, idx) ->
    data = $.extend(true, [], data)  # make a deep copy of data
    idx = idx || 0
    max_value = Math.max.apply(null, data.map((d) -> return d[idx].y))
    for series in data
      factor = max_value / series[idx].y
      for set_j in set
        set_j.y *= factor / max_value * 100
    data;


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
        self = @
        d3.json(data, (new_data) ->
          self.main.call(self, data options)
        )
      else
        @main(data, options)
      return @

    main: (data, options) ->
      @_data = @initData data
      @setUp options
      @render()
      @postRender()


    # override @initData if data needs to be scrubbed before getting charted
    initData: (data) -> data

    setUp: (options) ->
      # set up box dimensions based on the parent element
      defaultOptions.height = @$elem.height()
      defaultOptions.width = @$elem.width()

      # merge user options and default options
      @options = $.extend(true, {}, defaultOptions, options || {})

      # allow an array of hex values for convenience
      if $.isArray(@options.color)
        @options.color = d3.scale.ordinal().range(@options.color)

      # pre-calculate plot box dimensions
      plot_box =
        w: @options.width - @options.margin.left - @options.margin.right
        h: @options.height - @options.margin.top - @options.margin.bottom
      @options.plot_box = plot_box

      @$elem.addClass "loading"

    render: ->
      # use jquery version for convenience
      @$elem.removeClass('loading')

      # setup svg DOM
      @svg = d3.select(@elem)
              .append("svg")
              .attr("width", "100%")
              .attr("height", "100%")
              .attr("viewBox", [0, 0, @options.width, @options.height].join(" "))
              .attr("preserveAspectRatio", "xMinYMin meet")

      # setup plot DOM
      @plot = @svg
               .append("g")
               .attr("class", "plot")
               .attr("width", this.options.plot_box.w)
               .attr("height", this.options.plot_box.h)
               .attr("transform", "translate(#{@options.margin.left}, #{@options.margin.top})")

    # event handler
    # if you need to do anything after the chart has been rendered
    postRender: () -> @options.postRender?.call(@)

    # METHOD
    # get or set data
    data: (new_data) ->
      if new_data?
        @_data = @initData(new_data)
        @refresh()
        return @
      @_data

    # get or set option
    option: (name, newvalue) ->
      if newvalue?
        @options[name] = newvalue;
        return @
      @options[name]

    # METHOD
    refresh: () -> @


  ################################ BAR CHART ###################################

  exports.D3BarChart = class D3BarChart extends D3Chart
    setUp: (options) ->
      super("setUp")

      self = @
      @layerFillStyle = @getLayerFillStyle()

      # setup x scales
      @xScale = @getXScale()
      @XAxis = null
      @x = @getX()

      # setup y scales
      plot_box = @options.plot_box
      self.height_scale = d3.scale.linear().range([0, plot_box.h])
      self.yScale = d3.scale.linear().range([plot_box.h, 0])
      self.yAxis = null
      self.y = self.getY()
      self.h = self.getH()

      # setup bar width
      self.bar_width = this.getBarWidth()

    render: () ->
      super("render")

      self = @
      @rescale(@getYDomain())

      @_layers = @getLayers()
      @getBars()

      # tooltip
      #
      # tooltips are done through bootstrap's tooltip jquery plugin.
      # that's why the syntax has switched from d3 to jquery
      if @options.tooltip.enabled
        # FIXME
        $('rect.bar', @svg[0]).tooltip({
          # manually call because options.tooltip can change
          title: () -> self.options.tooltip.call(this)
        })

      # draw axes
      if @options.xAxis.enabled
        @xAxis = d3.svg.axis()
          .orient("bottom")
          .scale(self.xScale)
          .tickSize(6, 1, 1)
          .tickFormat((a) -> a)
        @svg.append("g")
          .attr("class", "x axis")
          .attr("title", self.options.xAxis.title)  # TODO render this title
          .attr("transform", "translate(#{self.options.margin.left}," + (self.options.height - self.options.margin.bottom) + ")")
          .call(@xAxis);

      if @options.yAxis.enabled
        @yAxis = d3.svg.axis()
                 .scale(self.yScale)
                 .orient("left")
        if self.options.yAxis.tickFormat
          yAxis.tickFormat(self.options.yAxis.tickFormat)
        @svg.append("g")
          .attr("class", "y axis")
          .attr("title", self.options.yAxis.title)  # TODO render this title
          .attr("transform", "translate(#{self.options.margin.left}, #{self.options.margin.top})")
          .call(@yAxis)

      if @options.legend.enabled
        # @preRenderLegend(self.options.legendElem)
        @renderLegend(self.options.legend.elem)
        @postRenderLegend(self.options.legend.elem)

    getXScale: () ->
      # TODO this makes a lot of assumptions about how the input data is
      # structured and ordered, replace with d3.extent
      data = @_data
      len_x = data[0].length
      min_x = data[0][0].x
      max_x = data[0][len_x - 1].x
      return d3.scale.ordinal()
          .domain(d3.range(min_x, max_x + 1))
          .rangeRoundBands([0, @options.plot_box.w], 0.1, 0.1)

    getYDomain: () -> [0, @getMaxY(@_data)]

    refresh: () ->
      # reset height ceiling
      @rescale(@getYDomain())

      # update layers data
      @_layers.data(@_data)

      # update bars data :(
      @_layers.selectAll("rect.bar")
        .data((d) -> d)
        .transition()
          .attr("y", @y)
          .attr("height", @h)

      if @yAxis
        @svg.select('.y.axis').transition().call(@yAxis)

      return @

    getMaxY: (d) ->
      # uhhh, this is confusing
      d3.max(d, (d) -> d3.max(d, (d) -> d.y))

    # returns a function(d, i)
    getLayerFillStyle: () ->
      self = this
      return (d, i) -> return self.options.color(i)

    # how to get the attribute of the data element into xScale
    getX: () ->
      self = this
      return (d) -> self.xScale(d.x)

    # how to get the attribute of the data element into yScale
    getY: () ->
      self = this;
      return (d) -> self.yScale(d.y)

    getH: () ->
      self = this;
      return (d) -> self.height_scale(d.y)

    rescale: (extent) ->
      @height_scale.domain([0, extent[1] - extent[0]])
      @yScale.domain(extent)
      return @

    # set up a layer for each series
    getLayers: () ->
      @plot.selectAll("g.layer")
        .data(@_data)
        .enter().append("g")
          .attr("class", "layer")
          .style("fill", @layerFillStyle)

    # setup a bar for each point in a series
    getBars: () ->
      @._layers.selectAll("rect.bar")
        .data((d) -> d)
        .enter().append("rect")
          .attr("class", "bar")
          .attr("width", @bar_width * 0.9)
          .attr("x", @x)
          .attr("y", @options.plot_box.h)
          .attr("height", 0)
          .transition()
            .delay((d, i) -> i * 10)
            .attr("y", @y)
            .attr("height", @h);

    # bar_width is an outer width, so it's actually more like bar space
    getBarWidth: () ->
      len_x = @xScale.range().length;
      @options.plot_box.w / len_x;


    ############################## LEGEND ######################################
    getLegendSeriesTitle: (d, i) -> "#{i}"

    renderLegend: (el) ->
      self = this
      if el.jquery  # todo what about things like zepto?
        this.$legend = el
        this.legend = el[0]
      else if typeof(el) == "string"
        this.legend = document.getElementById(el);
      else
        this.legend = el
      # bars are built bottom-up, so build the legend the same way using legendStackOrder
      # use null to make insert behave like append
      #   doc source: https://github.com/mbostock/d3/wiki/Selections#wiki-insert
      #   null convention source: http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#ID-952280727
      legendStackOrder = self.options.legend.stackOrder == "btt" ? ":first-child" : null

      items = d3.select(this.legend).append("ul")
        .attr("class", "nav nav-pills nav-stacked")
        .selectAll("li")
          .data(this._data)
          .enter()
            .insert("li", legendStackOrder)
              .attr('class', 'inactive')
              .append('a').attr("href", "#")
      items
        .append("span").attr("class", "legend-key")
        # TODO use an element that can be controlled with CSS better but is also printable
        .html("&#9608;").style("color", this.layerFillStyle)
      items
        .append("span").attr("class", "legend-value")
        .text(self.getLegendSeriesTitle)
      # events
      items.on("click", (d, i) ->
        d3.event.preventDefault();
        self.options.legend.click?(d, i, this)
      )
      return @

    # event handler
    postRenderLegend: (el) ->
      @options.legend.postRenderLegend?.call(@, el);
      return @


  ################## STACKED BAR CHART #########################################
  exports.D3StackedBarChart = class D3StackedBarChart extends D3BarChart

    initData: (new_data) ->
      # process add stack offsets
      d3.layout.stack()(new_data)

    getMaxY: (d) ->
      d3.max(d, (d) ->
        d3.max(d, (d) ->
          d.y + d.y0;
        )
      )

    getY: () ->
      self = this
      (d) -> self.yScale(d.y + d.y0)


  ################## GROUPED BAR CHART #########################################
  exports.D3GroupedBarChart = class D3GroupedBarChart extends D3BarChart

    getLayers: () ->
      self = this;
      layers = self.plot.selectAll("g.layer")
        .data(this._data)
        .enter().append("g")
          .attr("class", "layer")
          .style("fill", self.layerFillStyle);
      # shift grouped bars so they're adjacent to each other
      layers
        .attr("transform", (d, i) ->
          "translate(#{self.getLayerOffset(i)},0)";
        )

    getLayerOffset: (i) -> @bar_width * 0.9 * i

    getBarWidth: () ->
      # TODO replace with super
      len_x = @xScale.range().length
      bar_width = @options.plot_box.w / len_x  # bar_width is an outer width

      len_series = this._data.length  # m, i, rows
      bar_width / len_series  # sub-divide

  # The End
  ""
