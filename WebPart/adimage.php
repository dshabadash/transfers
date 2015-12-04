<?php
//
//  PhotoBox
//
//  Created by Viacheslav Savchenko vs.savchenko@readdle.com on 7/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

    require_once("db.php");

    $app_name = $_GET['app_name'];

    if (!shouldLoadImage($app_name)) {
        exit(0);
    }

    
    $image_width = $_GET['width'];
    $image_height = $_GET['height'];

    $image_size = array (
        'width' => $image_width,
        'height' => $image_height
    );

    $ad_image_path = adImagePath($app_name, $image_size);

    if ($ad_image_path) {
        header('Content-Type: image/jpeg');
        readfile($ad_image_path);
    }


/* Functions */

    function shouldLoadImage($app_name) {
        $shouldLoadImage = FALSE;

        $db = db_connect();

        if (!$db) {
            return $shouldLoadImage;
        }


        $escaped_app_name = mysql_real_escape_string($app_name);
        $query =
            "SELECT * " .
            "FROM pb_settings " .
            "WHERE app_name='$escaped_app_name' AND show_ad_image='1';";

        $result = mysql_query($query, $db);

        if (mysql_num_rows($result) > 0) {
            $launch_number = $_GET['launch_number'];

            $shouldLoadImage = (($launch_number == 1) ||
                                ($launch_number == 10) ||
                                ($launch_number == 15));

            if (!$shouldLoadImage) {
                mysql_free_result($result);

                $query =
                    "SELECT * " .
                    "FROM pb_settings " .
                    "WHERE app_name='$escaped_app_name' AND show_ad_constantly='1';";

                $result = mysql_query($query, $db);
                $shouldLoadImage = (mysql_num_rows($result) > 0);
            }
        }
        
        mysql_close($db);

        
        return $shouldLoadImage;
    }

    /*  Ad image sizes.
     *
     *  320x480 iphone size, portrait orientation
     *  320x568 iphone5 size, portrait orientation
     *  540x620 ipad size, UIModalPresentationFormSheet
     */
    function adImagePath($app_name, $image_size) {
        if (($image_size['width'] <= 320) &&
            ($image_size['height'] <= 480)) {

            // Path below should be changed to real ad image path
            $image_path = "ad/ad.jpg";
        }
        else if (($image_size['width'] <= 320) &&
                 ($image_size['height'] <= 568)) {

            // Path below should be changed to real ad image path
            $image_path = "ad/ad.jpg";
        }
        else if (($image_size['width'] <= 540) &&
                 ($image_size['height'] <= 620)) {

            // Path below should be changed to real ad image path
            $image_path = "ad/ad.jpg";
        }
        /* Other size-matching conditions
        elseif () {
        }
        */

        return $image_path;
    }

?>