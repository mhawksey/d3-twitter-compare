  function render0(data, i) {
     var word0 = d3.layout.cloud().size([200, 200]).words(data).rotate(function () {
        return ~~ (Math.random() * 2) * 90;
     }).fontSize(function (d) {
        return fontSize(+d.size);
     }).on("end", function (d) {
        d3.select("#word" + i).append("svg").attr("width", 180).attr("height", 180).append("g").attr("transform", "translate(100,100)").selectAll("text").data(d).enter().append("text").style("font-size", function (d) {
           return d.size + "px";
        }).attr("text-anchor", "middle").attr("transform", function (d) {
           return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
        }).attr("fill", colour_group[i]).attr("href", function (d) {
           return d.text;
        }).on("click", function (d) {
           var f = d3.select(this).attr("href");
           filterForm(f);
        }).text(function (d) {
           return d.text;
        });
     }).start();
  }


  var worddata = [];
  var colour_group = ["#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854"];
  var maxGroup = 5;
  fontSize = d3.scale.sqrt().range([1, 10]);
  d3.csv("data/SCORE-UKOER wordcounts 0 .csv", function (loadedRows) {
     worddata = loadedRows;
     render0(worddata, 0);
  });
  d3.csv("data/SCORE-UKOER wordcounts 1 .csv", function (loadedRows) {
     worddata = loadedRows;
     render0(worddata, 1);
  });
  d3.csv("data/SCORE-UKOER wordcounts 2 .csv", function (loadedRows) {
     worddata = loadedRows;
     render0(worddata, 2);
  });
  d3.csv("data/SCORE-UKOER wordcounts 3 .csv", function (loadedRows) {
     worddata = loadedRows;
     render0(worddata, 3);
  });
  d3.csv("data/SCORE-UKOER wordcounts 4 .csv", function (loadedRows) {
     worddata = loadedRows;
     render0(worddata, 4);
  });