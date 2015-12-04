<?php
    require 'push.php';

    // Set $msg_id and choose environment
    // ENVIRONMENT_SANDBOX is for tests only

    
    $msg_id = '';

    //$environment = ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION;
    $environment = ApnsPHP_Abstract::ENVIRONMENT_SANDBOX;

    // It will be set depending on the $environment value
    $cert_file_path = '';


    //
    // ImageTransferPlus
    //

    $app = 'ImageTransferPlus';

    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/image_transfer_plus_dev.pem';
    }
    else {
        $cert_file_path = '../certs/image_transfer_plus_production.pem';
    }

    try {
        pushMessage($msg_id, $app, $cert_file_path, $environment);
    }
    catch (Exception $e) {
        echo 'Caught exception: ',  $e->getMessage(), "\n";
    }


    //
    // ImageTransfer
    //

    $app = 'ImageTransfer';

    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/image_transfer_dev.pem';
    }
    else {
        $cert_file_path = '../certs/image_transfer_production.pem';
    }

    try {
        pushMessage($msg_id, $app, $cert_file_path, $environment);
    }
    catch (Exception $e) {
        echo 'Caught exception: ',  $e->getMessage(), "\n";
    }


    //
    // VideoTransferPlus
    //

    $app = 'VideoTransferPlus';

    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/video_transfer_plus_dev.pem';
    }
    else {
        $cert_file_path = '../certs/video_transfer_plus_production.pem';
    }

    try {
        pushMessage($msg_id, $app, $cert_file_path, $environment);
    }
    catch (Exception $e) {
        echo 'Caught exception: ',  $e->getMessage(), "\n";
    }


    //
    // VideoTransfer
    //

    $app = 'VideoTransfer';

    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/video_transfer_dev.pem';
    }
    else {
        $cert_file_path = '../certs/video_transfer_production.pem';
    }

    try {
        pushMessage($msg_id, $app, $cert_file_path, $environment);
    }
    catch (Exception $e) {
        echo 'Caught exception: ',  $e->getMessage(), "\n";
    }


    //
    // Vitrum
    //

    $app = 'Vitrum';

    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/vitrum_dev.pem';
    }
    else {
        $cert_file_path = '../certs/vitrum_production.pem';
    }
    
    try {
        pushMessage($msg_id, $app, $cert_file_path, $environment);
    }
    catch (Exception $e) {
        echo 'Caught exception: ',  $e->getMessage(), "\n";
    }
