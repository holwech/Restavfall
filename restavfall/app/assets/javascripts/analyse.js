var runAnalysis = function(stage) {
    $.ajax({
        type: "GET",
        url: '/analyse/'+stage,
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "OK") {
            $("#data").append(data['text'] + "<br>");
            runAnalysis(data['next']);
        }
        else if (data['status'] == "Done") {
            $("#new-friend").html("Give me another friend");
            $("#new-event").html("Give me another event");

            currentEvent = data['event'];
            currentFriend = data['friend'];
            toggleVisibility();
            setFriend();
            setEvent();
            setLink();
        }
    });
}
var newFriend = function() {
    $.ajax({
        type: "GET",
        url: '/analyse/Friend',
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "Done") {
           currentFriend = data['friend']; 
            setFriend();
            setLink();
        }
    });
}
var newEvent = function() {
    $.ajax({
        type: "GET",
        url: '/analyse/Event',
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "Done") {
           currentEvent = data['event']; 
            setEvent();
            setLink();
        }
    });
}


var setFriend = function() {
    $("#friend-profile").attr("src", currentFriend['pic']);
    $("#friend-name").html(currentFriend['name']);
    $("#friend-name").attr("href", "http://www.facebook.com/" + currentFriend['id'])
}

var setEvent = function() {
    $("#event-link").attr("href","http://www.facebook.com/" + currentEvent['eventID']);
    $("#event-img").attr("src", currentEvent['img']);
    $("#link-share").html(currentEvent['name']);
}

var setLink = function() {
    var app_id = 'app_id=649498578495089';
    var redirect = '&redirect_uri=https://localhost:3001/close';
    var disp = '&display=popup';
    var link = "https://apps.facebook.com/prosjektrestavfall/uno/"+
                userId + "/" +
                currentFriend['id'] + "/" +
                currentEvent['id'] + "/";
    $('#link-share').attr("href", link);

    var shareLink = 'https://www.facebook.com/dialog/share?'+app_id+'&display='+disp+redirect+'&href='+link;
    $('#post-share').attr('onclick', "window.open('"+shareLink+"', 'fbshare', 'width=640,height=320');");

    var sendLink = 'https://www.facebook.com/dialog/send?'+app_id+'&display='+disp+redirect+'&link='+link;
    $('#send-share').attr('onclick', "window.open('"+sendLink+"', 'fbshare', 'width=640,height=320');");
}

var toggleVisibility = function() {
    $("#results").toggle();
    $("#data").toggle();
}
