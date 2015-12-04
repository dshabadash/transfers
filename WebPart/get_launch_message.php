<?php
//
//  PhotoBox
//
//  Created by Viacheslav Savchenko vs.savchenko@readdle.com on 7/22/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//
//  Return a message to show on application launch
//

    require_once("db.php");

    db_connect() or die();


    $message = array();

    $app_name = $_GET['app_name'];
    $launch_number = $_GET['launch_number'];
    $message_id = message_id($app_name, $launch_number);
    $message = get_message($message_id);
    $message = json_encode($message);

    echo $message;

    
    mysql_close($db);


/* Functions */

    // Returns a message id or -1 if message should not be loaded
    function message_id($app_name, $launch_number) {

        $escaped_app_name = mysql_real_escape_string($app_name);
        $query =
            "SELECT * " .
            "FROM pb_settings " .
            "WHERE app_name='$escaped_app_name';";

        $result = mysql_query($query);

        if (mysql_num_rows($result) > 0) {
            list($app,
                 $show_ad_image,
                 $show_ad_constantly,
                 $message_id) = mysql_fetch_row($result);

            $show_ad_time = (($launch_number == 1) ||
                             ($launch_number == 10) ||
                             ($launch_number == 15));

            $shouldLoadAdImage = (($show_ad_image && show_ad_time) || 
                                  ($show_ad_image && $show_ad_constantly));

            if ($shouldLoadAdImage) {
                return $message_id;
            }
        }
        
        return -1;
    }
