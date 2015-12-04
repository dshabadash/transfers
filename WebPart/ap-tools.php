<?php
define('SDB_DOMAIN', 'readdle-push-db');

$deviceTables = array('com.readdle.Scanner'=>"scannerPro",
                      'com.readdle.Shakespeare'=>'shakespeareLite',
                      'com.readdle.BookReaderLite'=>"bookReaderLite");



function apBase64ToUDID($base, $force_base=false) {
	$head = substr($base, 0, 4);
	if (($head != 'r64[') && ($force_base == false))
		return $base;
		
	$base = substr($base, 4, strlen($base) - 5);
	$data = base64_decode($base);
	$retval = '';
	
    $slen = strlen($data);
    for($i=0; $i<$slen; $i++)
		$retval .= bin2hex($data[$i]);

	return $retval;
}


function apUDIDToBase64($hex) {
	if (preg_match('|^[0-9a-fA-F]+$|', $hex) == false)
		return $hex;

    $data = '';
    $twohex = '';
    
    $slen = strlen($hex);
    for($i=0; $i<$slen; $i++) {
        $c = $hex[$i];
        if (preg_match('|[0-9a-fA-F]|', $c) == false)
            continue;
        
        $twohex .= $c;
        
        if (strlen($twohex) == 2) {
            $data .= chr(hexdec($twohex));
            $twohex = '';
        }
    }
    
    return 'r64['.base64_encode($data).']';
}



function apHexToBase64($hex) {
    $data = '';
    $twohex = '';
    
    $slen = strlen($hex);
    for($i=0; $i<$slen; $i++) {
        $c = $hex[$i];
        if (preg_match('|[0-9a-fA-F]|', $c) == false)
            continue;
        
        $twohex .= $c;
        
        if (strlen($twohex) == 2) {
            $data .= chr(hexdec($twohex));
            $twohex = '';
        }
    }
    
    return base64_encode($data);
}

function apBase64toHex($base64, $sep = '') {
    $data = base64_decode($base64);
    
    $hex_i = 0;
    $hex = '';
    $slen = strlen($data);
    for($i=0; $i<$slen; $i++) {
        $c = $data[$i];
        $x = dechex(ord($c));
        if (strlen($x) == 1)
            $x = '0'.$x;
        $hex .= $x;
        $hex_i++;
        
        if ($sep != '') {
            if ($hex_i % 4 == 0)
	        $hex .= $sep;
        }
        
    }
    return rtrim($hex);
}


