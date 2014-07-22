<?php

$JOBNAME = basename(dirname(__DIR__));

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
#$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = $JOBNAME;
$CFG->dbuser    = 'jenkins';
$CFG->dbpass    = 'huds13!';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbsocket' => 1,
);

$CFG->wwwroot   = 'http://127.0.0.1/'.$JOBNAME;
$CFG->dataroot  = '/var/lib/jenkins/elearning/sitedata/site';  # just a real fake, cos it's needed :D
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

$CFG->passwordsaltmain = '';

$CFG->noemailever = true;  // turn off all emails

#behat setup
$CFG->behat_prefix = 'behat_';
$CFG->behat_dataroot = '/var/lib/jenkins/elearning/sitedata/behat_'.$JOBNAME;
$CFG->behat_wwwroot   = 'http://'.$JOBNAME.'.localhost:8000';
#$CFG->behat_switchcompletely = true;  # for php 5.3

#phpunit setup
$CFG->phpunit_prefix = 'phpu_';
$CFG->phpunit_dataroot = '/var/lib/jenkins/elearning/sitedata/phpunit_'.$JOBNAME;

unset($JOBNAME);

require_once(dirname(__FILE__) . '/lib/setup.php');

function gzopen($filename, $mode, $use_include_path = 0) {  // temp bullshit hack until we get a new box
    return gzopen64($filename, $mode, $use_include_path);
}

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
