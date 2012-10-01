When you make stacked bar charts, you'll want "big" bars on the bottom and
"small" bars on top. The default d3 stack
[supports a few presets](https://github.com/mbostock/d3/wiki/Stack-Layout#wiki-order),
but that is not one of them. So in addition to those, you can specify a
special order called "big-bottom" and they will get passed onto d3:

* inside-out
* reverse
* default
* big-bottom

Usage:

    var options = { stackOrder: "big-bottom" };
