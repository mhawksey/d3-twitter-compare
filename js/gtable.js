    var baseQuery = "SELECT S, B, K, lower(P), J, I, F, D, M WHERE J <> '' ";
    var colNames = " LABEL B 'Screen Name', K 'Name', lower(P) 'Description', J 'Follows', I 'Group', F 'Betweenness', D 'Degree In', M 'Followers', S 'Image' ";

    var isFirstTime = true;
    var data;
    var visualization;
    var descFilter;
    var nameFilter;
	var categoryPicker
    //var queryInput;
    var query = new google.visualization.Query('http://spreadsheets.google.com/tq?key=0AqGkLMU9sHmLdDYxNXlGMXZpVlZPaTd3MF9EVXdaUlE&pub=1&gid=115');

    function sendAndDraw() {
       if (isFirstTime) {
          query.setQuery(baseQuery + colNames);
          //queryInput = document.getElementById('display-query');
          isFirstTime = false;
       }
       // Send the query with a callback function.
       query.send(handleQueryResponse);
    }

    function drawVisualization() {
       // To see the data that this visualization uses, browse to
       // http://spreadsheets.google.com/ccc?key=pCQbetd-CptGXxxQIG7VFIQ  
       query.setQuery(baseQuery);

       // Send the query with a callback function.
       query.send(handleQueryResponse);
    }

    function setQuery(queryString) {
       // Query language examples configured with the UI
       query.setQuery(queryString);
       sendAndDraw();
       // queryInput.value = queryString;
    }

    function handleQueryResponse(response) {
       if (response.isError()) {
          alert('Error in query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
          return;
       }
       var data = response.getDataTable();
       var formatter = new google.visualization.PatternFormat('<img src="{0}"/ style="max-width:48px">');
       formatter.format(data, [0]); // Apply formatter and set the formatted value of the first column.
       // Define a StringFilter control for the 'Name' column
       descFilter = new google.visualization.ControlWrapper({
          'controlType': 'StringFilter',
          'containerId': 'controlDesc',
          'options': {
             'filterColumnIndex': 3,
             'matchType': 'any',
             'ui': {
                'label': 'Filters: Descriptions'
             }
          }
       });
       nameFilter = new google.visualization.ControlWrapper({
          'controlType': 'StringFilter',
          'containerId': 'controlName',
          'options': {
             'filterColumnIndex': 1,
             'matchType': 'any',
             'ui': {
                'label': 'Screen name'
             }
          }
       });
	    // Define a category picker for the 'Metric' column.
	    categoryPicker = new google.visualization.ControlWrapper({
		'controlType': 'CategoryFilter',
		'containerId': 'controlGroup',
		'options': {
		  'filterColumnLabel': 'Group',
		  'ui': {
			'allowTyping': false,
			'allowMultiple': false,
			'label': 'Group',
			'caption': 'Select a group'
		  }
		},
	  });

       // Define a table visualization
       var cssClassNames = {
          'tableCell': 'cell'
       };
       var table = new google.visualization.ChartWrapper({
          'chartType': 'Table',
          'containerId': 'chart1',
          'options': {
             'allowHtml': true,
             'cssClassNames': cssClassNames,
             'height': '400px'
          }
       });

       // Create the dashboard.
       var dashboard = new google.visualization.Dashboard(document.getElementById('dashboard'));
       // Configure the string filter to affect the table contents
       dashboard.bind(descFilter, table);
       dashboard.bind(nameFilter, table);
	   dashboard.bind(categoryPicker, table);
       dashboard.draw(data);
    }
    google.setOnLoadCallback(sendAndDraw);

    function filterForm(aWord) {
       descFilter.setState({
          'value': aWord
       });
       descFilter.draw();
    }

    function filterFormName(aName) {
       nameFilter.setState({
          'value': aName
       });
       nameFilter.draw();
    }
	
!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");