do ($=jQuery, d3=d3, tt=tt, exports=window) ->

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
    tooltip: ->
      d = @__data__
      d.title || d.y
    xAxis:
      enabled: true
      title: ""
      # tickFormat: (a) -> a
    yAxis:
      enabled: true
      title: ""
      # tickFormat: (a) -> a`
    legend:
      enabled: false
      element: undefined  # required an existing DOM element
      stackOrder: "btt"  # bottom to top (btt), or top to bottom (ttb)


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
    # override @initData if data needs to be scrubbed before getting charted
    initData: (data) -> data

    # get or set data
    data: (new_data) ->
      if new_data?
        @_data = @initData(new_data)
        @refresh()
        return @
      @_data

    # get or set data
    refresh: () -> @

    # get or set option
    option: (name, newvalue) ->
      if newvalue?
        @options[name] = newvalue;
        return @
      @options[name]


  #***************** BAR CHART ******************/
  exports.D3BarChart = class D3BarChart extends D3Chart
    constructor: (el, data, options) ->
      # TODO move into super
      self = this
      if el.jquery  # todo what about things like zepto?
        @elem = el[0]
        @$elem = el
      else if (typeof el == "string")
        this.elem = document.getElementById(el)
      else
        @elem = el
      if !@elem
        # console.warn("missing element")
        return false

      if (typeof data == "string")  # if data is url
        d3.json(data, (new_data) ->
          self._data = self.initData(new_data)
          self.setUp(options)
          self.render()
          self.postRender()
        );
      else
        this._data = this.initData(data)
        this.setUp(options)
        this.render()
        self.postRender()

    setUp: (options) ->
      # merge user options and default options
      self = this
      data = this._data

      # cache the jquery representation of the element if it doesn't already exist
      if !self.$elem
        self.$elem = $(self.elem)

      # set up box dimensions based on the parent element
      defaultOptions.height = self.$elem.height()
      defaultOptions.width = self.$elem.width()

      self.options = $.extend(true, {}, defaultOptions, options)

      # allow an array of hex values for convenience
      if $.isArray(self.options.color)
        self.options.color = d3.scale.ordinal().range(self.options.color)

      # pre-calculate plot box dimensions
      plot_box =
        w: self.options.width - self.options.margin.left - self.options.margin.right
        h: self.options.height - self.options.margin.top - self.options.margin.bottom
      self.options.plot_box = plot_box

      self.layerFillStyle = self.getLayerFillStyle()

      # setup x scales
      this.x_scale = self.getXScale()
      self.x_axis = null
      self.x = self.getX()

      # setup y scales
      self.height_scale = d3.scale.linear().range([0, plot_box.h])
      self.y_scale = d3.scale.linear().range([plot_box.h, 0])
      self.y_axis = null
      self.y = self.getY()
      self.h = self.getH()

      # setup bar width
      self.bar_width = this.getBarWidth()

    render: () ->
      self = this

      this.$elem.removeClass('loading')

      # setup svg DOM
      svg = d3.select(this.elem)
              .append("svg")
              .attr("width", "100%")
              .attr("height", "100%")
              .attr("viewBox", [0, 0, this.options.width, this.options.height].join(" "))
              .attr("preserveAspectRatio", "xMinYMin meet")
      this.svg = svg

      # setup plot DOM
      plot = svg
               .append("g")
               .attr("class", "plot")
               .attr("width", this.options.plot_box.w)
               .attr("height", this.options.plot_box.h)
               .attr("transform", "translate(#{@options.margin.left}, #{@options.margin.top})")
      this.plot = plot

      this.rescale(self.getYDomain())

      this._layers = this.getLayers()
      this.getBars()

      # tooltip
      #
      # tooltips are done through bootstrap's tooltip jquery plugin.
      # that's why the syntax has switched from d3 to jquery
      $('rect.bar', svg[0]).tooltip({
        # manually call because options.tooltip can change
        title: () -> self.options.tooltip.call(this)
      })

      # draw axes
      if self.options.xAxis.enabled
        @xAxis = d3.svg.axis()
          .orient("bottom")
          .scale(self.x_scale)
          .tickSize(6, 1, 1)
          .tickFormat((a) -> a)
        svg.append("g")
          .attr("class", "x axis")
          .attr("title", self.options.xAxis.title)  # TODO render this title
          .attr("transform", "translate(#{self.options.margin.left}," + (self.options.height - self.options.margin.bottom) + ")")
          .call(x_axis);

      if self.options.yAxis.enabled
        @yAxis = d3.svg.axis()
                 .scale(self.y_scale)
                 .orient("left")
        if self.options.yAxis.tickFormat
          y_axis.tickFormat(self.options.yAxis.tickFormat)
        svg.append("g")
          .attr("class", "y axis")
          .attr("title", self.options.yAxis.title)  # TODO render this title
          .attr("transform", "translate(" + self.options.margin.left + "," + self.options.margin.top + ")")
          .call(y_axis)

      if @options.legend.enabled
        # @preRenderLegend(self.options.legendElem)
        @renderLegend(self.options.legend.elem)
        @postRenderLegend(self.options.legend.elem)

    ###

    postRender: function(){
      if (this.options.postRender) {
        this.options.postRender.call(this);
      }
    },

    getXScale: function(){
      // TODO this makes a lot of assumptions about how the input data is
      // structured and ordered, replace with d3.extent
      var self = this,
          data = this._data;
      var len_x = data[0].length,
          min_x = data[0][0].x,
          max_x = data[0][len_x - 1].x;
      return d3.scale.ordinal()
          .domain(d3.range(min_x, max_x + 1))
          .rangeRoundBands([0, self.options.plot_box.w], 0.1, 0.1);
    },

    getYDomain: function(){
       return [0, this.getMaxY(this._data)];
    },

    refresh: function(){
      var self = this,
          data = self._data;

      // reset height ceiling
      self.rescale(self.getYDomain());

      // update layers data
      self._layers.data(data);
      // update bars data :(
      self._layers.selectAll("rect.bar")
        .data(function(d) { return d; })
        .transition()
          .attr("y", self.y)
          .attr("height", self.h);

      if (self.yAxis){
        self.svg.select('.y.axis').transition().call(self.yAxis);
      }
      return this;
    },

    getMaxY: function(data){
      return d3.max(data, function(d) {
        return d3.max(d, function(d) {
          return d.y;
        });
      });
    },

    getLayerFillStyle: function(){
      var self = this;
      return function(d, i) { return self.options.color(i); };
    },

    getX: function(){
      var self = this;
      return function(d) { return self.x_scale(d.x); };
    },

    getY: function(){
      var self = this;
      return function(d) { return self.y_scale(d.y); };
    },

    getH: function(){
      var self = this;
      return function(d) { return self.height_scale(d.y); };
    },

    rescale: function(extent){
      // TODO get rid of this method
      this.height_scale.domain([0, extent[1] - extent[0]]);
      this.y_scale.domain(extent);
      return this;
    },

    getLayers: function(){
      // set up a layer for each series
      var self = this;
      var layers = self.plot.selectAll("g.layer")
        .data(this._data)
        .enter().append("g")
          .attr("class", "layer")
          .style("fill", self.layerFillStyle);
      return layers;
    },

    // setup a bar for each point in a series
    getBars: function(){
      var self = this;
      return this._layers.selectAll("rect.bar")
        .data(function(d) { return d; })
        .enter().append("rect")
          .attr("class", "bar")
          .attr("width", self.bar_width * 0.9)
          .attr("x", self.x)
          .attr("y", self.options.plot_box.h)
          .attr("height", 0)
          .transition()
            .delay(function(d, i) { return i * 10; })
            .attr("y", self.y)
            .attr("height", self.h);
    },

    getBarWidth: function(){
      var len_x = this.x_scale.range().length;
      var bar_width = this.options.plot_box.w / len_x;  // bar_width is an outer width
      return bar_width;
    },

    getLegendSeriesTitle: function(d, i){
      return "lol";
    },

    renderLegend: function(el){
      var self = this;
      if (el.jquery) {  // todo what about things like zepto?
        this.$legend = el;
        this.legend = el[0];
      } else if (typeof el == "string"){
        this.legend = document.getElementById(el);
      } else {
        this.legend = el;
      }
      // use null to make insert behave like append
      //   doc source: https://github.com/mbostock/d3/wiki/Selections#wiki-insert
      //   null convention source: http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#ID-952280727
      var legendStackOrder = self.options.legend.stackOrder == "btt" ? ":first-child" : null;
      var items = d3.select(this.legend).append("ul")
        .attr("class", "nav nav-pills nav-stacked")
        .selectAll("li")
          .data(this._data)
          // bars are built bottom-up, so build the legend the same way
          .enter()
            .insert("li", legendStackOrder)
              .attr('class', 'inactive')
              .append('a').attr("href", "#");
      items
        .append("span").attr("class", "legend-key")
        // TODO use an element that can be controlled with CSS better but is also printable
        .html("&#9608;").style("color", this.layerFillStyle);
      items
        .append("span").attr("class", "legend-value")
        .text(self.getLegendSeriesTitle);
      // events
      items.on("click", function(d, i){
        d3.event.preventDefault();
        if (self.legendActivateSeries){
          self.legendActivateSeries(i, this);
        }
      });
    },

    postRenderLegend: function(el){
      if (this.options.legend.postRenderLegend) {
        this.options.legend.postRenderLegend.call(this, el);
      }
    }
    ###

  ""
`


  /***************** STACKED BAR CHART ******************/
  var D3StackedBarChart = exports.D3StackedBarChart = D3BarChart.extend({

    initData: function(new_data){
      // process add stack offsets
      return d3.layout.stack()(new_data);
    },

    getMaxY: function(data){
      return d3.max(data, function(d) {
        return d3.max(d, function(d) {
          return d.y + d.y0;
        });
      });
    },

    getY: function(){
      var self = this;
      return function(d) { return self.y_scale(d.y + d.y0); };
    }
  });


  /***************** GROUPED BAR CHART ******************/
  var D3GroupedBarChart = exports.D3GroupedBarChart = D3BarChart.extend({

    getLayers: function(){
      // set up a layer for each series
      var self = this;
      var layers = self.plot.selectAll("g.layer")
        .data(this._data)
        .enter().append("g")
          .attr("class", "layer")
          .style("fill", self.layerFillStyle);
      // shift grouped bars so they're adjacent to each other
      layers
        .attr("transform", function(d, i) {
          return "translate(" + self.getLayerOffset(i) + ",0)";
        });
      return layers;
    },

    getLayerOffset: function(i) {
      return this.bar_width * 0.9 * i;
    },

    getBarWidth: function(){
      // TODO replace with super
      var len_x = this.x_scale.range().length;
      var bar_width = this.options.plot_box.w / len_x;  // bar_width is an outer width

      var len_series = this._data.length;  // m, i, rows
      return bar_width / len_series;  // sub-divide
    }
  });

  `
