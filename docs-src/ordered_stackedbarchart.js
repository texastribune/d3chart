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
     {x: 4, y: 2}],
    [{x: 0, y: 1},
     {x: 1, y: 1},
     {x: 2, y: 1},
     {x: 3, y: 1},
     {x: 4, y: 1}],
    [{x: 0, y: 2},
     {x: 1, y: 4},
     {x: 2, y: 8},
     {x: 3, y: 16},
     {x: 4, y: 32}]];

// Supported orders:
//
// * "big-bottom"
// * "reverse"
// * "inside-out"
// * "default"
//
var options = { stackOrder: "big-bottom" };

var mychart = new D3StackedBarChart("chart", data, options);
