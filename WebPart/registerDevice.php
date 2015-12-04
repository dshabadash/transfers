<?php
    // it is better to recieve and store push token in base64

    require_once("db.php");
    $db = db_connect() or die();

    if (!isset($_POST['token'])) die('FAIL');
    $baseDeviceToken = $_POST['token'];
    $baseDeviceToken = mysql_real_escape_string($baseDeviceToken);


    if (isset($_SERVER['HTTP_USER_AGENT']) &&
        (strpos($_SERVER['HTTP_USER_AGENT'], 'rb:') !== false)) {

        $appid = str_replace('rb:', '', $_SERVER['HTTP_USER_AGENT']);
    }
    else {
        $appid = $_POST['appid'];
    }

    $appid = mysql_real_escape_string($appid);

    
    @$secondsFromGMT = intval($_POST['secondsFromGMT']);

    
    $device = '';
    if (isset($_POST['token2'])) {
        $device = $_POST['token2'];
        $device = mysql_real_escape_string($device);
    }

    
    $device_type = '';
    if (isset($_POST['deviceType'])) {
        $device_type = $_POST['deviceType'];
        $device_type = mysql_real_escape_string($device_type);
    }

    $remote_addr = mysql_real_escape_string($_SERVER['REMOTE_ADDR']);


    $request =
        "REPLACE INTO pb_tokens " .
        "SET " .
            "token='$baseDeviceToken', " .
            "device='$device', " .
            "device_type='$device_type', " .
            "app='$appid', " .
            "gmt_offset='$secondsFromGMT', " .
            "ip='$remote_addr';";

    mysql_query($request);
    mysql_close($db);

    echo 'OK';
?>
