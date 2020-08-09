<#include "../../include/import_global.ftl">
<#include "../../include/html_doctype.ftl">
<#--
titleMessageKey 标题标签I18N关键字，不允许null
formAction 表单提交action，允许为null
readonly 是否只读操作，允许为null
-->
<#assign formAction=(formAction!'#')>
<#assign readonly=(readonly!false)>
<#assign isAdd=(formAction == 'saveAdd')>
<html>
<head>
<#include "../../include/html_head.ftl">
<title><#include "../../include/html_title_app_name.ftl">
	<@spring.message code='${titleMessageKey}' /> - <@spring.message code='dataSet.dataSetType.SQL' />
</title>
</head>
<body>
<div id="${pageId}" class="page-form page-form-dataSet">
	<form id="${pageId}-form" action="#" method="POST">
		<div class="form-head"></div>
		<div class="form-content">
			<#include "include/dataSet_form_html_name.ftl">
			<div class="form-item">
				<div class="form-item-label">
					<label><@spring.message code='dataSet.dataSource' /></label>
				</div>
				<div class="form-item-value">
					<input type="text" name="schemaConnectionFactory.schema.title" class="ui-widget ui-widget-content" value="${(dataSet.connectionFactory.schema.title)!''?html}" readonly="readonly" />
					<input type="hidden" name="schemaConnectionFactory.schema.id" class="ui-widget ui-widget-content" value="${(dataSet.connectionFactory.schema.id)!''?html}" />
					<#if !readonly>
					<button type="button" class="select-schema-button"><@spring.message code='select' /></button>
					</#if>
				</div>
			</div>
			<div class="form-item">
				<div class="form-item-label">
					<label><@spring.message code='dataSet.sql' /></label>
				</div>
				<div class="form-item-value form-item-value-workspace">
					<textarea name="sql" class="ui-widget ui-widget-content" style="display:none;">${(dataSet.sql)!''?html}</textarea>
					<div class="workspace-editor-wrapper ui-widget ui-widget-content">
						<div id="${pageId}-workspaceEditor" class="workspace-editor"></div>
					</div>
					<#include "include/dataSet_form_html_wow.ftl" >
				</div>
			</div>
			<div class="form-item">
				<div class="form-item-label">
					<label><@spring.message code='dataSet.propertyLabelsText.SQL' /></label>
				</div>
				<div class="form-item-value">
					<input type="text" name="propertyLabelsText" class="ui-widget ui-widget-content" value="${(dataSet.propertyLabelsText)!''?html}" placeholder="<@spring.message code='dataSet.propertyLabelsTextSplitByComma' />" />
				</div>
			</div>
		</div>
		<div class="form-foot" style="text-align:center;">
			<#if !readonly>
			<input type="submit" value="<@spring.message code='save' />" class="recommended" />
			&nbsp;&nbsp;
			<input type="reset" value="<@spring.message code='reset' />" />
			</#if>
		</div>
	</form>
	<#include "include/dataSet_form_html_preview_pvp.ftl" >
</div>
<#include "../../include/page_js_obj.ftl" >
<#include "../../include/page_obj_form.ftl">
<#include "../../include/page_obj_sqlEditor.ftl">
<#include "include/dataSet_form_js.ftl">
<script type="text/javascript">
(function(po)
{
	po.dataSetProperties = <@writeJson var=dataSetProperties />;
	po.dataSetParams = <@writeJson var=dataSetParams />;
	
	$.initButtons(po.element());
	po.initWorkspaceHeight();
	
	po.getDataSetSchemaId = function(){ return po.element("input[name='schemaConnectionFactory.schema.id']").val(); };
	
	po.isSqlModified = function(textareaValue, editorValue)
	{
		if(textareaValue == undefined)
			textareaValue = po.element("textarea[name='sql']").val();
		if(editorValue == undefined)
			editorValue = po.sqlEditor.getValue();
		
		return po.isModifiedIgnoreBlank(textareaValue, editorValue);
	};
	
	po.element(".select-schema-button").click(function()
	{
		var options =
		{
			pageParam :
			{
				select : function(schema)
				{
					po.element("input[name='schemaConnectionFactory.schema.title']").val(schema.title);
					po.element("input[name='schemaConnectionFactory.schema.id']").val(schema.id);
				}
			}
		};
		
		$.setGridPageHeightOption(options);
		
		po.open("${contextPath}/schema/select", options);
	});
	
	po.getSqlEditorSchemaId = function(){ return po.getDataSetSchemaId(); };
	po.getSqlEditorElementId = function(){ return "${pageId}-workspaceEditor"; };
	po.initSqlEditor();
	
	po.initWorkspaceEditor(po.sqlEditor, po.element("textarea[name='sql']").val());
	
	po.isWorkspaceModified = function()
	{
		return po.isSqlModified();
	};
	po.initWorkspaceTabs();
	
	po.getAddParamName = function()
	{
		var selectionRange = po.sqlEditor.getSelectionRange();
		return (po.sqlEditor.session.getTextRange(selectionRange) || "");
	};
	po.initDataSetParamsTable(po.dataSetParams);
	
	po.initPreviewParamValuePanel();
	
	po.previewOptions.url = po.url("sqlPreview");
	po.previewOptions.paging = true;
	po.previewOptions.beforePreview = function()
	{
		var schemaId = po.getDataSetSchemaId();
		var sql = po.sqlEditor.getValue();
		
		if(!schemaId || !sql)
			return false;
		
		this.data.schemaId = schemaId;
		this.data.sql = sql;
	};
	po.previewOptions.beforeMore = function()
	{
		if(!this.data.schemaId || !this.data.sql)
			return false;
	};
	po.previewOptions.beforeRefresh = function()
	{
		if(!this.data.schemaId || !this.data.sql)
			return false;
	};
	po.previewOptions.buildTablesColumns = function(previewResponse)
	{
		return $.buildDataTablesColumns(previewResponse.table);
	};
	po.previewOptions.success = function(previewResponse)
	{
		po.element("textarea[name='sql']").val(this.data.sql);
		po.dataSetProperties = (previewResponse.dataSetProperties || []);
		po.sqlEditor.focus();
	};
	
	po.initPreviewOperations();
	
	po.element(".preview-result-table-wrapper .export-button").click(function(event)
	{
		var schemaId = po.getDataSetSchemaId();
		var sql = po.sqlEditor.getValue();
		
		if(!schemaId || !sql)
			return;
		
		if(po.hasFormDataSetParam())
		{
			//避免设置参数面板被隐藏
			event.stopPropagation();
			po.showDataSetParamValuePanel(
			{
				submit: function(formData)
				{
					po.exportDataSetData(schemaId, sql, po.getFormDataSetParams(), formData);
				}
			});
		}
		else
		{
			po.exportDataSetData(schemaId, sql);
		}
	});
	
	po.exportDataSetData = function(schemaId, sql, dataSetParams, paramValues)
	{
		var data =
		{
			sql: sql,
			dataSetParams: (dataSetParams || []),
			paramValues: (paramValues || {})
		};
		
		$.postJson(po.url("resolveSql"), data, function(sql)
		{
			var options = {data: {"initSqls": sql}};
			$.setGridPageHeightOption(options);
			po.open("${contextPath}/dataexchange/"+schemaId+"/export", options);
		});
	};
	
	$.validator.addMethod("dataSetSqlRequired", function(value, element)
	{
		var sql = po.sqlEditor.getValue();
		return sql.length > 0;
	});
	
	$.validator.addMethod("dataSetSqlPreviewRequired", function(value, element)
	{
		return !po.isSqlModified(value);
	});
	
	po.form().validate(
	{
		ignore : "",
		rules :
		{
			"name" : "required",
			"schemaConnectionFactory.schema.title" : "required",
			"sql" : {"dataSetSqlRequired": true, "dataSetSqlPreviewRequired": true}
		},
		messages :
		{
			"name" : "<@spring.message code='validation.required' />",
			"schemaConnectionFactory.schema.title" : "<@spring.message code='validation.required' />",
			"sql" : {"dataSetSqlRequired": "<@spring.message code='validation.required' />", "dataSetSqlPreviewRequired": "<@spring.message code='dataSet.validation.previewSqlForCorrection' />"}
		},
		submitHandler : function(form)
		{
			var formData = $.formToJson(form);
			formData["properties"] = po.dataSetProperties;
			formData["params"] = po.getFormDataSetParams();
			
			$.postJson("${contextPath}/analysis/dataSet/${formAction}", formData,
			function(response)
			{
				po.pageParamCallAfterSave(true, response.data);
			});
		},
		errorPlacement : function(error, element)
		{
			error.appendTo(element.closest(".form-item-value"));
		}
	});
})
(${pageId});
</script>
</body>
</html>