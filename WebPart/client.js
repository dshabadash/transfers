var local_ip;
var permanent_id;
var ClientState = {
	InternetExplorer: -1,
	HaveNoLocalIp: 0,
	FailedToConnectToServer: 1,
	BadPermanentId: 2,
	NotConnectedToDevice: 3,
	ConnectedToDevice: 4,
	Uploading: 5,
	Downloading: 6
}
var currentClientState = ClientState.HaveNoLocalIp;
var shouldUseJSONP = false;
var currentAssetCount = 0;
var currentAssetsAreBeingPrepared = false;
var deviceStatus;
var deviceType = "iPad or iPhone";
function debugLog(message) {
	var line = new Date().toTimeString() + " " + message;
	$("#debug").html(line + '<br>' + $("#debug").html());
}

function setClientState(clientState) {
	var shouldUpdateUI = true;
	if (clientState == currentClientState) {
		shouldUpdateUI = false;
	}
	currentClientState = clientState;
    if (currentClientState == ClientState.HaveNoLocalIp) {
		scheduleRequestDeviceIp();
	} else if (currentClientState == ClientState.BadPermanentId) {} else if (currentClientState == ClientState.FailedToConnectToServer) {
		scheduleRequestDeviceIp();
	} else if (currentClientState == ClientState.NotConnectedToDevice) {
		debugLog('checking if device is available...');
		requestDeviceStatus(local_ip);
	} else if (currentClientState == ClientState.ConnectedToDevice) {
		var assetCount = deviceStatus['asset_count'];
		if (assetCount != currentAssetCount) {
			currentAssetCount = assetCount;
			shouldUpdateUI = true;
		}
		var assetsAreBeingPrepared = deviceStatus['assets_are_being_prepared'];
		if (assetsAreBeingPrepared != currentAssetsAreBeingPrepared) {
			currentAssetsAreBeingPrepared = assetsAreBeingPrepared;
			shouldUpdateUI = true;
		}
		schedulerequestDeviceStatus();
		if (filesToUpload.length > 0) {
			setClientState(ClientState.Uploading);
		} else if (deviceStatus['transfer_state'] === 'upload_in_progress') {
			setClientState(ClientState.Uploading);
		} else if (deviceStatus['transfer_state'] === 'download_in_progress') {
			setClientState(ClientState.Downloading);
		}
	} else if (currentClientState == ClientState.Uploading) {} else if (currentClientState == ClientState.Downloading) {}
	if (shouldUpdateUI) {
		updateUI();
	}
}

function updateUI() {
	var showDeviceBlock = false;
    if (currentClientState == ClientState.HaveNoLocalIp) {
		showActivityIndicator();
		$('#main_info_message').text("Your " + deviceType + " can't be found. Make sure Image Transfer is running and " + deviceType + " is in the same Wi-Fi network with this computer.");
		$('#info_block #info_title').text("Looking for device...");
	} else if (currentClientState == ClientState.BadPermanentId) {
		$('#main_info_message').text("The address you've entered doesn't seem to work. Please check it again on your " + deviceType + ".");
		$('#info_block #info_title').text("Oops!");
	} else if (currentClientState == ClientState.FailedToConnectToServer) {
		$('#main_info_message').text("Something went wrong. Just give us a moment and we'll try again.");
		$('#info_block #info_title').text("Yikes!");
	} else if (currentClientState == ClientState.NotConnectedToDevice) {
		showActivityIndicator();
	} else if (currentClientState == ClientState.ConnectedToDevice) {
		showDeviceBlock = true;
		var asset_count = deviceStatus['asset_count'];
		debugLog('Device status OK. AssetCount=' + asset_count);
		$('#download_img').attr("src", "img/img_download.png");
		if (asset_count > 0) {
			var imageString = asset_count == 1 ? " image" : " images";
			$('#download_block #info_message').css("display", "none");
			$('#download_button').css("display", "block");
		} else {
			var assetsAreBeingPrepared = deviceStatus['assets_are_being_prepared'];
			if (assetsAreBeingPrepared) {
				$('#download_block #info_message').css("display", "block");
				$('#download_block #info_message').html('Hang on, pictures are being prepared<br><br><img src="img/dots_animation.gif"></img>');
				hideAllButtons();
				$('#download_button').css("display", "none");
			} else {
				$('#download_block #info_message').css("display", "block");
				$('#download_block #info_message').html('Please select photos and videos on the ' + deviceType + ' to download');
				hideAllButtons();
				$('#download_button').css("display", "none");
			}
		}
	} else if (currentClientState == ClientState.Uploading) {
		showDeviceBlock = false;
		$('#main_info_message').text("Upload is in progress. Hold on for a while...");
		$('#info_block #info_title').text("Uploading");
		if (filesToUpload.length == 0) {
			showActivityIndicator();
		}
	} else if (currentClientState == ClientState.Downloading) {
		showDeviceBlock = false;
		$('#main_info_message').text("Download is in progress. Hold on for a while...");
		$('#info_block #info_title').text("Downloading");
		showActivityIndicator();
	}
	if (showDeviceBlock) {
		$('#device_block').css('display', 'block');
		$('#info_block').css('display', 'none');
		var upload_url = 'http://' + local_ip + ':8080/upload';
		$('#upload_form').attr('action', upload_url);
		setupUploader();
	} else {
		$('#device_block').css('display', 'none');
		$('#info_block').css('display', 'block');
	}
}

function requestDeviceIp() {
	debugLog('requesting client IP for permanent_id=' + permanent_id);
	if (static_local_ip) {
		local_ip = static_local_ip;
		setClientState(ClientState.NotConnectedToDevice);
		return;
	}
	$.ajax({
		url: 'getip.php',
		dataType: 'json',
		timeout: 5000,
		data: {
			'permanent_id': permanent_id
		},
		success: function(data) {
			local_ip = data.local_ip;
			if (local_ip == '') {
				debugLog('Failed to get IP: ' + data.error);
				setClientState(ClientState.BadPermanentId);
			} else {
				debugLog('Got IP:' + local_ip);
				setClientState(ClientState.NotConnectedToDevice);
			}
		},
		error: function(jqXHR, textStatus, errorThrown) {
			debugLog(textStatus + ' | ' + errorThrown);
			setClientState(ClientState.FailedToConnectToServer);
		}
	});
}

function requestDeviceStatus(local_ip) {
	var local_url = 'http://' + local_ip + ':8080/status';
	if (shouldUseJSONP == true) {
		$.ajax({
			url: local_url,
			dataType: 'jsonp',
			jsonp: 'jsonp_callback',
			crossDomain: 'true',
			timeout: 3000,
			success: function(data) {
				deviceStatus = data;
				deviceType = deviceStatus['device_type'];
				setClientState(ClientState.ConnectedToDevice);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				debugLog(textStatus + ' | ' + errorThrown);
				setClientState(ClientState.HaveNoLocalIp);
			}
		});
	} else {
		$.ajax({
			url: local_url,
			dataType: 'json',
			crossDomain: 'true',
			timeout: 3000,
			success: function(data) {
				deviceStatus = data;
				deviceType = deviceStatus['device_type'];
				setClientState(ClientState.ConnectedToDevice);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				debugLog(textStatus + ' | ' + errorThrown);
				if (errorThrown.toString() == "No Transport") {
					debugLog("No Transport error, Falling back to JSONP");
					shouldUseJSONP = true;
					requestDeviceStatus(local_ip);
				} else {
					setClientState(ClientState.HaveNoLocalIp);
				}
			}
		});
	}
}

function scheduleRequestDeviceIp() {
	debugLog('Scheduled request client IP');
	showActivityIndicator();
	window.setTimeout(function() {
		requestDeviceIp();
	}, 5000);
}

function schedulerequestDeviceStatus() {
	window.setTimeout(function() {
		requestDeviceStatus(local_ip);
	}, 2000);
}

function hideAllButtons() {
	$('#button_container').html('');
}

function showActivityIndicator() {
	hideAllButtons();
	$('#button_container').html('<img src="img/activity_indicator.gif" alt="..."></img>');
}
var uploader;
function setupUploader() {
	var upload_url = 'http://' + local_ip + ':8080/upload';
	var uploadContainer = $('#upload_button_container');
	uploadContainer.html("");
	$('<div id="upload_plugin" class="upload_button">Upload Photos</div>').appendTo(uploadContainer);
	uploader = new qq.FineUploaderBasic({
		button: $('#upload_plugin')[0],
		maxConnections: 1,
		request: {
			endpoint: upload_url
		},
		validation: {
/* 			allowedExtensions: ['jpg', 'jpeg', 'png', 'cr2', 'mov', 'mp4', 'm4v', '3gp'], */
			acceptFiles: 'image/tiff,image/jpeg,image/gif,image/png,image/bmp,image/ico,image/cur,image/xbm,video/quicktime,video/mp4,video/MPV,video/3gpp'
		},
		retry: {
			enableAuto: true,
			autoAttemptDelay: 2
		},
		text: {
			uploadButton: "Upload Photos"
		},
		callbacks: {
			onSubmit: function(id, fileName) {
				addFileToUpload(id, fileName);
				globalUploadProgress();
				$("#upload_progress #progress").css('width', 0);
				$("#upload_progress").css('opacity', 1);
			},
			onUpload: function(id, fileName) {},
			onProgress: function(id, fileName, loaded, total) {
				if (loaded < total) {
					progress = loaded / total;
					globalUploadProgress(progress);
				} else {}
			},
			onComplete: function(id, fileName, responseJSON) {
				removeFileToUpload(id);
				globalUploadProgress();
				if (responseJSON.success) {
					debugLog('Uploaded: ' + fileName);
				} else {
					debugLog('Oops: ' + fileName + ' not uploaded because: ' + responseJSON.error);
				}
			}
		}
	});
}
var filesToUpload = [];
function addFileToUpload(id, fileName) {
	filesToUpload[id] = fileName;
}

function removeFileToUpload(id) {
	filesToUpload[id] = 'done';
}

function globalUploadProgress() {
	globalUploadProgress(-1);
}

function globalUploadProgress(itemProgress) {
	var i = 0;
	var totalFiles = filesToUpload.length;
	var uploadedFiles = 0;
	for (i = 0; i < totalFiles; i++) {
		if (filesToUpload[i] === 'done') {
			uploadedFiles++;
		}
	}
	var fraction = 0;
	if (itemProgress != -1) {
		fraction = 1 / totalFiles * itemProgress * 100;
	}
	var progress = (uploadedFiles / totalFiles * 100) + fraction;
	$("#upload_progress #progress").css('width', progress + '%');
	debugLog('Global progress: ' + uploadedFiles + '/' + totalFiles + '  (' + progress + '%)');
	if (uploadedFiles == totalFiles) {
		filesToUpload.splice(0, uploadedFiles);
		uploader.reset();
		$("#upload_progress").animate({
			opacity: 0
		}, {
			duration: 400,
			queue: false
		});
		debugLog('Uploading finished');
	}
}

function downloadButtonClicked() {
	var asset_zip_name = deviceStatus['asset_zip_name'];
	var local_url = 'http://' + local_ip + ':8080/files/' + asset_zip_name;
	window.location = local_url;
}
$(document).ready(function() {
	debugLog("DOM loaded");
	permanent_id = getPermanentId();
    requestDeviceIp();
});