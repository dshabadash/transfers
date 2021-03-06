<html>
<head>
    <meta http-equiv="X-UA-Compatible" content="chrome=1" />
    <meta charset="utf-8">
    <link rel="stylesheet" href="client.css" type="text/css">
    <link rel="stylesheet" href="fineuploader-3.6.2.css" type="text/css">
    <script type="text/javascript" src="jquery-1.8.3.min.js">
</script>
    <script type="text/javascript" src="jquery.fineuploader-3.6.2.min.js">
</script>
    <script type="text/javascript" src="client.js">
</script>
    <script type="text/javascript">

        //GET_PERMANENT_ID
        function getPermanentId() {
            return "<?php echo $_GET['permanent_id'] ?>";
        }

        //PORT
        var static_port = undefined;

        //STATIC_LOCAL_IP
        var static_local_ip = undefined;
    </script>

    <title></title>
</head><!--  -->

<body>
    <div id="top_bg">
        <div class="main_title" align="center">
            Image Transfer
        </div>
    </div>

    <div id="bottom_bg">
        <div class="main_footer" align="center">
            <a href="http://capablebits.com" target="_blank">Copyright © 2012 Capable Bits</a><br>
            <br>
            <a href="http://www.facebook.com/CapableBits" target="_blank"><img src="img/icon_facebook.png" alt="icon_facebook" width="" height=""></a> <a href="http://twitter.com/capablebits" target="_blank"><img src="img/icon_twitter.png" alt="icon_twitter" width="" height=""></a> <a href="mailto:team@capablebits.com"><img src="img/icon_email.png" alt="icon_email" width="" height=""></a>
        </div>
    </div>

    <div align="center">
        <div id="main_block" class="main_block">
            <div class="info_block"><img src="img/main_block_bg.png"></div>

            <div id="info_block" class="info_block">
                <div id="info_title"></div>

                <div id="main_info_message">
                    <br>
                    Loading...
                </div>

                <div id="button_container" align="center">
                </div>

                <div id="button_container2" align="center">
                    <div id="upload_progress" align="center">
                        <div id="progress_internal" align="center">
                            <div id="progress"></div>
                        </div>
                    </div>
                </div>
            </div>

            <div id="device_block" class="info_block">
                <div id="device_info_message">
                    Please keep the app running on your iPhone while transfer is in progress.
                </div>

                <div id="device_vertical_line"><img src="img/vertical_line.png" alt="vertical_line"></div>

                <div class="action_block" id="download_block" align="center">
                    <img id="download_img" src="img/img_download.png" alt="img_download">

                    <div class="info_message" id="info_message"></div>

                    <div id="button_container" class="device_button_container" align="center">
                        <div id="download_button" class="download_button" align="center" onclick="downloadButtonClicked()">
                            Download Photos
                        </div>
                    </div>
                </div>

                <div class="action_block" id="upload_block" align="center">
                    <img src="img/img_upload.png" alt="img_upload">

                    <div class="info_message"></div>

                    <div id="upload_button_container" class="device_button_container" align="center">
                        <div id="upload_plugin" class="upload_button">
                            Upload Photos
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="debug">
        Page is loading...
    </div>
</body>
</html>
