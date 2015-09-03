var lines = ['Genererer magi','Søker lykke', 'Ser inn i fremtiden'];

var fillData = function(data) {
    user = data['user'];
    currentFriend = data['friend']; 
    currentEvent = data['event']; 
    currentLink = data['link'];
    setUser();
    setEvent();
    setFriend();
    setLink();
}

var setUser = function() {
    $("#me-image").attr("src", user['pic']);
    $("#me-name").html(user['name']);
    $("#me-name").attr("href", "http://www.facebook.com/" + user['id'])
}

var setFriend = function() {
    $("#friend-image").attr("src", currentFriend['pic']);
    $("#friend-name").html(currentFriend['name']);
    $("#friend-name").attr("href", "http://www.facebook.com/" + currentFriend['id'])
}

var setEvent = function() {
    $("#event-image").attr("src", "http://www.uka.no" + currentEvent['image']);
    $("#ticket-link").attr("href","http://www.uka.no" + currentEvent['url']);
    $("#event-title").html(currentEvent['title'].toUpperCase());
}

var setLink = function() {
    var app_id = 'app_id=649498578495089';
    var redirect = '&redirect_uri=https://niivx.uka.no:3001/close';
    var disp = '&display=popup';
    var link = "https://niivx.uka.no/uno/"+ currentLink + "/r?signed_request="+sr;

    var shareLink = 'https://www.facebook.com/dialog/share?'+app_id+disp+redirect+'&href='+link;
    $('#share-image').attr('onclick', "window.open('"+shareLink+"', 'fbshare', 'width=640,height=320');");

    var sendLink = 'https://www.facebook.com/dialog/send?'+app_id+disp+redirect+'&link='+link;
    $('#send-image').attr('onclick', "window.open('"+sendLink+"', 'fbshare', 'width=640,height=320');");
}

var runAnalysis = function(stage) {
    $.ajax({
        type: "GET",
        url: '/analyse/'+stage,
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "OK") {
            runAnalysis(data['next']);
        }
        else if (data['status'] == "Done") {
            fillData(data);
            done(data);
        }
    });
}

var again = function() {
    $.ajax({
        type: "GET",
        url: '/analyse/FriendEvent',
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "Done") {
            fillData(data);
        }
    });
}

var done = function() {
    $('#container').attr("class", "down");
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
    $('#wheel_board').attr("class", "rotate");
    $('#rhino_head').attr("class", "nod");
    $('#button_click').attr("class", "");
	runAnalysis("Start");
}
