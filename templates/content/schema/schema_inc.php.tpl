<?php /* -*- Mode: php; tab-width: 4; indent-tabs-mode: t; c-basic-offset: 4; -*- */
{{include file="php_file_header.tpl"}}

global $gBitSystem;

// Requirements
$gBitSystem->registerRequirements( {{$PACKAGE}}_PKG_NAME, array(
{{if empty($config.requirements)}}
	'liberty' => array( 'min' => '2.1.0' ),
{{else}}{{foreach from=$config.requirements key=pkg item=reqs name=reqs}}
	'{{$pkg}}' => array( {{foreach from=$reqs key=k item=v name=values}}'{{$k}}' => '{{$v}}',{{/foreach}} ),
{{/foreach}}
{{/if}}
));

$gBitSystem->registerPackageInfo( {{$PACKAGE}}_PKG_NAME, array(
	'description' => "{{$config.description}}",
	{{if $config.license}}'license' => '{{if $config.license.url}}<a href="{{$config.license.url}}">{{/if}}{{$config.license.name}}{{if $config.license.url}}</a>{{/if}}',{{/if}}
));


// Install process
global $gBitInstaller;
if( is_object( $gBitInstaller ) ){

$tables = array(
{{* content types *}}
{{foreach from=$config.types key=typeName item=type}}
    {{include file="type_schema_inc.php.tpl"}}
{{foreach from=$type.typemaps key=typemapName item=typemap}}
    {{include file="typemap_schema_inc.php.tpl" tablePrefix=$typeName}}
{{/foreach}}
{{/foreach}}
{{* services *}}
{{foreach from=$config.services key=serviceName item=service}}
    {{include file="service_schema_inc.php.tpl"}}
{{foreach from=$service.typemaps key=typemapName item=typemap}}
    {{include file="typemap_schema_inc.php.tpl" tablePrefix=$serviceName}}
{{/foreach}}
{{/foreach}}
{{* tables *}}
{{foreach from=$config.tables key=tableName item=table}}
    {{include file="table_schema_inc.php.tpl" tableName=$tableName table=$table}}
{{/foreach}}
);

foreach( array_keys( $tables ) AS $tableName ) {
	$gBitInstaller->registerSchemaTable( {{$PACKAGE}}_PKG_NAME, $tableName, $tables[$tableName] );
}

// $indices = array();
// $gBitInstaller->registerSchemaIndexes( {{$PACKAGE}}_PKG_NAME, $indices );

// Sequences
$gBitInstaller->registerSchemaSequences( {{$PACKAGE}}_PKG_NAME, array (
{{foreach from=$config.types key=typeName item=type name=types}}
	'{{$typeName}}_data_id_seq' => array( 'start' => 1 ),
{{foreach from=$type.typemaps key=typemapName item=typemap}}
{{if $typemap.sequence}}
	'{{$typeName}}_{{$typemapName}}_id_seq' => array( 'start' => 1 ),
{{/if}}
{{/foreach}}
{{/foreach}}
));

// Schema defaults
$defaults = array(
{{foreach from=$config.types key=typeName item=type name=types}}
{{foreach from=$type.defaults item=default}}
	"INSERT INTO `{{$typeName}}_data` {{$default}}"{{if !$smarty.foreach.types.last}},{{/if}}
{{/foreach}}{{/foreach}}
);
if (count($defaults) > 0) {
	$gBitInstaller->registerSchemaDefault( {{$PACKAGE}}_PKG_NAME, $defaults);
}


// User Permissions
$gBitInstaller->registerUserPermissions( {{$PACKAGE}}_PKG_NAME, array(
	array ( 'p_{{$package}}_admin'  , 'Can admin the {{$package}} package', 'admin'      , {{$PACKAGE}}_PKG_NAME ),
	array ( 'p_{{$package}}_view'  , 'Can view the {{$package}} package', 'basic'      , {{$PACKAGE}}_PKG_NAME ),
{{foreach from=$config.types key=typeName item=type name=types}}
	array ( 'p_{{$typeName}}_create' , 'Can create a {{$typeName}} entry'   , '{{$type.permissions.default.create|default:registered}}' , {{$PACKAGE}}_PKG_NAME ),
	array ( 'p_{{$typeName}}_view'   , 'Can view {{$typeName}} entries'     , '{{$type.permissions.default.view|default:basic}}'      , {{$PACKAGE}}_PKG_NAME ),
	array ( 'p_{{$typeName}}_update' , 'Can update any {{$typeName}} entry' , '{{$type.permissions.default.update|default:editors}}'    , {{$PACKAGE}}_PKG_NAME ),
	array ( 'p_{{$typeName}}_expunge', 'Can delete any {{$typeName}} entry' , '{{$type.permissions.default.expunge|default:admin}}'      , {{$PACKAGE}}_PKG_NAME ),
	array ( 'p_{{$typeName}}_admin'  , 'Can admin any {{$typeName}} entry'  , '{{$type.permissions.default.admin|default:admin}}'      , {{$PACKAGE}}_PKG_NAME ),
{{/foreach}}
));

// Default Preferences
$gBitInstaller->registerPreferences( {{$PACKAGE}}_PKG_NAME, array(
{{foreach from=$config.types key=typeName item=type name=types}}
	array ( {{$PACKAGE}}_PKG_NAME , '{{$typeName}}_default_ordering'      , '{{$typeName}}_id_desc' ),
{{*	array ( {{$PACKAGE}}_PKG_NAME , 'list_{{$typeName}}_id'               , 'y'              ), *}}
{{if $type.title}}
	array ( {{$PACKAGE}}_PKG_NAME , '{{$typeName}}_list_title'            , 'y'              ),
{{/if}}
{{if $type.summary}}
	array ( {{$PACKAGE}}_PKG_NAME , '{{$typeName}}_list_summary'          , 'y'              ),
{{/if}}
{{if $config.homeable}}
	array ( {{$PACKAGE}}_PKG_NAME , '{{$package}}_{{$typeName}}_home_id'               , 0                ),
{{if $smarty.foreach.types.first}}
	array ( {{$PACKAGE}}_PKG_NAME , '{{$package}}_home_type'                    , '{{$typeName}}'      ),
{{/if}}
{{/if}}
{{/foreach}}
));

// ### Register content types
$gBitInstaller->registerContentObjects( {{$PACKAGE}}_PKG_NAME, array(
{{foreach from=$config.types key=typeName item=type name=types}}
    '{{$type.class_name}}'=>{{$PACKAGE}}_PKG_PATH.'{{$type.class_name}}.php',
{{/foreach}}
));

{{if $config.pluggable}}
// Process plugin settings
$gBitInstaller->loadPackagePluginSchemas( {{$PACKAGE}}_PKG_NAME );
{{/if}}

}
