// Generated by CoffeeScript 1.3.3
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function($, d3, exports) {
  var D3BarChart, D3Chart, D3GroupedBarChart, D3StackedBarChart, any, d3_layout_stackReduceSum, d3_layout_stackSum, defaultOptions;
  defaultOptions = {
    color: d3.scale.category10(),
    margin: {
      top: 10,
      right: 0,
      bottom: 30,
      left: 50
    },
    tooltip: {
      enabled: false,
      format: function() {
        var d;
        d = this.__data__;
        return d.title || d.y;
      }
    },
    xAxis: {
      enabled: false,
      title: "",
      format: void 0
    },
    yAxis: {
      enabled: false,
      title: "",
      format: void 0
    },
    legend: {
      enabled: false,
      element: void 0,
      reversed: false,
      click: void 0,
      postRender: void 0
    }
  };
  exports.normalizeFirst = function(data, idx) {
    var factor, max_value, series, set_j, _i, _j, _len, _len1;
    data = $.extend(true, [], data);
    idx = idx || 0;
    max_value = Math.max.apply(null, data.map(function(d) {
      return d[idx].y;
    }));
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      series = data[_i];
      factor = max_value / series[idx].y;
      for (_j = 0, _len1 = set.length; _j < _len1; _j++) {
        set_j = set[_j];
        set_j.y *= factor / max_value * 100;
      }
    }
    return data;
  };
  d3_layout_stackReduceSum = function(d) {
    return d.reduce(d3_layout_stackSum, 0);
  };
  d3_layout_stackSum = function(p, d) {
    return p + d[1];
  };
  any = function(arr) {
    return arr.reduce(function(a, b) {
      return a || b;
    });
  };
  exports.D3Chart = D3Chart = (function() {

    function D3Chart(el, data, options) {
      var self;
      if (el.jquery) {
        this.elem = el[0];
        this.$elem = el;
      } else if (typeof el === "string") {
        this.elem = document.getElementById(el);
        this.$elem = $(this.elem);
      } else {
        this.elem = el;
        this.$elem = $(this.elem);
      }
      if (!this.elem) {
        console.warn("missing element");
        return false;
      }
      if (typeof data === "string") {
        self = this;
        d3.json(data, function(new_data) {
          return self.main.call(self, data(options));
        });
      } else {
        this.main(data, options);
      }
      return this;
    }

    D3Chart.prototype.main = function(data, options) {
      this.setUp(options);
      this._data = this.initData(data);
      this.plotSetUp();
      this.render();
      return this.postRender();
    };

    D3Chart.prototype.setUp = function(options) {
      defaultOptions.height = this.$elem.height();
      defaultOptions.width = this.$elem.width();
      this.options = $.extend(true, {}, defaultOptions, options || {});
      if ($.isArray(this.options.color)) {
        this.options.color = d3.scale.ordinal().range(this.options.color);
      }
      this.options.plotBox = {
        width: this.options.width - this.options.margin.left - this.options.margin.right,
        height: this.options.height - this.options.margin.top - this.options.margin.bottom
      };
      return this.$elem.addClass("loading");
    };

    D3Chart.prototype.initData = function(data) {
      return data;
    };

    D3Chart.prototype.plotSetUp = function(data) {
      return data;
    };

    D3Chart.prototype.render = function() {
      this.svg = d3.select(this.elem).append("svg").attr("width", "100%").attr("height", "100%").attr("viewBox", [0, 0, this.options.width, this.options.height].join(" ")).attr("preserveAspectRatio", "xMinYMin meet");
      this.plot = this.svg.append("g").attr("class", "plot").attr("width", this.options.plotBox.width).attr("height", this.options.plotBox.height).attr("transform", "translate(" + this.options.margin.left + ", " + this.options.margin.top + ")");
      return this.$elem.removeClass('loading');
    };

    D3Chart.prototype.postRender = function() {
      var _ref;
      return (_ref = this.options.postRender) != null ? _ref.call(this) : void 0;
    };

    D3Chart.prototype.data = function(new_data) {
      if (new_data != null) {
        this._data = this.initData(new_data);
        this.refresh();
        return this;
      }
      return this._data;
    };

    D3Chart.prototype.option = function(name, newvalue) {
      if (newvalue != null) {
        this.options[name] = newvalue;
        return this;
      }
      return this.options[name];
    };

    D3Chart.prototype.refresh = function() {
      return this;
    };

    return D3Chart;

  })();
  exports.D3BarChart = D3BarChart = (function(_super) {

    __extends(D3BarChart, _super);

    function D3BarChart() {
      return D3BarChart.__super__.constructor.apply(this, arguments);
    }

    D3BarChart.prototype.plotSetUp = function() {
      var plotBox;
      this.layerFillStyle = this.getLayerFillStyle();
      this.xScale = this.getXScale();
      this.XAxis = null;
      this.x = this.getX();
      plotBox = this.options.plotBox;
      this.hScale = d3.scale.linear().range([0, plotBox.height]);
      this.yScale = d3.scale.linear().range([plotBox.height, 0]);
      this.yAxis = null;
      this.y = this.getY();
      this.h = this.getH();
      return this.bar_width = this.getBarWidth();
    };

    D3BarChart.prototype.render = function() {
      var self;
      D3BarChart.__super__.render.call(this);
      self = this;
      this.rescale(this.getYDomain());
      this._layers = this.getLayers();
      this.getBars();
      if (this.options.tooltip.enabled && $.fn.tooltip) {
        $('rect.bar', this.svg[0]).tooltip({
          title: function() {
            return self.options.tooltip.call(this);
          }
        });
      }
      if (this.options.xAxis.enabled) {
        this.xAxis = d3.svg.axis().orient("bottom").scale(this.xScale).tickSize(6, 1, 1);
        if (this.options.xAxis.format) {
          this.xAxis.tickFormat(this.options.xAxis.format);
        }
        this.svg.append("g").attr("class", "x axis").attr("title", this.options.xAxis.title).attr("transform", "translate(" + this.options.margin.left + ", " + (this.options.height - this.options.margin.bottom) + ")").call(this.xAxis);
      }
      if (this.options.yAxis.enabled) {
        this.yAxis = d3.svg.axis().scale(self.yScale).orient("left");
        if (this.options.yAxis.format) {
          this.yAxis.tickFormat(this.options.yAxis.format);
        }
        this.svg.append("g").attr("class", "y axis").attr("title", this.options.yAxis.title).attr("transform", "translate(" + this.options.margin.left + ", " + this.options.margin.top + ")").call(this.yAxis);
      }
      if (this.options.legend.enabled) {
        this.renderLegend(this.options.legend.elem);
        return this.postRenderLegend(this.options.legend.elem);
      }
    };

    D3BarChart.prototype.refresh = function() {
      this.rescale(this.getYDomain());
      this._layers.data(this._data);
      this._layers.selectAll("rect.bar").data(function(d) {
        return d;
      }).transition().attr("y", this.y).attr("height", this.h);
      if (this.yAxis) {
        this.svg.select('.y.axis').transition().call(this.yAxis);
      }
      return this;
    };

    D3BarChart.prototype.getXScale = function() {
      var d, max_x, min_x;
      d = this._data.map(this.barsDataAccessor);
      min_x = d3.min(d, function(d) {
        return d3.min(d, function(d) {
          return d.x;
        });
      });
      max_x = d3.max(d, function(d) {
        return d3.max(d, function(d) {
          return d.x;
        });
      });
      return d3.scale.ordinal().domain(d3.range(min_x, max_x + 1)).rangeRoundBands([0, this.options.plotBox.width], 0.1, 0.1);
    };

    D3BarChart.prototype.getYDomain = function() {
      return [0, this.getMaxY(this._data)];
    };

    D3BarChart.prototype.getMaxY = function(d) {
      var _d;
      _d = d.map(this.barsDataAccessor);
      return d3.max(_d, function(d) {
        return d3.max(d, function(d) {
          return d.y;
        });
      });
    };

    D3BarChart.prototype.getLayerFillStyle = function() {
      var self;
      self = this;
      return function(d, i) {
        return self.options.color(i);
      };
    };

    D3BarChart.prototype.getX = function() {
      var self;
      self = this;
      return function(d) {
        return self.xScale(d.x);
      };
    };

    D3BarChart.prototype.getY = function() {
      var self;
      self = this;
      return function(d) {
        return self.yScale(d.y);
      };
    };

    D3BarChart.prototype.getH = function() {
      var self;
      self = this;
      return function(d) {
        return self.hScale(d.y);
      };
    };

    D3BarChart.prototype.rescale = function(extent) {
      this.hScale.domain([0, extent[1] - extent[0]]);
      this.yScale.domain(extent);
      return this;
    };

    D3BarChart.prototype.getLayers = function() {
      return this.plot.selectAll("g.layer").data(this._data).enter().append("g").attr("class", "layer").style("fill", this.layerFillStyle);
    };

    D3BarChart.prototype.barsDataAccessor = function(d) {
      return d;
    };

    D3BarChart.prototype.getBars = function() {
      return this._layers.selectAll("rect.bar").data(this.barsDataAccessor).enter().append("rect").attr("class", "bar").attr("width", this.bar_width * 0.9).attr("x", this.x).attr("y", this.options.plotBox.height).attr("height", 0).transition().delay(function(d, i) {
        return i * 10;
      }).attr("y", this.y).attr("height", this.h);
    };

    D3BarChart.prototype.getBarWidth = function() {
      var len_x;
      len_x = this.xScale.range().length;
      return this.options.plotBox.width / len_x;
    };

    D3BarChart.prototype.getLegendSeriesTitle = function(d, i) {
      return "" + i;
    };

    D3BarChart.prototype.renderLegend = function(el) {
      var items, legendStackOrder, self, _ref;
      self = this;
      if (el.jquery) {
        this.$legend = el;
        this.legend = el[0];
      } else if (typeof el === "string") {
        this.legend = document.getElementById(el);
      } else {
        this.legend = el;
      }
      legendStackOrder = (_ref = this.options.legend.reversed) != null ? _ref : {
        ":first-child": null
      };
      items = d3.select(this.legend).append("ul").attr("class", "nav nav-pills nav-stacked").selectAll("li").data(this._data).enter().insert("li", legendStackOrder).attr('class', 'inactive').append('a').attr("href", "#");
      items.append("span").attr("class", "legend-key").html("&#9608;").style("color", this.layerFillStyle);
      items.append("span").attr("class", "legend-value").text(self.getLegendSeriesTitle);
      items.on("click", function(d, i) {
        var _base;
        d3.event.preventDefault();
        return typeof (_base = self.options.legend).click === "function" ? _base.click(d, i, this) : void 0;
      });
      return this;
    };

    D3BarChart.prototype.postRenderLegend = function(el) {
      var _ref;
      if ((_ref = this.options.legend.postRenderLegend) != null) {
        _ref.call(this, el);
      }
      return this;
    };

    return D3BarChart;

  })(D3Chart);
  exports.D3StackedBarChart = D3StackedBarChart = (function(_super) {

    __extends(D3StackedBarChart, _super);

    function D3StackedBarChart() {
      return D3StackedBarChart.__super__.constructor.apply(this, arguments);
    }

    D3StackedBarChart.prototype.initData = function(new_data) {
      var data, stack, stackOrder;
      stack = d3.layout.stack();
      stackOrder = void 0;
      if (this.options.stackOrder) {
        stack.order(function(d) {
          var n, sums;
          n = d.length;
          sums = d.map(d3_layout_stackReduceSum);
          stackOrder = d3.range(n).sort(function(a, b) {
            return sums[b] - sums[a];
          });
          return stackOrder;
        });
      }
      data = stack.values(this.barsDataAccessor)(new_data);
      console.log(data);
      if (this.options.stackOrder) {
        data = stackOrder.map(function(x) {
          return data[x];
        });
      }
      return data;
    };

    D3StackedBarChart.prototype.getMaxY = function(d) {
      var _d;
      _d = d.map(this.barsDataAccessor);
      return d3.max(_d, function(d) {
        return d3.max(d, function(d) {
          return d.y + d.y0;
        });
      });
    };

    D3StackedBarChart.prototype.getY = function() {
      var self;
      self = this;
      return function(d) {
        return self.yScale(d.y + d.y0);
      };
    };

    return D3StackedBarChart;

  })(D3BarChart);
  exports.D3GroupedBarChart = D3GroupedBarChart = (function(_super) {

    __extends(D3GroupedBarChart, _super);

    function D3GroupedBarChart() {
      return D3GroupedBarChart.__super__.constructor.apply(this, arguments);
    }

    D3GroupedBarChart.prototype.getLayerOffset = function(d, i) {
      return this.bar_width * 0.9 * i;
    };

    D3GroupedBarChart.prototype.getLayers = function() {
      var layers, self;
      self = this;
      layers = D3GroupedBarChart.__super__.getLayers.call(this);
      return layers.attr("transform", function(d, i) {
        return "translate(" + (self.getLayerOffset(d, i)) + ", 0)";
      });
    };

    D3GroupedBarChart.prototype.getBarWidth = function() {
      var bar_width, len_series;
      bar_width = D3GroupedBarChart.__super__.getBarWidth.call(this);
      len_series = this._data.length;
      return bar_width / len_series;
    };

    return D3GroupedBarChart;

  })(D3BarChart);
  return "";
})(jQuery, d3, window);
