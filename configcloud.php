<?php

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
#$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'jenkins';
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
$CFG->behat_dataroot = '/mnt/ramdisk/sitedata/behat';
$CFG->behat_wwwroot   = 'http://localhost:8000';

$CFG->behat_config = array(
    'default' => array(
        'extensions' => array(
            'Behat\MinkExtension\Extension' => array(
                'selenium2' => array(
                    'capabilities' => array( #we need this capability thang in order to use selenium hub
                        'version' => ''
                    )
                )
            )
        )
    ),
);

//for phantomjs - add to behat_config to run tests via selenium
/*$CFG->behat_config = array(
       'default' => array(
           'filters' => array(
               'tags' => '~@_switch_window&&~@_file_upload&&~@_alert&&~@_bug_phantomjs'
           ),
          'extensions' => array(
              'Behat\MinkExtension\Extension' => array(
                  'selenium2' => array(
                      'browser' => 'phantomjs',
                      'wd_host' => 'http://localhost:7777/wd/hub'
                  )
              )
          )
       ),
    );
*/

#phpunit setup
$CFG->phpunit_prefix = 'phpu_';
$CFG->phpunit_dataroot = '/mnt/ramdisk/sitedata/phpunit';


require_once(dirname(__FILE__) . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
