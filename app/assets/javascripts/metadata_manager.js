	
//When file picker is able to return file ids, insert the Box file picker
/*
	$(document).ready(function() {
		var boxSelect = new BoxSelect();

		boxSelect.success(function(message) {
			$("#results").html(JSON.stringify(message, undefined, 4));
			
			var formattedMessage = JSON.stringify(message, undefined, 4);
			var name = jQuery.parseJSON(formattedMessage)
			console.log(name[0].name)


			document.getElementById("folderName").innerHTML=name[0].name;


		});
		boxSelect.cancel(function() {
			$("#results").html('The user clicked cancel or closed the window');
			console.log("failture")
		});
	});

*/
