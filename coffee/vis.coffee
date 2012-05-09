
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 940
    @height = 500

    @tooltip = CustomTooltip("gates_tooltip", 240)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    @year_centers = {
      "SCOREProject": {x: @width / 3, y: @height / 2},
      "SCOREProject,ukoer": {x: @width / 2, y: @height / 2},
      "ukoer": {x: 2 * @width / 3, y: @height / 2}
    }

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # nice looking colors - no reason to buck the trend
    @fill_color = d3.scale.ordinal()
      .domain(["0", "1", "2", "3", "4", "5"])
      .range(["#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854" ])

    # use the max total_amount in the data as the max in the scale's domain
    max_amount_bc = d3.max(@data, (d) -> parseInt(d.betweenness_centrality))
    @radius_scale_bc = d3.scale.pow().exponent(0.5).domain([0, max_amount_bc]).range([2, 85])

    max_amount_degree = d3.max(@data, (d) -> parseInt(d.degree_in))
    @radius_scale_degree = d3.scale.pow().exponent(0.5).domain([0, max_amount_degree]).range([2, 40])

    max_amount_followers = d3.max(@data, (d) -> parseInt(d.followers_count))
    @radius_scale_followers = d3.scale.pow().exponent(0.5).domain([0, max_amount_followers]).range([2, 85])
    
    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.screen_name
        radius: @radius_scale_bc(parseInt(d.betweenness_centrality))
        radius_bc: @radius_scale_bc(parseInt(d.betweenness_centrality))
        radius_degree: @radius_scale_degree(parseInt(d.degree_in))
        radius_followers: @radius_scale_followers(parseInt(d.followers_count))
        value: d.betweenness_centrality
        name: d.screen_name
        image: d.profile_image_url
        group: d.group
        belongs_to : d.belongs_to
        x: Math.random() * 900
        y: Math.random() * @height
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then 
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis").append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")

    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # used because we need 'this' in the 
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.group))
      .attr("stroke-width", 2)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
      .attr("id", (d) -> "bubble_#{d.id}")
      .attr("href", (d) -> "{d.name}")
      .on("click", (d) -> filterFormName(d.name))
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision 
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to 
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d[radius_type], 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout
  # to size nodes by bc.
  display_by_bc: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
    @circles.transition().duration(2000).attr("r", (d) -> d.radius_bc)
    @force.start()

  # Sets up force layout
  # to size nodes by degree.
  display_by_degree: () =>
    radius_type = 'radius_degree'
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)    
    @circles.transition().duration(2000).attr("r", (d) -> d.radius_degree)
    @force.start()

  # Sets up force layout
  # to size nodes by followers.
  display_by_followers: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
    @circles.transition().duration(2000).attr("r", (d) -> d.radius_followers)
    @force.start()

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  # sets the display of bubbles to be separated
  # into each year. Does this by calling move_towards_year
  display_by_year: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_year(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_years()

  # move all circles to their associated @year_centers 
  move_towards_year: (alpha) =>
    (d) =>
      target = @year_centers[d.belongs_to]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

  # Method to display year titles
  display_years: () =>
    years_x = {"SCOREProject (n.194)": 160, "Both (n.107)": @width / 2, "ukoer (n.325)": @width - 160}
    years_data = d3.keys(years_x)
    years = @vis.selectAll(".years")
      .data(years_data)

    years.enter().append("text")
      .attr("class", "years")
      .attr("x", (d) => years_x[d] )
      .attr("y", 40)
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to hide year titiles
  hide_years: () =>
    years = @vis.selectAll(".years").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<img src=\"#{data.image}\" align=\"left\" style=\"padding-right:5px\"/><span class=\"name\">Screen Name:</span><span class=\"value\"> #{data.name}</span><br/>"
    #content +="<span class=\"name\">Amount:</span><span class=\"value\"> $#{addCommas(data.value)}</span><br/>"
    content +="<span class=\"name\">Follows:</span><span class=\"value\"> #{data.belongs_to}</span>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()


root = exports ? this
radius_type = 'radius_bc'

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_all()
  root.display_year = () =>
    chart.display_by_year()
  root.display_bc = () =>
    chart.display_by_bc()
  root.display_degree = () =>
    chart.display_by_degree()
  root.display_followers = () =>
    chart.display_by_followers()
  root.toggle_view = (view_type) =>
    if view_type == 'year'
      root.display_year()
    else
      root.display_all()
  root.toggle_size = (view_by) =>
    if view_by == 'degree' 
      radius_type = 'radius_degree'
      root.display_degree()
    else if view_by == 'followers'
      radius_type = 'radius_followers'
      root.display_followers()
    else
      radius_type = 'radius_bc'
      root.display_bc()

  d3.csv "data/score_ukoer_data.csv", render_vis
