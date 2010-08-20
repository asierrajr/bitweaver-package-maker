<?php /* -*- Mode: php; tab-width: 4; indent-tabs-mode: t; c-basic-offset: 4; -*- */
/* vim: :set fdm=marker : */
/**
 * $Header: $
 *
 * Copyright (c) 2010 Tekimaki LLC http://tekimaki.com
 * Copyright (c) 2010 will james will@tekimaki.com
 * Copyright (c) 2010 nick palmer@overtsolutions.com
 *
 * All Rights Reserved. See below for details and a complete list of authors.
 * Licensed under the GNU LESSER GENERAL PUBLIC LICENSE. See http://www.gnu.org/copyleft/lesser.html for details
 *
 * $Id: $
 * @package pkgmkr
 * @subpackage functions
 */

abstract class aRenderer{
	abstract public static function validateConfig( $config ); 
	abstract public function prepConfig( &$config ); 
	abstract public function generate( $config );
	abstract public static function convertName( $file, $config, $params = array() );
	abstract public static function renderFiles( $config, $dir, $files ); 

	protected function initSmarty(){
		global $gBitSmarty;

		require_once(BIT_ROOT_PATH . "util/smarty/libs/Smarty.class.php");
		$gBitSmarty = new Smarty();
		$gBitSmarty->template_dir = PKGMKR_PKG_PATH . "templates";
		$gBitSmarty->compile_dir = BIT_ROOT_PATH . "temp/templates_c";

		// Turn off tr prefilter so those tags come out right
		//	$gBitSmarty->unregister_prefilter('tr');

		// set the delimiters for tags
		$gBitSmarty->left_delimiter = "{{";
		$gBitSmarty->right_delimiter = "}}";

		$gBitSmarty->default_template_handler_func = "find_pkgmkr_template";
	}

	/**
	 * validateSchema
	 */
	public static function validateSchema( &$configHash, $name, $schema, $schemaType = 'type' ){
		if ( substr( $name,0,2 ) === 'pg' ){
			error("Do not start $schemaType names with 'pg' as there is a bug in the ADODB library which causes it to not see tables with names start with 'pg'" );
		}
		if (empty($schema['class_name'])) {
			$configHash[$name]['class_name'] = 'Bit'.ucfirst($name);
		}
		if (empty($schema['description'])) {
			error("A description is required for $name");
		}
		if (empty($schema['base_class'])) {
			error("A base class is required for $name");
		}
		if (empty($schema['base_package'])) {
			error("A base package is required for $name");
		}
		if ( $schemaType == 'type' && empty($schema['content_name'])) {
			error("A content name is required for $name");
		}

		$excludeFields = array( 'title', 'data', 'summary' );			// yaml may specify settings for auto generated fields in the field list, so we exclude them from requirements checks
		if( !empty( $type['fields'] ) ){
			foreach ($schema['fields'] as $fieldName => $field) {
				if( !in_array( $fieldName, $excludeFields ) ){
					if (empty($field['schema'])) {
						error("A schema is required for field $fieldName in $schemaType $name");
					}
					if (empty($field['schema']['type'])) {
						error("A datatype is required in the schema for field $fieldName in $schemaType $name");
					}
					if( !aRenderer::validateReservedSql( $fieldName ) ){
						error( "$fieldName is a reserved sql term please change the schema in $schemaType $name" );
					}	
				}
			}
		}

		// typemap - for type only (not services)  
		if( !empty( $schema['typemaps'] ) ){
			foreach ($schema['typemaps'] as $typemapName => $typemap) {
				foreach ($typemap['fields'] as $fieldName => $field) {
					if (empty($field['schema'])) {
						error("A schema is required for typemap $typemapName field $fieldName in type $name");
					}
					if (empty($field['schema']['type'])) {
						error("A type is required in the schema for typemap $typemapName field $fieldName in type $name");
					}
					if( !aRenderer::validateReservedSql( $fieldName ) ){
						error( "$fieldName is a reserved sql term please change the schema in typemap $typemapName" );
					}	
				}
			}
		}
	}

	/**
	 * validateReservedSql
	 */
	public static function validateReservedSql( $pParam ){
		$words = array( 'column' );
		return ( !in_array( $pParam, $words ) );
	}

	/**
	 * renderFile
	 */
	public static function renderFile($dir, $file, $template, $config, $prefix) {
		global $gBitSmarty;

		$filename = $dir."/".$file;
		message(" ".$filename);

		if (file_exists($filename)) {
			if (is_file($filename)) {
				if (is_readable($filename)) {
					if ($contents = file_get_contents($filename)) {
						$start_count = preg_match_all(
							'@([^a-zA-Z0-9\s]{1,2}) =-=- CUSTOM (BEGIN|END): ([^\s]*?) -=-= ([^a-zA-Z0-9\s]{1,2})@ms', $contents, $matches, PREG_OFFSET_CAPTURE | PREG_SET_ORDER);

						if ($start_count > 0) {
							for ($i = 0; $i < count($matches); $i += 2) {
								// TODO: Sanity balance check.
								$start_point = $matches[$i][4][1] + 1;
								$end_point = $matches[$i+1][0][1];
								$substring = substr($contents, $start_point, $end_point - $start_point);
								$start_point = strpos($substring, "\n");
								$end_point = strrpos($substring, "\n");
								$length = $end_point - $start_point;
								$customBlock[$matches[$i][3][0]] =
									substr($substring, $start_point + 1, $length -1);

							}
							$count = count($customBlock);
							if ($start_count != $count * 2) {
								error("Start count does not match preserved count.");
							} else {
								$gBitSmarty->assign('customBlock', $customBlock);
							}
						}
					} else {
						error("Unable to read old file: $filename");
					}
				}
			} else {
				error("$filename exists but is not a file!");
			}
		} else {
			echo "$filename is new.\n";
		}

		// Get the contents of the file from smarty
		$content = $gBitSmarty->fetch($prefix . $template);
		if (!empty($content)) {
			if (!$handle = fopen($filename, 'w+')) {
				error("Cannot open file ($filename)");
			}

			// Write $content to our opened file.
			if (fwrite($handle, $content) === FALSE) {
				error("Cannot write to file ($filename)");
			}

			fclose($handle);

			if (preg_match("/.php$/", $filename)) {
				aRenderer::lintFile($filename);
			}
		} else {
			error("Error generating file: $filename");
		}
	}

	/**
	 * listFile
	 */
	public static function lintFile($filename) {
		message(" ... verifying ...");

		exec("php -l $filename", $output, $ret);
		if ($ret != 0) {
			error("ERROR: The generated file: $filename is invalid.", FALSE);
			error($output);
		}
	}

	protected function locateTemplatesRecurse($dir) {
		global $gTemplatePaths;
		if ($dh = opendir(PKGMKR_PKG_PATH . "/templates/" . $dir)) {
			while (($file = readdir($dh)) !== false) {
				if ($file != "." && $file != "..") {
					if (is_dir(PKGMKR_PKG_PATH . "/templates/".$dir."/".$file)) {
						$this->locateTemplatesRecurse($dir . "/" . $file);
					} else {
						if (!empty($gTemplatePaths[$file])) {
							error("Doh! You have added a new template with the same name as another in the ".$gTemplatePaths[$file]." directory! This is NOT supported. All template names must be unique package maker wide.", true);
						}
						$gTemplatePaths[$file] = $dir;
					}
				}
			}
			closedir($dh);
		}
	}

	protected function locateTemplates() {
		global $gTemplatePaths;
		$gTemplatePaths = array();
		$this->locateTemplatesRecurse("");
	}

	public static function getTemplatePrefix($template, $params) {
		$prefix = '';
		if (!empty($params) && !empty($params['templates']) &&
			!empty($params['templates'][$template])) {
			$prefix = $params['templates'][$template] . "_";
		}
		return $prefix;
	}


}

function find_pkgmkr_template($resource_type, $resource_name, &$template_source, &$template_timestamp, &$smarty_obj) {
	global $gTemplatePaths;

	if( $resource_type == 'file' ) {
		if (!empty($gTemplatePaths[$resource_name])) {
			$file = PKGMKR_PKG_PATH ."/templates/".
				$gTemplatePaths[$resource_name] . "/" . $resource_name;
			$template_source = file_get_contents($file);
			$template_timestamp = filemtime($file);
			return true;
		}
    }
	return false;
}
