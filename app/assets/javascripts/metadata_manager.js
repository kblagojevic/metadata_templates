$(document).ready(function() {
	var boxSelect = new BoxSelect(),
		$field = $('#folder_ids');

	boxSelect.success(function(message) {
		message.forEach(function (folder) {
			if ($field.val()) {
				var newVal = $field.val() + ',' + folder.id
			}
			else {
				var newVal = folder.id
			}
			$field.val(newVal);
		});
	});
});
