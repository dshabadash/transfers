<?php
require_once("../sendp.com/db.php");
require '../ap-tools.php';

// Adjust to your timezone
date_default_timezone_set('UTC');

// Report all PHP errors
error_reporting(-1);

// Using Autoload all classes are loaded on-demand
require_once 'ApnsPHP/Autoload.php';

// Parameters:
// $msg_id  id field value
// $app_name app field value
// $cert_file_path path to application provision certificate, MUST match with $app_name
// $environment ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION or ApnsPHP_Abstract::ENVIRONMENT_SANDBOX
function pushMessage($msg_id, $app_name, $cert_file_path, $environment = ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION) {

    $db = db_connect();
    if (!$db) {
        echo "Cant connect to database, app: $app_name";
        return;
    }

    
    // Instanciate a new ApnsPHP_Push object
    //$push = new ApnsPHP_Push(
    //	ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION,
    //	'../certs/_production_cert_.pem'
    //);
    //
    $push = new ApnsPHP_Push($environment, $cert_file_path);


    // Set the Root Certificate Autority to verify the Apple remote peer
    $push->setRootCertificationAuthority('../certs/entrust_root_certification_authority.pem');

    // Connect to the Apple Push Notification Service
    $push->connect();


    // Check if there is message to push
    
    $result = mysql_query(
        "SELECT text, iphone_link, iphone5_link, ipad_link " .
        "FROM pb_messages " .
        "WHERE id='$msg_id';"
    );

    list($push_text) = mysql_fetch_row($result);
    if ($push_text == false) {
        echo "No Push Text app: $app_name\n";
        return;
    }

    echo "Push text:" . $push_text . "\n";


    // Request all tokens registred from target app
    
    $server_offset = date_offset_get(new DateTime);
    
    $where_condition = '';
    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION) {
        $where_condition = "app='$app_name' AND ts < (NOW() - INTERVAL 24 HOUR)";
    }
    else {
        $where_condition = "app='$app_name'";
    }

    $result = mysql_query(
        "SELECT token, app, gmt_offset " .
        "FROM pb_tokens " .
        "WHERE $where_condition " .
        "ORDER BY gmt_offset DESC;"
    );

    echo "all " . mysql_num_rows($result) . "\n";

    
    $cnt = 0;
    while((list($token, $app, $gmt_offset) = mysql_fetch_row($result))) {

        // Check if message already had been sent to device identified by token

        $check_result = mysql_query(
            "SELECT token " .
            "FROM pb_token_sent " .
            "WHERE message_id='$msg_id' AND token='$token';"
        );

        $check = (mysql_num_rows($check_result) > 0);
        if ($check !== false) {
            if ($environment == ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION) {
                continue;
            }
        }
        

        // Check if message should be sent on target device according to
        // target device local time

        $time = time() - $server_offset + $gmt_offset;
        $hh = intval(gmdate('G', $time));

        // $hh is TIME in 24 hour format
        if (($hh < 10) || ($hh > 22)) {
            if ($environment == ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION) {
                continue;
            }
        }


        mysql_query(
            "REPLACE INTO pb_token_sent " .
            "SET token='$token', message_id='$msg_id';"
        );

        error_log(date('r') . " sending to {$token}\n", 3, "push.log");


        // Do not push message if token value is not valid

        $push_t = apBase64toHex($token);
        if (!preg_match('~[a-f0-9]{64}~i', $push_t)) {
            continue;
        }


        // sending
        $message = new ApnsPHP_Message($push_t);
        $message->setCustomIdentifier("msg".$cnt);
        $message->setBadge(0);
        $message->setText($push_text);
        $message->setSound();
        $message->setCustomProperty('user', array('message_id' => $msg_id));
        $message->setExpiry(3600);
        $push->add($message);
        //

        $cnt++;

        if ($cnt % 1000 == 0) {
            $push->send();
            clean_tokens($push);
        }

    }

    echo "done sending {$cnt}\n";


    // Send all messages in the message queue
    $push->send();

    clean_tokens($push);

    // Disconnect from the Apple Push Notification Service
    $push->disconnect();
}

function clean_tokens($push) {
    // Examine the error message container
    $aErrorQueue = $push->getErrors();

    foreach($aErrorQueue as $error) {
        $msg = $error['MESSAGE'];
        $rec = $msg->getRecipient();
        $rec_base = apHexToBase64($rec);

        echo "removing token {$rec}: {$rec_base}\n";
        $rec_base = mysql_real_escape_string($rec_base);
        error_log("DELETE FROM pb_tokens WHERE token='{$rec_base}' LIMIT 1;\n", 3, "sql_del.sql");
    }
}
