<?php

/* Database settings */
$db_host = "localhost";
$db_user = "sendp";
$db_pass = "patrBnpDZrvq4xI9";
$db_name = "sendp";

/* Connect to database */
function db_connect() {
	global $db_host, $db_user, $db_pass, $db_name;

	$db = mysql_connect($db_host, $db_user, $db_pass);
	if (!$db) {
		_die('Failed to connect to DB');
	}

	mysql_select_db($db_name, $db) or _die('Failed to select DB');

	return $db;
}

/* Default _die implementation (replace to generate custom JSON response) */
if (!function_exists("_die")) {
	function _die($error_description) {
		die($error_description);
	}
}

// Returns a message from table pb_messages as array of fields
function get_message($id) {
    $message = array();

    if ($id < 0) {
        return $message;
    }
    

    $query =
        "SELECT text, iphone_link, iphone5_link, ipad_link, ad_link " .
        "FROM pb_messages " .
        "WHERE id='$id';";

    $result = mysql_query($query);

    if (mysql_num_rows($result) > 0) {
        list($push_text,
             $iphone_link,
             $iphone5_link,
             $ipad_link,
             $ad_link) = mysql_fetch_row($result);

        $message = array (
            'text' => $push_text,
            'iphone_link' => $iphone_link,
            'iphone5_link' => $iphone5_link,
            'ipad_link' => $ipad_link,
            'ad_link' => $ad_link
        );
    }
    
    mysql_free_result($result);
    
    return $message;
}

?>