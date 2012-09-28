// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function($, d3, tt, exports) {
    var D3BarChart, D3Chart, D3GroupedBarChart, D3StackedBarChart, defaultOptions;
    defaultOptions = {
      color: d3.scale.category10(),
      height: 300,
      width: 940,
      margin: {
        top: 10,
        right: 0,
        bottom: 30,
        left: 50
      },
      tooltip: function() {
        var d;
        d = this.__data__;
        return d.title || d.y;
      },
      xAxis: {
        enabled: true,
        title: ""
      },
      yAxis: {
        enabled: true,
        title: ""
      },
      legend: {
        enabled: false,
        element: void 0,
        stackOrder: "btt"
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
    exports.D3Chart = D3Chart = (function() {

      function D3Chart() {}

      D3Chart.prototype.initData = function(data) {
        return data;
      };

      D3Chart.prototype.data = function(new_data) {
        if (new_data != null) {
          this._data = this.initData(new_data);
          this.refresh();
          return this;
        }
        return this._data;
      };

      D3Chart.prototype.refresh = function() {
        return this;
      };

      D3Chart.prototype.option = function(name, newvalue) {
        if (newvalue != null) {
          this.options[name] = newvalue;
          return this;
        }
        return this.options[name];
      };

      return D3Chart;

    })();
    exports.D3BarChart = D3BarChart = (function(_super) {

      __extends(D3BarChart, _super);

      function D3BarChart(el, data, options) {
        var self;
        self = this;
        if (el.jquery) {
          this.elem = el[0];
          this.$elem = el;
        } else if (typeof el === "string") {
          this.elem = document.getElementById(el);
        } else {
          this.elem = el;
        }
        if (!this.elem) {
          return false;
        }
        if (typeof data === "string") {
          d3.json(data, function(new_data) {
            self._data = self.initData(new_data);
            self.setUp(options);
            self.render();
            return self.postRender();
          });
        } else {
          this._data = this.initData(data);
          this.setUp(options);
          this.render();
          self.postRender();
        }
      }

      D3BarChart.prototype.setUp = function(options) {
        var data, plot_box, self;
        self = this;
        data = this._data;
        if (!self.$elem) {
          self.$elem = $(self.elem);
        }
        defaultOptions.height = self.$elem.height();
        defaultOptions.width = self.$elem.width();
        self.options = $.extend(true, {}, defaultOptions, options);
        if ($.isArray(self.options.color)) {
          self.options.color = d3.scale.ordinal().range(self.options.color);
        }
        plot_box = {
          w: self.options.width - self.options.margin.left - self.options.margin.right,
          h: self.options.height - self.options.margin.top - self.options.margin.bottom
        };
        self.options.plot_box = plot_box;
        self.layerFillStyle = self.getLayerFillStyle();
        this.x_scale = self.getXScale();
        self.x_axis = null;
        self.x = self.getX();
        self.height_scale = d3.scale.linear().range([0, plot_box.h]);
        self.y_scale = d3.scale.linear().range([plot_box.h, 0]);
        self.y_axis = null;
        self.y = self.getY();
        self.h = self.getH();
        return self.bar_width = this.getBarWidth();
      };

      D3BarChart.prototype.render = function() {
        var plot, self, svg;
        self = this;
        this.$elem.removeClass('loading');
        svg = d3.select(this.elem).append("svg").attr("width", "100%").attr("height", "100%").attr("viewBox", [0, 0, this.options.width, this.options.height].join(" ")).attr("preserveAspectRatio", "xMinYMin meet");
        this.svg = svg;
        plot = svg.append("g").attr("class", "plot").attr("width", this.options.plot_box.w).attr("height", this.options.plot_box.h).attr("transform", "translate(" + this.options.margin.left + ", " + this.options.margin.top + ")");
        this.plot = plot;
        this.rescale(self.getYDomain());
        this._layers = this.getLayers();
        this.getBars();
        $('rect.bar', svg[0]).tooltip({
          title: function() {
            return self.options.tooltip.call(this);
          }
        });
        if (self.options.xAxis.enabled) {
          this.xAxis = d3.svg.axis().orient("bottom").scale(self.x_scale).tickSize(6, 1, 1).tickFormat(function(a) {
            return a;
          });
          svg.append("g").attr("class", "x axis").attr("title", self.options.xAxis.title).attr("transform", ("translate(" + self.options.margin.left + ",") + (self.options.height - self.options.margin.bottom) + ")").call(x_axis);
        }
        if (self.options.yAxis.enabled) {
          this.yAxis = d3.svg.axis().scale(self.y_scale).orient("left");
          if (self.options.yAxis.tickFormat) {
            y_axis.tickFormat(self.options.yAxis.tickFormat);
          }
          svg.append("g").attr("class", "y axis").attr("title", self.options.yAxis.title).attr("transform", "translate(" + self.options.margin.left + "," + self.options.margin.top + ")").call(y_axis);
        }
        if (this.options.legend.enabled) {
          this.renderLegend(self.options.legend.elem);
          return this.postRenderLegend(self.options.legend.elem);
        }
      };

      D3BarChart.prototype.postRender = function() {
        var _ref;
        return (_ref = this.options.postRender) != null ? _ref.call(this) : void 0;
      };

      D3BarChart.prototype.getXScale = function() {
        var data, len_x, max_x, min_x;
        data = this._data;
        len_x = data[0].length;
        min_x = data[0][0].x;
        max_x = data[0][len_x - 1].x;
        return d3.scale.ordinal().domain(d3.range(min_x, max_x + 1)).rangeRoundBands([0, this.options.plot_box.w], 0.1, 0.1);
      };

      D3BarChart.prototype.getYDomain = function() {
        return [0, this.getMaxY(this._data)];
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

      D3BarChart.prototype.getMaxY = function(d) {
        return d3.max(d, function(d) {
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
          return self.x_scale(d.x);
        };
      };

      D3BarChart.prototype.getY = function() {
        var self;
        self = this;
        return function(d) {
          return self.y_scale(d.y);
        };
      };

      D3BarChart.prototype.getH = function() {
        var self;
        self = this;
        return function(d) {
          return self.height_scale(d.y);
        };
      };

      D3BarChart.prototype.rescale = function(extent) {
        this.height_scale.domain([0, extent[1] - extent[0]]);
        this.y_scale.domain(extent);
        return this;
      };

      D3BarChart.prototype.getLayers = function() {
        return this.plot.selectAll("g.layer").data(this._data).enter().append("g").attr("class", "layer").style("fill", this.layerFillStyle);
      };

      D3BarChart.prototype.getBars = function() {
        return this._layers.selectAll("rect.bar").data(function(d) {
          return d;
        }).enter().append("rect").attr("class", "bar").attr("width", this.bar_width * 0.9).attr("x", this.x).attr("y", this.options.plot_box.h).attr("height", 0).transition().delay(function(d, i) {
          return i * 10;
        }).attr("y", this.y).attr("height", this.h);
      };

      D3BarChart.prototype.getBarWidth = function() {
        var len_x;
        len_x = this.x_scale.range().length;
        return this.options.plot_box.w / len_x;
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
        legendStackOrder = (_ref = self.options.legend.stackOrder === "btt") != null ? _ref : {
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
        return d3.layout.stack()(new_data);
      };

      D3StackedBarChart.prototype.getMaxY = function(d) {
        return d3.max(d, function(d) {
          return d3.max(d, function(d) {
            return d.y + d.y0;
          });
        });
      };

      D3StackedBarChart.prototype.getY = function() {
        var self;
        self = this;
        return function(d) {
          return self.y_scale(d.y + d.y0);
        };
      };

      return D3StackedBarChart;

    })(D3BarChart);
    exports.D3GroupedBarChart = D3GroupedBarChart = (function(_super) {

      __extends(D3GroupedBarChart, _super);

      function D3GroupedBarChart() {
        return D3GroupedBarChart.__super__.constructor.apply(this, arguments);
      }

      D3GroupedBarChart.prototype.getLayers = function() {
        var layers, self;
        self = this;
        layers = self.plot.selectAll("g.layer").data(this._data).enter().append("g").attr("class", "layer").style("fill", self.layerFillStyle);
        return layers.attr("transform", function(d, i) {
          return "translate(" + (self.getLayerOffset(i)) + ",0)";
        });
      };

      D3GroupedBarChart.prototype.getLayerOffset = function(i) {
        return this.bar_width * 0.9 * i;
      };

      D3GroupedBarChart.prototype.getBarWidth = function() {
        var bar_width, len_series, len_x;
        len_x = this.x_scale.range().length;
        bar_width = this.options.plot_box.w / len_x;
        len_series = this._data.length;
        return bar_width / len_series;
      };

      return D3GroupedBarChart;

    })(D3BarChart);
    return "";
  })(jQuery, d3, tt, window);

}).call(this);
