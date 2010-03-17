{literal}{include file="bitpackage:liberty/services_inc.tpl" serviceLocation='nav' serviceHash=$gContent->mInfo}
<div class="display {/literal}{$package}{literal}">
	<div class="floaticon">
		{if $print_page ne 'y'}
			{if $gContent->hasUpdatePermission()}
				<a title="{tr}Edit this {/literal}{$package}{literal}{/tr}" href="{$smarty.const.{/literal}{$PACKAGE}{literal}_PKG_URL}edit.php?{/literal}{$package}{literal}_id={$gContent->mInfo.{/literal}{$package}{literal}_id}">{biticon ipackage="icons" iname="accessories-text-editor" iexplain="Edit {/literal}{$Package}{literal}"}</a>
			{/if}
			{if $gContent->hasExpungePermission()}
				<a title="{tr}Remove this {/literal}{$package}{literal}{/tr}" href="{$smarty.const.{/literal}{$PACKAGE}{literal}_PKG_URL}remove_{/literal}{$package}{literal}.php?{/literal}{$package}{literal}_id={$gContent->mInfo.{/literal}{$package}{literal}_id}">{biticon ipackage="icons" iname="edit-delete" iexplain="Remove {/literal}{$Package}{literal}"}</a>
			{/if}
		{/if}<!-- end print_page -->
	</div><!-- end .floaticon -->

	<div class="header">
		<h1>{$gContent->mInfo.title|escape|default:"{/literal}{$Package}{literal}"}</h1>
		<p>{$gContent->mInfo.description|escape}</p>
		<div class="date">
			{tr}Created by{/tr}: {displayname user=$gContent->mInfo.creator_user user_id=$gContent->mInfo.creator_user_id real_name=$gContent->mInfo.creator_real_name}, {tr}Last modification by{/tr}: {displayname user=$gContent->mInfo.modifier_user user_id=$gContent->mInfo.modifier_user_id real_name=$gContent->mInfo.modifier_real_name}, {$gContent->mInfo.last_modified|bit_long_datetime}
		</div>
	</div><!-- end .header -->

	<div class="body">
		<div class="content">
			{include file="bitpackage:liberty/services_inc.tpl" serviceLocation='body' serviceHash=$gContent->mInfo}
			{$gContent->mInfo.parsed_data}
		</div><!-- end .content -->
	</div><!-- end .body -->
</div><!-- end .{/literal}{$package}{literal} -->
{include file="bitpackage:liberty/services_inc.tpl" serviceLocation='view' serviceHash=$gContent->mInfo}
{/literal}