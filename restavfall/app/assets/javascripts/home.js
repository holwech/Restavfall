var lines = ['Genererer magi','Søker lykke', 'Ser inn i fremtiden'];

var again = function() {
    // getNewData()
    // fillData()
}

var done = function() {
    $('#container').attr("class", "down");
    // fillData(data);
}

var spin = function() {
    var c = 1;
    var i = 0;
    var update = function() {
        var elem = $('#text');
        var cl = elem.attr('class');
        if (cl == 'right') {
            elem.html(lines[i++ % lines.length]);
            elem.attr('class', 'center');
        }
        else if (cl == 'center') {
            if (c++ % 3 == 0)
                elem.attr('class', 'left');
            else
                return;
        }
        else elem.attr('class', 'right');
    };
    setInterval(update, 500);
    setTimeout(done, 5000);
    $('#wheel_board').attr("class", "rotate");
    $('#rhino_head').attr("class", "nod");
    $('#button_click').attr("class", "");
}
