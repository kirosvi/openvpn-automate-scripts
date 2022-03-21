<?php

//if (!isset($_SERVER['PHP_AUTH_USER'])) {
//    header('WWW-Authenticate: Basic realm="My Realm"');
//    header('HTTP/1.0 401 Unauthorized');
//    echo 'You have submit Cancel';
//    exit;
//} else {
    $path = $_GET['path'];
    list($folder, $file) = explode("/", $path);
    list($name, $surname, $type, $ext) = explode(".", $file);
    $user= $_SERVER['PHP_AUTH_USER'];
    $rfile = "$name.$surname";

    if ( $rfile == $user) {
      header('X-Accel-Redirect: /protected/'.$path);
    }
    else {
    echo "You have not permission to see this page!";
    }
//}

?>
