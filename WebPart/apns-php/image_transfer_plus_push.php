<?php
    require 'push.php';

    // Set $msg_id and choose environment
    // ENVIRONMENT_SANDBOX is for tests only

    $msg_id = '';
    $app = 'ImageTransferPlus';

    //$environment = ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION;
    $environment = ApnsPHP_Abstract::ENVIRONMENT_SANDBOX;

    $cert_file_path = '';
    if ($environment == ApnsPHP_Abstract::ENVIRONMENT_SANDBOX) {
        $cert_file_path = '../certs/image_transfer_plus_dev.pem';
    }
    else {
        $cert_file_path = '../certs/image_transfer_plus_production.pem';
    }

    pushMessage($msg_id, $app, $cert_file_path, $environment);
