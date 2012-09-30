// https://gist.github.com/3802316

var data = [
    [{x: 0, y: 0},
     {x: 1, y: 1},
     {x: 2, y: 2},
     {x: 3, y: 3},
     {x: 4, y: 4}],
    [{x: 0, y: 2},
     {x: 1, y: 2},
     {x: 2, y: 2},
     {x: 3, y: 2},
     {x: 4, y: 2}]];

var options = {
      xAxis: {
        enabled: true
      },
      yAxis: {
        enabled: true
      }
    };

var mychart = new D3StackedBarChart("chart", data, options);
