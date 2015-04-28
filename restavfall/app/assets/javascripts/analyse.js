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
	    toggleVisibility();
            updateData(data);
        }
    });
}
var newFriendEvent = function() {
    $.ajax({
        type: "GET",
        url: '/analyse/FriendEvent',
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "Done") {
            updateData(data);
        }
    });
}

var updateData = function(data) {
    currentFriend = data['friend']; 
    currentEvent = data['event']; 
    currentLink = data['link'];
    setEvent();
    setFriend();
    setLink();
}

var setFriend = function() {
    $("#friend-profile").attr("src", currentFriend['pic']);
    $("#friend-name").html(currentFriend['name']);
    $("#friend-name").attr("href", "http://www.facebook.com/" + currentFriend['id'])
}

var setEvent = function() {
    $("#event-img").attr("src", currentEvent['img']);
    $("#event-link").attr("href","http://www.facebook.com/" + currentEvent['fbeventID']);
    $("#link-share").html(currentEvent['name']);
}

var setLink = function() {
    var app_id = 'app_id=649498578495089';
    var redirect = '&redirect_uri=https://niivx.uka.no:3001/close';
    var disp = '&display=popup';
    var link = "https://niivx.uka.no:3001/uno/"+
                currentLink + "/r";

    $('#link-share').attr("href", link);

    var shareLink = 'https://www.facebook.com/dialog/share?'+app_id+disp+redirect+'&href='+link;
    $('#post-share').attr('onclick', "window.open('"+shareLink+"', 'fbshare', 'width=640,height=320');");

    var sendLink = 'https://www.facebook.com/dialog/send?'+app_id+disp+redirect+'&link='+link;
    $('#send-share').attr('onclick', "window.open('"+sendLink+"', 'fbshare', 'width=640,height=320');");
}

var toggleVisibility = function() {
    $("#results").toggle();
    $("#data").toggle();
}
