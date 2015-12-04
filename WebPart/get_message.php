<?php
//
//  PhotoBox
//
//  Created by Viacheslav Savchenko vs.savchenko@readdle.com on 7/22/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//
//  Script returns message paylod for given id
//
    
    require_once("db.php");

    db_connect() or die();


    $message_id = $_GET['id'];
    if (!isset($message_id)) {
        die('get_message: Message id is not set');
    }

    $message_id = intval($message_id);
    $message = get_message($message_id);
    $message = json_encode($message);

    echo $message;


    mysql_close($db);
