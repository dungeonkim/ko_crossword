window.onload = function(){
    // words[i] correlates to clues[i]
    var words = ["dog", "cat", "bat", "elephant", "kangaroo"];
    var clues = ["Man's best friend", "Likes to chase mice", "Flying mammal", "Has a trunk", "Large marsupial"];

    // Create crossword object with the words and clues
    var cw = new Crossword(words, clues);

    // create the crossword grid (try to make it have a 1:1 width to height ratio in 10 tries)
    var tries = 10; 
    var grid = cw.getSquareGrid(tries);

    // report a problem with the words in the crossword
    if(grid == null){
        var bad_words = cw.getBadWords();
        var str = [];
        for(var i = 0; i < bad_words.length; i++){
            str.push(bad_words[i].word);
        }
        alert("Shoot! A grid could not be created with these words:\n" + str.join("\n"));
        return;
    }

    // turn the crossword grid into HTML
    var show_answers = true;
    document.getElementById("crossword").innerHTML = CrosswordUtils.toHtml(grid, show_answers);

    // make a nice legend for the clues
    var legend = cw.getLegend(grid);
    addLegendToPage(legend);
};

function addLegendToPage(groups){
    for(var k in groups){
        var html = [];
        for(var i = 0; i < groups[k].length; i++){
            html.push("<li><strong>" + groups[k][i]['position'] + ".</strong> " + groups[k][i]['clue'] + "</li>");
        }
        document.getElementById(k).innerHTML = html.join("\n");
    }
}
