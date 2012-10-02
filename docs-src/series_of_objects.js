var MyBarChart = (function() {

    __extends(Custom, D3StackedBarChart);

    function Custom() {
      return Custom.__super__.constructor.apply(this, arguments);
    }
    Custom.prototype.getLayerFillStyle = function() {
      var self = this;
      return function(d, i) {
        return self.options.color[d.name];
      };
    };

    return Custom;

  })();


var data = [
      {
        values:
          [{x: 0, y: 0},
           {x: 1, y: 1},
           {x: 2, y: 2},
           {x: 3, y: 3},
           {x: 4, y: 4}],
        name: "Breakfast"
      },
      {
        values:
          [{x: 0, y: 2},
           {x: 1, y: 2},
           {x: 2, y: 2},
           {x: 3, y: 2},
           {x: 4, y: 2}],
        name: "Lunch"
      }
    ];

var options = {
      color: {
        "Breakfast": 'goldenrod',
        "Lunch": 'darkslategrey'
      },
      accessors: {
        bars: function(d){ return d.values; }
      },
      xAxis: { enabled: true },
      yAxis: { enabled: true }
    };

var mychart = new MyBarChart("chart", data, options);
