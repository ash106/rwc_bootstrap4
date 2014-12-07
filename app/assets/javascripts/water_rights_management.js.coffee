$(".water_rights_management-dashboard").ready ->
  # Called when the dashboard user selectbox changes
  $('#user-selector').change (e) ->
    console.log $(this).val()
    window.location.href = "/wrm-dashboard/#{$(this).val()}"


$(".water_rights_management-show_water_rights").ready ->
  # Initialize tablesorter
  $("#water_rights_table").tablesorter
    theme: 'bootstrap',
    widgets: ['uitheme'],
    headerTemplate: '{content} {icon}', # new in v2.7. Needed to add the bootstrap icon!
    sortList: [[0,0]], #Default sort on first column, order ascending
    headers:
      4: # View Right column
        sorter: false

  # Basic map options object
  mapOptions =
    center: new google.maps.LatLng(40.5999605, -111.747028)
    zoom: 9
    mapTypeId: google.maps.MapTypeId.ROADMAP

  # Create the map
  map = new google.maps.Map($("#map_canvas.water_rights")[0], mapOptions)
  
  # Create bounds to focus map on the added geometry
  bounds = new google.maps.LatLngBounds()

  # Empty array that will be used to store water rights
  water_rights = []

  #Geometry style settings
  polygon_fill_color = '#76b5c6'
  polygon_stroke_color = '#6eb3c6'
  point_icon_url = 'https://cdn1.iconfinder.com/data/icons/Map-Markers-Icons-Demo-PNG/48/Map-Marker-Marker-Outside-Azure.png'

  # Load GeoJSON based on current_user ID, which defaults to 0 if no user is signed in
  map.data.loadGeoJson("/get-water-rights-data/#{$('#water_rights_table_body').data('user')}.json")

  #Date formatter for water rights dates in table
  date_formatter = (date) ->
    d = date.split("-")[2]
    m = date.split("-")[1]
    y = date.split("-")[0]
    m + "/" + d + "/" + y

  # Get feature names for a given water right number
  get_feature_names = (num) ->
    feature_names = []
    # Loop thru all features
    map.data.forEach (feature) ->
      # Get water rights associated with current feature
      feature_wrs = feature.getProperty "water_rights"
      # Get array of water right numbers associated with current feature
      feature_wr_numbers = _.pluck(feature_wrs, 'number')
      # If feature_wr_numbers contains the given number, push current feature's name onto feature_names array
      if _.contains(feature_wr_numbers, num)
        feature_names.push feature.getProperty "name"
    # Return string of feature names
    feature_names.join(", ")

  # Called when 'View' button is clicked in a table row
  $('#water_rights_table_body').on 'click', 'td a.show-link', (e) ->
    e.preventDefault()
    # Reset styling for map features
    map.data.revertStyle()
    # Get number from clicked water right link
    clicked_wr_number = $(this).attr 'href'
    # Clear water rights table before appends
    $('#water_rights_table_body').html ""
    # Re-add water rights to table, highlighting only the clicked row
    for wr in water_rights
      # Set the clicked row to highlighted
      if wr.number == clicked_wr_number
        context = 
          wr: wr
          date_formatter: date_formatter
          get_feature_names: get_feature_names
          highlighted: true
        $('#water_rights_table_body').append JST['templates/water_right'](context)
      # All other rows are unhighlighted
      else
        context = 
          wr: wr
          date_formatter: date_formatter
          get_feature_names: get_feature_names
        $('#water_rights_table_body').append JST['templates/water_right'](context)
    # Update tablesorter
    $("#water_rights_table").trigger("update")
    # Create bounds for features associated with clicked water right
    selected_bounds = new google.maps.LatLngBounds()
    # Set styling for features associated with clicked water right
    map.data.forEach (feature) ->
      # Get water rights associated with current feature
      feature_wrs = feature.getProperty "water_rights"
      # Get array of water right numbers associated with current feature
      feature_wr_numbers = _.pluck(feature_wrs, 'number')
      # If feature_wr_numbers contains clicked water right number, set styling on feature
      if _.contains(feature_wr_numbers, clicked_wr_number)
        # If feature is a polygon, set fill color and stroke color
        if feature.getGeometry().getType() == "Polygon"
          map.data.overrideStyle feature, fillColor: polygon_fill_color, strokeColor: polygon_stroke_color
          # Extend bounds for each point in polygon
          points = feature.getGeometry().getAt(0).getArray()
          for point in points
            selected_bounds.extend point
        # If feature is a point, set icon
        if feature.getGeometry().getType() == "Point"
          map.data.overrideStyle feature, icon: point_icon_url
          # Extend bounds for point
          selected_bounds.extend feature.getGeometry().get()
    # Zoom map to bounds for features associated with clicked water right
    map.fitBounds selected_bounds

  # setLinkListeners = ->
  #   console.log "called setLinkListeners"
  #   $('td a').click (e) ->
  #     e.preventDefault()
  #     map.data.revertStyle()
  #     clicked_wr_number = $(this).attr "href"
  #     $('#water_rights_table_body').html(
  #       for wr in water_rights
  #         if wr.number == clicked_wr_number
  #           "<tr class='highlighted'><td>#{wr.number}</td><td>#{date_formatter(wr.priority_date)}</td><td>#{wr.change_application_number}</td><td>#{date_formatter(wr.proof_due_date)}</td><td><a href='#{wr.number}'>View</a></td><td>#{if wr.flow_cfs != null then wr.flow_cfs else ""}</td><td>#{if wr.flow_ac_ft != null then wr.flow_ac_ft else ""}</td><td>#{wr.place_of_use}</td><td>#{if wr.comments != null then wr.comments else ""}</td></tr>"
  #         else
  #           "<tr><td>#{wr.number}</td><td>#{date_formatter(wr.priority_date)}</td><td>#{wr.change_application_number}</td><td>#{date_formatter(wr.proof_due_date)}</td><td><a href='#{wr.number}'>View</a></td><td>#{if wr.flow_cfs != null then wr.flow_cfs else ""}</td><td>#{if wr.flow_ac_ft != null then wr.flow_ac_ft else ""}</td><td>#{wr.place_of_use}</td><td>#{if wr.comments != null then wr.comments else ""}</td></tr>"
  #     )
  #     setLinkListeners()
  #     console.log clicked_wr_number
  #     selected_bounds = new google.maps.LatLngBounds()
  #     map.data.forEach (feature) ->
  #       feature_wrs = feature.getProperty "water_rights"
  #       for wr in feature_wrs
  #         if wr.number == clicked_wr_number
  #           if feature.getGeometry().getType() == "Polygon"
  #             map.data.overrideStyle feature, fillColor: '#76b5c6', strokeColor: '#6eb3c6'
  #             points = feature.getGeometry().getAt(0).getArray()
  #             for point in points
  #               selected_bounds.extend point
  #           if feature.getGeometry().getType() == "Point"
  #             map.data.overrideStyle feature, icon: 'https://cdn1.iconfinder.com/data/icons/Map-Markers-Icons-Demo-PNG/48/Map-Marker-Flag--Azure.png'
  #             selected_bounds.extend feature.getGeometry().get()
  #       map.fitBounds selected_bounds


  # Called when each feature is added to the map
  map.data.addListener 'addfeature', (e) ->
    # console.log e.feature
    # If feature is a polygon, add all points of polygon to map bounds
    if e.feature.getGeometry().getType() == "Polygon"
      # Get array of points that make up outer linear ring of polygon
      points = e.feature.getGeometry().getAt(0).getArray()
      # Extend bounds for each point
      for point in points
        bounds.extend point
    # If feature is a point, add single point to map bounds
    if e.feature.getGeometry().getType() == "Point"
      bounds.extend e.feature.getGeometry().get()
    # Fit map bounds to added geometry
    map.fitBounds bounds
    # Get water rights property for the added feature
    wrs = e.feature.getProperty "water_rights"
    # Push each water right onto the main array
    for wr in wrs
      water_rights.push wr
    # These 3 functions should only be run once, but can't figure out how to not run them after every feature
    # Get rid of duplicates
    water_rights = _.uniq water_rights, (wr) ->
                      wr.number
    # Sort water rights by number
    # water_rights = _.sortBy water_rights, (wr) ->
    #                   parseInt wr.number.match(/(\d+)$/)[0], 10
    # Clear water rights table before appends
    $('#water_rights_table_body').html ""
    # Add water rights to table
    for wr in water_rights
      context = 
        wr: wr
        date_formatter: date_formatter
        get_feature_names: get_feature_names
      # Append each water right using water_right.jst.eco template
      $('#water_rights_table_body').append JST['templates/water_right'](context)
        # "<tr><td>#{wr.number}</td><td>#{if wr.priority_date then date_formatter(wr.priority_date) else ""}</td><td>#{if wr.change_application_number then wr.change_application_number else ""}</td><td>#{if wr.proof_due_date then date_formatter(wr.proof_due_date) else ""}</td><td><a href='#{wr.number}'>View</a></td><td>#{if wr.flow_cfs then wr.flow_cfs else ""}</td><td>#{if wr.flow_ac_ft then wr.flow_ac_ft else ""}</td><td>#{if wr.place_of_use then wr.place_of_use else ""}</td><td>#{if wr.comments then wr.comments else ""}</td></tr>"
    # Update tablesorter
    $("#water_rights_table").trigger("update")
  #   setLinkListeners()
  #   return

  # Called when a feature (piece of geometry) is clicked
  map.data.addListener 'click', (e) ->
    # Reset styling for map features 
    map.data.revertStyle()
    # If clicked feature is a polygon, set fill color and stroke color
    if e.feature.getGeometry().getType() == "Polygon"
      map.data.overrideStyle e.feature, fillColor: polygon_fill_color, strokeColor: polygon_stroke_color
    # If clicked feature is a point, set icon
    if e.feature.getGeometry().getType() == "Point"
      map.data.overrideStyle e.feature, icon: point_icon_url
    # Get water rights for clicked feature
    clicked_water_rights = e.feature.getProperty "water_rights"
    # Get array of water right numbers for clicked feature
    clicked_wr_numbers = _.pluck(clicked_water_rights, 'number')
    # Clear water rights table before appends
    $('#water_rights_table_body').html ""
    # Re-add water rights to table, highlighting the ones associated with the clicked feature
    for wr in water_rights
      # If current water right number is in clicked_wr_numbers, add the highlighted class
      if _.contains(clicked_wr_numbers, wr.number)
        context = 
          wr: wr
          date_formatter: date_formatter
          get_feature_names: get_feature_names
          highlighted: true
        $('#water_rights_table_body').append JST['templates/water_right'](context)
          # "<tr class='highlighted'><td>#{wr.number}</td><td>#{date_formatter(wr.priority_date)}</td><td>#{wr.change_application_number}</td><td>#{date_formatter(wr.proof_due_date)}</td><td><a href='#{wr.number}'>View</a></td><td>#{if wr.flow_cfs != null then wr.flow_cfs else ""}</td><td>#{if wr.flow_ac_ft != null then wr.flow_ac_ft else ""}</td><td>#{wr.place_of_use}</td><td>#{if wr.comments != null then wr.comments else ""}</td></tr>"
      # Otherwise add the water right without the highlighted class
      else
        context = 
          wr: wr
          date_formatter: date_formatter
          get_feature_names: get_feature_names
        $('#water_rights_table_body').append JST['templates/water_right'](context)
  #         "<tr><td>#{wr.number}</td><td>#{date_formatter(wr.priority_date)}</td><td>#{wr.change_application_number}</td><td>#{date_formatter(wr.proof_due_date)}</td><td><a href='#{wr.number}'>View</a></td><td>#{if wr.flow_cfs != null then wr.flow_cfs else ""}</td><td>#{if wr.flow_ac_ft != null then wr.flow_ac_ft else ""}</td><td>#{wr.place_of_use}</td><td>#{if wr.comments != null then wr.comments else ""}</td></tr>"
    # Update tablesorter
    $("#water_rights_table").trigger("update")
  #   )
  #   setLinkListeners()
  #   return

  # Called when the user selectbox changes
  $('#user-selector').change (e) ->
    # Remove previous GeoJSON features
    map.data.forEach (feature) ->
      map.data.remove feature
    # Reset map bounds
    bounds = new google.maps.LatLngBounds()
    # Reset water_rights array
    water_rights = []
    # Load new data based on selected user_id
    map.data.loadGeoJson("/get-water-rights-data/#{$(this).val()}.json")
