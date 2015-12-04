<?php

$db;

/* script body */
{
	require_once("db.php");
	global $db;
	$db = db_connect();

	$permanent_id = false;
	if ($_GET['permanent_id'] ) $permanent_id = $_GET['permanent_id'];

	$ask_for_id = true;

	if ($permanent_id) {
		$permanent_id = htmlentities($permanent_id);
		$permanent_id = mysql_escape_string($permanent_id);
		
		echo("Permanent ID: $permanent_id<br>");
		
		if ($_GET['activate'] == 1) {
			echo('Activating...');
			
			mysql_query("UPDATE pb_permalink SET activate_code=1 WHERE permanent_id='$permanent_id';")
				or die("Unable to update activate_code");
			
			echo("<script type=\"text/javascript\">window.location = \"http://sendp.com/activate.php?permanent_id=$permanent_id\";</script>");
			
			exit(0);
		} else if ($_GET['activate'] == 2) {
			echo ('Deactivating...');
			
			mysql_query("UPDATE pb_permalink SET activate_code=2 WHERE permanent_id='$permanent_id';")
				or die("Unable to update activate_code");

			echo("<script type=\"text/javascript\">window.location = \"http://sendp.com/activate.php?permanent_id=$permanent_id\";</script>");
			
			exit(0);
		}
		
		$result = mysql_query("SELECT activate_code, breed FROM pb_permalink WHERE permanent_id='$permanent_id';", $db)
						or die("Unable to execute query");
	
		$row = mysql_fetch_row($result);
		if ($row) {
			$breed = $row[1];
			if ($breed == 0) {
				echo("Free version, unactivated.");
			} else if ($breed == 1) {
				echo("Free version, Plus by InApp");
			} else if ($breed == 2) {
				echo("Free version, Plus by Admin");
			} else {
				echo("Plus version");
			}
			echo('<br>');
		
			if ($breed < 3) {
				$activate_code = $row[0];
				if ($activate_code == 1) {
					echo("Status: Activated
						<a href=\"activate.php?permanent_id=$permanent_id&activate=2\">Deactivate</a>
					");
				} else if ($activate_code == 2) {
					echo("Status: Waiting for deactivation
						<a href=\"activate.php?permanent_id=$permanent_id&activate=1\">Activate</a>
					");
				} else {
					echo("Status: Neutral
						<a href=\"activate.php?permanent_id=$permanent_id&activate=1\">Activate</a>
						<a href=\"activate.php?permanent_id=$permanent_id&activate=2\">Deactivate</a>
					");
				}
			}
			
			$ask_for_id = false;
		} else {
			echo('Incorrect ID');
		}
	}
	
	if ($ask_for_id) {
		echo('<form name="input" action="activate.php" method="get">
				Permanent ID: <input type="text" name="permanent_id">
				<input type="submit" value="Submit">
			</form>
		');
	}
}

?>
<br><br>
<a href="activate.php">Check another ID</a>
