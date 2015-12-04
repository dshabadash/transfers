<?php

$db;

function generateRandomString($length = 10) {    
    return substr(str_shuffle("0123456789"), 0, $length);
}

function permanentIdIsUnique($tmp_id) {
	global $db;
	$result = mysql_query("SELECT local_ip FROM pb_permalink WHERE permanent_id='$tmp_id';", $db)
							or _die("Unable to execute query");
	return mysql_num_rows($result) == 0;
}

function echoRespond($perm_id) {
	$responseParams = array(
		'permanent_id' => $perm_id
	);
	$responseBody = json_encode($responseParams);
	echo($responseBody);
}

function activationKeyForDeviceId($dev_id, $ip, $activate_code) {
	if ($activate_code == 1) {
		//activate app
		$crc32 = crc32('Hydrogene12' . $ip .'atok' . $dev_id . '13CapableBits');
	} else if ($activate_code == 2) {
		//deactivate app
		$crc32 = crc32('CherryLime04' . $ip . 'tape' . $dev_id . '07CapableBits');		

		//set activate_code to 0		
		mysql_query("UPDATE pb_permalink SET activate_code=0 WHERE device_id='$dev_id';")
				or die("Unable to update activate_code");

	} else {
		//reserved
		$crc32 = crc32('AlphaBubble01' . $ip . 'glue' . $dev_id . '11CapableBits');		
	}
	$crcStr = sprintf($crc32);
	
	$nums = array('0','1','2','3','4','5','6','7','8','9');
	$letters = array('q','e','t','u','o','s','f','h','n','v');
	$encodedCrcStr = str_replace($nums, $letters, $crcStr);
	
	return $encodedCrcStr;
}

function echoRespondWithActivation($perm_id, $dev_id, $ip, $should_unlock) {
	$key = activationKeyForDeviceId($dev_id, $ip, $should_unlock);

	$responseParams = array(
		'permanent_id' => $perm_id,
		'key' => $key
	);
	$responseBody = json_encode($responseParams);
	echo($responseBody);
}

/* script body */
{
	require_once("db.php");
	global $db;
	$db = db_connect();

	if (! $_GET['id']) die("no id specified");
	if (! $_GET['ip']) die("no ip specified");

	
	$device_id = mysql_escape_string($_GET['id']);
	$local_ip = mysql_escape_string($_GET['ip']);
	$result = mysql_query("SELECT permanent_id, activate_code FROM pb_permalink WHERE device_id='$device_id';", $db)
							or die("Unable to execute query");
							
	$breedStr = '';
	if ($_GET['breed']) $breedStr = $_GET['breed'];
	if ($breedStr == 'oak') {
		$breed = 3;
	} else if ($breedStr == 'walnut') {
		$breed = 2;
	} else if ($breedStr == 'beech') {
		$breed = 1;
	} else {
		$breed = 0;
	}
	
	$row = mysql_fetch_row($result);
	if ($row) {
		$permanent_id = $row[0];
			mysql_query("UPDATE pb_permalink SET local_ip='$local_ip', breed=$breed WHERE device_id='$device_id';")
							or die("Unable to update IP");
		$activate_code = $row[1];
		
		echoRespondWithActivation($permanent_id, $device_id, $local_ip, $activate_code);
	} else {
		if ($_GET['perm_id_prefix']) {
			$perm_id_prefix = mysql_escape_string($_GET['perm_id_prefix']);
		} else {
			$perm_id_prefix = 'user';
		}
		
		$salt_length = 3;
		do {
			$tmp_id = $perm_id_prefix . generateRandomString($salt_length);
			$salt_length += 1;
		} while (! permanentIdIsUnique($tmp_id));
	
		$permanent_id = $tmp_id;
		mysql_query("INSERT INTO pb_permalink (device_id, permanent_id, local_ip, breed) VALUES('$device_id', '$permanent_id', '$local_ip', '$breed');")
							or die("Unable to make permalink");
		echoRespond($permanent_id);
	}

	mysql_close($db);
}

?>