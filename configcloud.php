<?php

unset($CFG);
global $CFG;
$CFG = new stdClass();

$phpport = 7000;
if (getenv('PHPPORT')) {
    $phpport = getenv('PHPPORT');
} elseif (!empty($_SERVER['SERVER_PORT'])) {
    $phpport = $_SERVER['SERVER_PORT'];
}

$CFG->dbtype    = 'pgsql';
#$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'db-'.$phpport;
$CFG->dbuser    = 'ubuntu';
$CFG->dbpass    = 'someshi!zzz';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbsocket' => 1,
);

$CFG->wwwroot   = 'http://127.0.0.1';
$CFG->dataroot  = '/mnt/ramdisk/sitedata/site';  # just a real fake, cos it's needed :D
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

$CFG->passwordsaltmain = '';

$CFG->noemailever = true;  // turn off all emails

#behat setup
$CFG->behat_prefix = 'behat_';
$CFG->behat_dataroot = '/mnt/ramdisk/sitedata/behat-'.$phpport;
$CFG->behat_wwwroot   = 'http://localhost:'.$phpport;

$CFG->behat_config = array(
    'default' => array(
        /*'filters' => array(
           'tags' => '~@_switch_window'
        ),*/
        'extensions' => array(
            'Behat\MinkExtension\Extension' => array(
                'selenium2' => array(
                    #'browser' => 'chrome',
                    'capabilities' => array( #we need this capability thang in order to use selenium hub
                        'version' => ''
                    )
                )
            )
        )
    ),
);

#phpunit setup
$CFG->phpunit_prefix = 'phpu_';
$CFG->phpunit_dataroot = '/mnt/ramdisk/sitedata/phpunit';

unset($phpport);

require_once(dirname(__FILE__) . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
