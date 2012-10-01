d3chart
=======

A work in progress library to build simple charts using [d3](http://d3js.org/).

Documentation
-------------
[texastribune.github.com/d3chart](http://texastribune.github.com/d3chart)


Dev Requirements
----------------

* CoffeeScript: `npm install coffeescript`
* Docco (to generate documentation): `npm install docco`
* Jist (to upload examples): `gem install jist`
* Foreman (to run a dev webserver want coffescript watcher): `gem install foreman`
* Python (for dev webserver and pygments, a Docco requirement)

Dev Commands
------------

* `foreman start`: Start dev server and coffescript watcher
* `make`: Generate documentation, docco and all examples
* `make gist`: Upload examples as gists

`make gist` will only update existing gists, and will only update gists that
are not yet commited to keep the gists' git history cleaner and
reduce network demand.
