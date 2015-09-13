var lines = [
	'Genererer magi',
	'Søker lykke',
   	'Ser inn i fremtiden',
	'Mater Nesevisehornet',
	'Skaper UKEmagi',
	'Roter i arkivene',
	'Undersøker kaos',
    'Prøver og feiler',
    'Mater Nesevisehornet',
    'Skaper UKEmagi',
    'Roter i arkivene ',
    'Finner UKEfølelse',
    'Spiser Lycheburger',
    'Jakter på svar',
    'Angrer i morgen',
    'Finner meningen med livet',
    'Er nysgjerrig på svar',
    'Venter i spenning',
    'Leter febrilsk etter billetter',
    'Kalibrerer vennskap',
    'Kjøpsslår om billetter',
    'Vanner blomster',
    'Planter planter',
    'Ser maling tørke',
    'Stanger opp i fortiden',
    'Leker med LEGO',
    'Tar en pustepause',
    'Titter på fjortisbilder',
    'Jakter på den ultimate selfie',
    'Gjør små øyeblikk store',
    'Tenker spretne tanker',
    'Ser på Gossip Girl',
    'Farger håret UKErødt',
    'Undersøker livsgnist',
    'Luker ut uvenner',
    'Kaster opp Sesamburger',
    'Blir kastet ut av Samfundet',
    'Roter meg bort på Samfundet',
    'Sidesetter fiender',
    'Analyserer hjerterytmer',
    'Luker ut ekskjærester',
    'Skrur opp kleinhetsfaktoren',
    'Finner frem gamle flammer',
    'Leser UKEprogrammet',
    'Fjerner nettroll',
    'Ser tilbake i tidene',
    'Maksimerer treffpotensiale',
    'Kartlegger ekser, din rundbrenner',
    'Leker med ilden',
    'Analyserer one-night-stands',
    'Sjekker klinekartet',
    'Roter i meldinger sendt etter 02.00',
    'Intervjuer moren din',
    'Poster clickbait',
    'Raider 7-Eleven',
    'Undersøker mappe med navn “hemmelig”',
    'Sletter fortid'
];

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
    $("#event-image").attr("src", "https://www.uka.no" + currentEvent['image']);
    $("#ticket-link").attr("href","http://www.uka.no" + currentEvent['url']);
    if (currentEvent['sold_out']){
        $("#ticket-link").html("SE INFO");
		$("#utsolgt").css("visibility", "visible");
	}
	else {
        $("#ticket-link").html("KJØP BILLETT");
		$("#utsolgt").css("visibility", "hidden");
	}
    $("#event-title").html(currentEvent['title'].toUpperCase());
	$("#description").html(currentEvent['description']);
}

var setLink = function() {
    var app_id = 'app_id=649498578495089';
    var redirect = '&redirect_uri=https://niivx.uka.no/close';
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
			nextData = null;
			again(false);
        }
    })
	.error(function() {
		error();
	});
}

function preloadImage(url)
{
	var img=new Image();
	img.src=url;
}

var again = function(setData) {
	if (setData == undefined) {
		fillData(nextData);
		nextData = null;
	}
    $.ajax({
        type: "GET",
        url: '/analyse/FriendEvent',
    })
    .success(function(data) {
        console.log(data);
        if (data['status'] == "Done") {
            nextData = data;
			preloadImage(data["friend"]["pic"]);
			preloadImage("https://www.uka.no" + data["event"]["image"]);
        }
    })
	.error(function() {
		error();
	});
}

var error = function() {
    $('#container').attr("class", "down");
    $('#event-title').html("OOPS");
    $('#description').html("Dette er pinlig, noe gikk galt! Heldigvis er det allerede noen som jobber med å fikse det. Prøv å laste inn siden på nytt!");
    $('#ticket').css("display", "none");
	$('#profiles').css("display", "none");
	$('#event-image').css("display", "none");
	$('#button-wrapper').css("display", "none");
}

var done = function() {
    $('#container').attr("class", "down");
}

var spinning = false;
var spin = function() {
	if (spinning)
		return;
	spinning = true;
    var c = 1;
    var i = 0;
    var update = function() {
        var elem = $('#text');
        var cl = elem.attr('class');
        if (cl == 'right') {
            elem.html(lines[Math.floor(lines.length * Math.random())]);
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
    $('.rhino-blink').attr("class", "blink-nod");
	$('#button').attr("onClick", "");
    $('#button_click').attr("class", "");
	runAnalysis("Start");
}

var slideUp = function(token) {
	if (token == ''){
		top.location.href='https://www.facebook.com/prosjektrestavfall?sk=app_649498578495089';
		return;
	}

	console.log("Sliding up");
    $('#container').attr("class", "up");
	setTimeout(delayedSlideUp, 2000);
    $.ajax({
        type: "GET",
        url: '/analyse/Token?token='+token,
    })
    .success(function(data) {
        console.log("Token sent");
    });
}

var delayedSlideUp = function() {
	console.log("Hiding/showing elements");
	$("#button-wrapper").css("display","inline");
	$(".hide").css("display","none");
}
