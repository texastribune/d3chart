var data = [
    [{x: 0, y: 0.1},
     {x: 1, y: 1},
     {x: 2, y: 2},
     {x: 3, y: 3},
     {x: 4, y: 4}],
    [{x: 0, y: 2},
     {x: 1, y: 2},
     {x: 2, y: 2},
     {x: 3, y: 2},
     {x: 4, y: 2}],
    [{x: 0, y: 3},
     {x: 1, y: 3},
     {x: 2, y: 3},
     {x: 3, y: 3},
     {x: 4, y: 3}]
     ];

var options = {
      barSpacing: "10%"
    };

var mychart = new D3StaggeredBarChart("chart", data, options);
