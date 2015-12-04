<?php

function echo_result($error_description, $local_ip_address) {
	echo "{
	\"error\" : \"$error_description\",
	\"local_ip\" : \"$local_ip_address\"
	}
	";
}

function _die($error_description) {
	echo_result($error_description, "");	
	exit(-1);
}


/* script body */
{
	require_once("db.php");
	$db = db_connect();
	
	if (! $_GET['permanent_id']) _die("no permanent_id specified");
	
	$permanent_id = mysql_escape_string($_GET['permanent_id']);
	$result = mysql_query("SELECT local_ip FROM pb_permalink WHERE permanent_id='$permanent_id';", $db)
							or _die("Unable to execute query");
	
	$row = mysql_fetch_row($result);
	if ($row) {
		$local_ip = $row[0];
		echo_result("", $local_ip);
	} else {
		$local_ip = "";
		echo_result("unknown permanent_id", $local_ip);
	}
	
	mysql_close($db);
}

?>