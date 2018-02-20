function fixText(text)	{ 
	return text.replace(/ÿ/g, ""); 
}

function addlog(text) {
	$("#log").append("<p>"+text+"</p>");
}

function updateContent(jsontext) {
	$.each(JSON.parse(jsontext), function (id, action) {
		var actiontype = Object.keys(action)[0];
		var htmlvalue = action[actiontype];
		switch (actiontype) {
			case "REPLACE":
				$("#" + id).html(fixText(""+htmlvalue));
				break;
			case "APPEND":
				$("#" + id).append(fixText(""+htmlvalue));
				break;
			case "PREPEND":
				$("#" + id).prepend(fixText(""+htmlvalue));
				break;
			case "BEFORE":
				$("#" + id).before(fixText(""+htmlvalue));
				break;
			case "AFTER":
				$("#" + id).after(fixText(""+htmlvalue));
				break;
			case "REMOVE":
				$("#" + id).remove();
				break;
			default:
				addlog("unknown action type " + actiontype);
				break;
		}
	});
}