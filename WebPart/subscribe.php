<?php

$db;


function emailIsUnique($tmp_id) {
	global $db;
	$result = mysql_query("SELECT email FROM pb_subscribers WHERE email='$tmp_id';", $db)
							or _die("Unable to execute query");
	return mysql_num_rows($result) == 0;
}

/* script body */
{
	require_once("db.php");
	global $db;
	$db = db_connect();

	if (! $_GET['email']) die("no email specified");

	$email = mysql_real_escape_string($_GET['email']);
	
	if (isset($_GET['unsubscribe']) && $_GET['unsubscribe']) {
		//unsubscribe
		if (!emailIsUnique($email)) {
			mysql_query("UPDATE pb_subscribers SET enabled='0' WHERE email='$email';")
					or die("Unable to enable email");
		}
	} else {
        $app_price = mysql_real_escape_string($_GET['app_price']);
        $device = mysql_real_escape_string($_GET['device']);
        $app_name = mysql_real_escape_string($_GET['app_name']);
        
		//subscribe
		if (emailIsUnique($email)) {
			mysql_query("INSERT INTO pb_subscribers (email, enabled, app_price, device, app_name) VALUES('$email', '1', '$app_price', '$device', '$app_name');")
								or die("Unable to add email");
		} else {
			mysql_query("UPDATE pb_subscribers SET enabled='1', app_price='$app_price', device='$device', app_name='$app_name' WHERE email='$email';")
					or die("Unable to enable email");
		}
	}
	
	mysql_close($db);
}

?>