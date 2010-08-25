<?php /* -*- Mode: php; tab-width: 4; indent-tabs-mode: t; c-basic-offset: 4; -*- */
/* vim: :set fdm=marker : */
{{include file="php_file_header.tpl"}}

global $gBitSystem, $gBitUser, $gLibertySystem;

// If package is active and the user has view auth then register the package menu
if( $gBitSystem->isPackageActive( '{{$config.package}}' ) && $gBitUser->hasPermission( 'p_{{$config.package}}_view' ) ) {
	// service functions
	require_once( CONFIG_PKG_PATH.'{{$config.package}}/plugins/{{$config.plugin}}/{{$config.class_name}}.php' );

	define( 'LIBERTY_SERVICE_{{$config.name|strtoupper}}', '{{$config.type}}' );

    $gLibertySystem->registerService(
		LIBERTY_SERVICE_{{$config.name|strtoupper}},
		{{$PACKAGE}}_PKG_NAME,
        array(
{{foreach from=$config.services.functions key=func item=typemaps}}
			'{{$func}}_function' => '{{$config.name}}_{{$func}}',
{{/foreach}}
{{foreach from=$config.services.files key=file item=typemaps}}
{{if $file eq 'content_edit_mini'}}{{assign var=tplfile value='service_edit_mini_inc.tpl'}}{{/if}}
{{if $file eq 'content_edit_tab'}}{{assign var=tplfile value='service_edit_tab_inc.tpl'}}{{/if}}
			'{{$file}}_tpl' => 'bitpackage:{{$config.package}}/{{$config.name}}/{{$tplfile}}',
{{/foreach}}
        ),
        array(
			'description' => '{{$config.description}}'
        )
    );
}
/* =-=- CUSTOM BEGIN: setup_plugin -=-= */
{{if !empty($customBlock.setup_plugin)}}
{{$customBlock.setup_plugin}}
{{else}}

{{/if}}
/* =-=- CUSTOM END: setup_plugin -=-= */


