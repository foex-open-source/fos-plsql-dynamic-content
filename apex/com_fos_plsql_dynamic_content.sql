

prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_190200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2019.10.04'
,p_release=>'19.2.0.00.18'
,p_default_workspace_id=>1620873114056663
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'FOS_MASTER_WS'
);
end;
/

prompt APPLICATION 102 - FOS Dev - Plugin Master
--
-- Application Export:
--   Application:     102
--   Name:            FOS Dev - Plugin Master
--   Exported By:     FOS_MASTER_WS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 61118001090994374
--     PLUGIN: 134108205512926532
--     PLUGIN: 168413046168897010
--     PLUGIN: 13235263798301758
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 34175298479606152
--     PLUGIN: 35822631205839510
--     PLUGIN: 2674568769566617
--     PLUGIN: 14934236679644451
--     PLUGIN: 2600618193722136
--     PLUGIN: 2657630155025963
--     PLUGIN: 284978227819945411
--     PLUGIN: 56714461465893111
--   Manifest End
--   Version:         19.2.0.00.18
--   Instance ID:     250144500186934
--

begin
  -- replace components
  wwv_flow_api.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_fos_plsql_dynamic_content
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(35822631205839510)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.FOS.PLSQL_DYNAMIC_CONTENT'
,p_display_name=>'FOS - PL/SQL Dynamic Content'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/script#MIN#.js'
,p_css_file_urls=>'#PLUGIN_FILES#css/style#MIN#.css'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'--',
'--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)',
'--',
'--  This is a refreshable version of the PL/SQL Dynamic Content Region.',
'--',
'--  License: MIT',
'--',
'--  GitHub: https://github.com/foex-open-source/fos-plsql-dynamic-content',
'--',
'-- =============================================================================',
'',
'function render',
'  ( p_region              apex_plugin.t_region',
'  , p_plugin              apex_plugin.t_plugin',
'  , p_is_printer_friendly boolean',
'  )',
'return apex_plugin.t_region_render_result',
'as',
'    l_return apex_plugin.t_region_render_result;',
'    ',
'    -- required settings',
'    l_region_id             varchar2(4000)             := p_region.static_id;',
'    l_wrapper_id            varchar2(4000)             := p_region.static_id || ''_FOS_WRAPPER'';',
'    l_ajax_identifier       varchar2(4000)             := apex_plugin.get_ajax_identifier;',
'    l_plsql_code            p_region.attribute_01%type := p_region.attribute_01;',
'    l_substitute_values     boolean                    := instr(p_region.attribute_15, ''substitute-values'') > 0;',
'    l_lazy_load             boolean                    := nvl(p_region.attribute_11, ''N'') = ''Y'';',
'    l_lazy_refresh          boolean                    := nvl(p_region.attribute_12, ''N'') = ''Y'';   ',
'',
'    -- Javascript Initialization Code',
'    l_init_js_fn            varchar2(32767)            := nvl(apex_plugin_util.replace_substitutions(p_region.init_javascript_code), ''undefined'');',
'    ',
'    -- page items to submit settings',
'    l_items_to_submit       varchar2(4000)             := apex_plugin_util.page_item_names_to_jquery(p_region.attribute_02);',
'    l_suppress_change_event boolean                    := p_region.attribute_03 is not null and p_region.attribute_04 = ''Y'';',
'    ',
'    -- spinner settings',
'    l_show_spinner          boolean                    := p_region.attribute_05 != ''N'';',
'    l_show_spinner_overlay  boolean                    := p_region.attribute_05 like ''%_OVERLAY'';',
'    l_spinner_position      varchar2(4000)             :=',
'        case ',
'            when p_region.attribute_05 like ''ON_PAGE%''   then ''body'' ',
'            when p_region.attribute_05 like ''ON_REGION%'' then ''#'' || l_region_id',
'            else null',
'        end;',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug',
'    then',
'        apex_plugin_util.debug_region',
'          ( p_plugin => p_plugin',
'          , p_region => p_region',
'          );',
'    end if;',
'    ',
'    -- a wrapper is needed to properly identify and replace the content in case of a refresh',
'    sys.htp.p(''<div id="'' || apex_escape.html_attribute(l_wrapper_id) || ''">'');',
'       ',
'    -- we let the devloper choose whether we substitute values automatically for them or not ',
'    if l_substitute_values ',
'    then',
'        l_plsql_code := apex_plugin_util.replace_substitutions(l_plsql_code);',
'    end if;',
'    ',
'    -- only when lazy-loading is turned off we immediately execute the plsql code.',
'    -- with lazy-loading the page will be rendered first, then an ajax call executes the code',
'    if not l_lazy_load ',
'    then',
'        apex_exec.execute_plsql(l_plsql_code);',
'    end if;',
'    ',
'    -- closing the wrapper',
'    sys.htp.p(''</div>'');',
'    ',
'    -- creating a json object with the region settings to pass to the client',
'    apex_json.initialize_clob_output;',
'',
'    apex_json.open_object;',
'    apex_json.write(''ajaxIdentifier''     , l_ajax_identifier      );',
'    apex_json.write(''regionId''           , l_region_id            );',
'    apex_json.write(''regionWrapperId''    , l_wrapper_id           );',
'    apex_json.write(''itemsToSubmit''      , l_items_to_submit      );',
'    apex_json.write(''suppressChangeEvent'', l_suppress_change_event);',
'    apex_json.write(''showSpinner''        , l_show_spinner         );',
'    apex_json.write(''showSpinnerOverlay'' , l_show_spinner_overlay );',
'    apex_json.write(''spinnerPosition''    , l_spinner_position     );',
'    apex_json.write(''lazyLoad''           , l_lazy_load            );',
'    apex_json.write(''lazyRefresh''        , l_lazy_refresh         );',
'    apex_json.close_object;',
'    ',
'    -- initialization code for the region widget. needed to handle the refresh event',
'    apex_javascript.add_onload_code(''FOS.region.plsqlDynamicContent('' || apex_json.get_clob_output|| '', ''|| l_init_js_fn || '');'');',
'    ',
'    apex_json.free_output;',
'',
'    return l_return;',
'end render;',
'',
'',
'function ajax',
'  ( p_region apex_plugin.t_region',
'  , p_plugin apex_plugin.t_plugin',
'  )',
'return apex_plugin.t_region_ajax_result',
'as',
'    -- plug-in attributes',
'    l_plsql_code              p_region.attribute_01%type := p_region.attribute_01;',
'    l_items_to_return         p_region.attribute_03%type := p_region.attribute_03;',
'    l_substitute_values       boolean                    := instr(p_region.attribute_15, ''substitute-values'') > 0;',
'    ',
'    -- local variables',
'    l_item_names              apex_t_varchar2;',
'    ',
'    -- needed for accessing the htp buffer',
'    l_htp_buffer              sys.htp.htbuf_arr;',
'    l_rows_x                  number                     := 9999999;',
'    l_rows                    number                     := 9999999;',
'    ',
'    -- resulting content',
'    l_content                 clob                       := '''';',
'    l_buffer                  varchar2(32000);',
'',
'    l_return                  apex_plugin.t_region_ajax_result;',
'    ',
'    -- fast append of a clob',
'    -- see benchmarks here: https://gist.github.com/vlsi/052424856512f80137989c817cb8f046',
'    procedure clob_append',
'      ( p_clob    in out nocopy clob',
'      , p_buffer  in out nocopy varchar2',
'      , p_append  in            varchar2',
'      ) ',
'    is',
'    begin',
'        p_buffer := p_buffer || p_append;',
'        ',
'    exception when value_error then',
'        if p_clob is null ',
'        then',
'            p_clob := p_buffer;',
'        else',
'            sys.dbms_lob.writeappend(p_clob, length(p_buffer), p_buffer);',
'        end if;',
'',
'        p_buffer := p_append;',
'    end clob_append; ',
'    --',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug',
'    then',
'        apex_plugin_util.debug_region',
'          ( p_plugin => p_plugin',
'          , p_region => p_region',
'          );',
'    end if;',
'    ',
'    -- helps remove the unnecesarry "X-ORACLE-IGNORE: IGNORE" which appear when using htp.get_page',
'    sys.htp.p;',
'    sys.htp.get_page(l_htp_buffer, l_rows_x);',
'    ',
'    -- we let the devloper choose whether we substitute values automatically for them or not ',
'    if l_substitute_values ',
'    then',
'        l_plsql_code := apex_plugin_util.replace_substitutions(l_plsql_code);',
'    end if;',
'    ',
'    -- executing the pl/sql code',
'    apex_exec.execute_plsql(l_plsql_code);',
'',
'    -- getting the htp buffer, where l_plsql_code might have written into. ',
'    -- has the side effect of removing it',
'    sys.htp.get_page(l_htp_buffer, l_rows);',
'',
'    -- rewriting htp buffer into a clob and pass back in json object',
'    for l_idx in 1 .. l_rows ',
'    loop',
'        --l_content := l_content || l_htp_buffer(l_idx); -- slower',
'        clob_append(l_content, l_buffer, l_htp_buffer(l_idx));',
'    end loop;',
'    l_content := l_content || l_buffer;',
'',
'    apex_json.open_object;',
'    apex_json.write(''status'' , ''success'');',
'    apex_json.write(''content'', l_content);',
'',
'    -- adding info about the page items to return',
'    if l_items_to_return is not null ',
'    then',
'    ',
'        l_item_names := apex_string.split(l_items_to_return,'','');',
'        ',
'        apex_json.open_array(''items'');',
'        ',
'        for l_idx in 1 .. l_item_names.count ',
'        loop',
'            apex_json.open_object;',
'            apex_json.write',
'              ( p_name  => ''id''',
'              , p_value => l_item_names(l_idx)',
'              );',
'            apex_json.write',
'              ( p_name  => ''value''',
'              , p_value => apex_util.get_session_state(l_item_names(l_idx))',
'              );',
'            apex_json.close_object;',
'        end loop;',
'',
'        apex_json.close_array;',
'    end if;',
'',
'    apex_json.close_object;',
'',
'    return l_return;',
'end ajax;'))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>false
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>',
'    The <strong>FOS - PL/SQL Dynamic Content</strong> plug-in is a refreshable region where you can output any HTML code using ''sys.htp.p'' calls. It supports Lazy Loading, Lazy Refresh, can show loading spinner and mask, and gives you before/after re'
||'fresh events to hook into.',
'</p>',
'<p>',
'    Using this plug-in you have complete control of the HTML output. ',
'</p>'))
,p_version_identifier=>'20.1.1'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// Settings for the FOS browser extension',
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>117
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(35849123427383459)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'PL/SQL Code'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Enter the PL/SQL code to generate the HTML output.</p>',
'<p>You can reference other page or application items from within your application using bind syntax (for example <code>:P1_MY_ITEM</code>). Any items referenced also need to be included in <strong>Page Items to Submit</strong>.</p>',
'<p>See the HTP package for details.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(35825076659937647)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'<p>The page items submitted to the server during a refresh, and therefore, available for use within your PL/SQL Code.</p><p>You can type in the item name or pick from the list of available items. If you pick from the list and there is already text en'
||'tered then a comma is placed at the end of the existing text, followed by the item name returned from the list.<br></p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(35922786323890332)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Items to Return'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'<p>The page items you wish to return to the client after the refresh process, with their current session state.</p><p>Enter the uppercase page items set you wish to return to the client after the refresh process, based on their current value in sessi'
||'on state. If your <strong>PL/SQL Code</strong> sets one or more page item values in session state you need to define those items in this attribute.</p><p>You can type in the item name or pick from the list of available items. If you pick from the lis'
||'t and there is already text entered then a comma is placed at the end of the existing text, followed by the item name returned from the list.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(35923475981894784)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Suppress Change Event'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(35922786323890332)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_NULL'
,p_help_text=>'<p>Specify whether the change event is suppressed on the items specified in <b>Page Items to Return</b>. This prevents subsequent Change based Dynamic Actions from firing, for these items.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(35929269874331346)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Show Spinner'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'N'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Show a spinner while the refresh request is taking place.</p>',
'<p>Note that the spinner will not be shown if the request returns very quickly, in order to avoid flickering.</p>'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(35929852365332558)
,p_plugin_attribute_id=>wwv_flow_api.id(35929269874331346)
,p_display_sequence=>10
,p_display_value=>'No'
,p_return_value=>'N'
,p_help_text=>'<p>Do not show a spinner.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(35930317821333368)
,p_plugin_attribute_id=>wwv_flow_api.id(35929269874331346)
,p_display_sequence=>20
,p_display_value=>'On Region'
,p_return_value=>'ON_REGION'
,p_help_text=>'<p>Show the spinner on the region.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(35939340066383910)
,p_plugin_attribute_id=>wwv_flow_api.id(35929269874331346)
,p_display_sequence=>30
,p_display_value=>'On Region with Overlay'
,p_return_value=>'ON_REGION_WITH_OVERLAY'
,p_help_text=>'<p>Adds a translucent overlay on the region which prohibits mouse inputs, and shows a spinner on top of that overlay.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(35930640668334085)
,p_plugin_attribute_id=>wwv_flow_api.id(35929269874331346)
,p_display_sequence=>40
,p_display_value=>'On Page'
,p_return_value=>'ON_PAGE'
,p_help_text=>'<p>Show a spinner centered on the whole page.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(35939814845385146)
,p_plugin_attribute_id=>wwv_flow_api.id(35929269874331346)
,p_display_sequence=>50
,p_display_value=>'On Page with Overlay'
,p_return_value=>'ON_PAGE_WITH_OVERLAY'
,p_help_text=>'<p>Adds a translucent overlay on the whole page which prohibits mouse inputs, and shows a spinner on top of that overlay.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(31245256062489780)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>110
,p_prompt=>'Lazy Load'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_help_text=>'<p>Only load the region when it is visible to the user i.e. shown/expanded etc.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(30910737715133703)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>120
,p_prompt=>'Lazy Refresh'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(31245256062489780)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>'<p>Enable this option to lazily refresh the region i.e. only when it is visible.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(28600337742732195)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>150
,p_prompt=>'Extra Options'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'substitute-values'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Extra plug-in options.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(28601110055742073)
,p_plugin_attribute_id=>wwv_flow_api.id(28600337742732195)
,p_display_sequence=>10
,p_display_value=>'Substitute Values'
,p_return_value=>'substitute-values'
,p_help_text=>'<p>Uncheck this option to skip the substitution of page item values in the PLSQL Code</p>'
);
wwv_flow_api.create_plugin_std_attribute(
 p_id=>wwv_flow_api.id(31426700536826749)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_name=>'INIT_JAVASCRIPT_CODE'
,p_is_required=>false
,p_depending_on_has_to_exist=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Using this setting you can centralize any changes using a Javascript function e.g.</p>',
'<pre>',
'function(options) {',
'   // when lazy loading we can customize how long after the "apexreadyend" we wait before checking if the region is visible',
'   options.visibilityCheckDelay = 2000; // milliseconds',
'}',
'</pre>'))
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C7320617065782C24202A2F0A0A76617220464F53203D2077696E646F772E464F53207C7C207B7D3B0A464F532E726567696F6E203D20464F532E726567696F6E207C7C207B7D3B0A0A2F2A2A0A202A20496E697469616C697A6174';
wwv_flow_api.g_varchar2_table(2) := '696F6E2066756E6374696F6E20666F72207468652064796E616D696320636F6E74656E7420726567696F6E2E0A202A20546869732066756E6374696F6E206D7573742062652072756E20666F722074686520726567696F6E20746F207375627363726962';
wwv_flow_api.g_varchar2_table(3) := '6520746F207468652072656672657368206576656E740A202A20496E70757420706172616D6574657220697320616E206F626A65637420776974682074686520666F6C6C6F77696E6720617474726962757465733A0A202A0A202A2040706172616D207B';
wwv_flow_api.g_varchar2_table(4) := '6F626A6563747D2020636F6E66696720202020202020202020202020202020202020202020202020436F6E66696775726174696F6E206F626A65637420686F6C64696E6720616C6C20617474726962757465730A202A2040706172616D207B737472696E';
wwv_flow_api.g_varchar2_table(5) := '677D2020636F6E6669672E616A61784964656E74696669657220202020202020202020416A6178204964656E746966696572206E656564656420627920617065782E7365727665722E706C7567696E0A202A2040706172616D207B737472696E677D2020';
wwv_flow_api.g_varchar2_table(6) := '636F6E6669672E726567696F6E496420202020202020202020202020202020546865206D61696E20726567696F6E2069642E2054686520726567696F6E206F6E207768696368202272656672657368222063616E206265207472696767657265640A202A';
wwv_flow_api.g_varchar2_table(7) := '2040706172616D207B737472696E677D2020636F6E6669672E726567696F6E5772617070657249642020202020202020204964206F66207772617070657220726567696F6E2E2054686520636F6E74656E7473206F66207468697320656C656D656E7420';
wwv_flow_api.g_varchar2_table(8) := '77696C6C206265207265706C61636564207769746820746865206E657720636F6E74656E740A202A2040706172616D207B737472696E677D20205B636F6E6669672E6974656D73546F5375626D69745D202020202020202020436F6D6D612D7365706172';
wwv_flow_api.g_varchar2_table(9) := '617465642070616765206974656D206E616D657320696E206A51756572792073656C6563746F7220666F726D61740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73757070726573734368616E67654576656E745D2020204966';
wwv_flow_api.g_varchar2_table(10) := '207468657265206172652070616765206974656D7320746F2062652072657475726E65642C20746869732064656369646573207768657468657220746F20747269676765722061206368616E6765206576656E74206F72206E6F740A202A204070617261';
wwv_flow_api.g_varchar2_table(11) := '6D207B626F6F6C65616E7D205B636F6E6669672E73686F775370696E6E65725D202020202020202020202053686F77732061207370696E6E6572206F72206E6F740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73686F775370';
wwv_flow_api.g_varchar2_table(12) := '696E6E65724F7665726C61795D20202020446570656E6473206F6E2073686F775370696E6E65722E20416464732061207472616E736C7563656E74206F7665726C617920626568696E6420746865207370696E6E65720A202A2040706172616D207B7374';
wwv_flow_api.g_varchar2_table(13) := '72696E677D20205B636F6E6669672E7370696E6E6572506F736974696F6E5D20202020202020446570656E6473206F6E2073686F775370696E6E65722E2041206A51756572792073656C6563746F7220756E746F20776869636820746865207370696E6E';
wwv_flow_api.g_varchar2_table(14) := '65722077696C6C2062652073686F776E0A202A2F0A464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E74203D2066756E6374696F6E2028636F6E6669672C20696E6974466E29207B0A0A2020202076617220706C7567696E4E616D';
wwv_flow_api.g_varchar2_table(15) := '65203D2027464F53202D20504C2F53514C2044796E616D696320436F6E74656E74273B0A20202020617065782E64656275672E696E666F28706C7567696E4E616D652C20636F6E6669672C20696E6974466E293B0A0A202020202F2F20416C6C6F772074';
wwv_flow_api.g_varchar2_table(16) := '686520646576656C6F70657220746F20706572666F726D20616E79206C617374202863656E7472616C697A656429206368616E676573207573696E67204A61766173637269707420496E697469616C697A6174696F6E20436F64650A2020202069662028';
wwv_flow_api.g_varchar2_table(17) := '696E6974466E20696E7374616E63656F662046756E6374696F6E29207B0A2020202020202020696E6974466E2E63616C6C28636F6E746578742C20636F6E666967293B0A202020207D0A0A2020202076617220636F6E74657874203D20746869732C2065';
wwv_flow_api.g_varchar2_table(18) := '6C243B0A0A20202020656C24203D20636F6E6669672E656C24203D202428272327202B20636F6E6669672E726567696F6E4964293B0A0A202020202F2F696D706C656D656E74696E672074686520617065782E726567696F6E20696E7465726661636520';
wwv_flow_api.g_varchar2_table(19) := '696E206F7264657220746F20726573706F6E6420746F2072656672657368206576656E74730A20202020617065782E726567696F6E2E63726561746528636F6E6669672E726567696F6E49642C207B0A2020202020202020747970653A2027666F732D72';
wwv_flow_api.g_varchar2_table(20) := '6567696F6E2D706C73716C2D64796E616D69632D636F6E74656E74272C0A2020202020202020726566726573683A2066756E6374696F6E202829207B0A20202020202020202020202069662028636F6E6669672E697356697369626C65207C7C2021636F';
wwv_flow_api.g_varchar2_table(21) := '6E6669672E6C617A795265667265736829207B0A20202020202020202020202020202020464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E742E726566726573682E63616C6C28636F6E746578742C20636F6E666967293B0A2020';
wwv_flow_api.g_varchar2_table(22) := '202020202020202020207D20656C7365207B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D20747275653B0A2020202020202020202020207D0A20202020202020207D2C0A20202020202020206F707469';
wwv_flow_api.g_varchar2_table(23) := '6F6E3A2066756E6374696F6E20286E616D652C2076616C756529207B0A2020202020202020202020207661722077686974654C6973744F7074696F6E73203D205B276C6F61646564272C276E6565647352656672657368272C2773686F775370696E6E65';
wwv_flow_api.g_varchar2_table(24) := '724F7665726C6179272C277370696E6E6572506F736974696F6E272C277669736962696C697479436865636B44656C6179275D3B0A20202020202020202020202076617220617267436F756E74203D20617267756D656E74732E6C656E6774683B0A2020';
wwv_flow_api.g_varchar2_table(25) := '2020202020202020202069662028617267436F756E74203D3D3D203129207B0A2020202020202020202020202020202072657475726E20636F6E6669675B6E616D655D3B0A2020202020202020202020207D20656C73652069662028617267436F756E74';
wwv_flow_api.g_varchar2_table(26) := '203E203129207B0A20202020202020202020202020202020696620286E616D652026262076616C75652026262077686974654C6973744F7074696F6E732E696E636C75646573286E616D652929207B0A2020202020202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(27) := '636F6E6669675B6E616D655D203D2076616C75653B0A202020202020202020202020202020207D20656C736520696620286E616D65202626202177686974654C6973744F7074696F6E732E696E636C75646573286E616D652929207B0A20202020202020';
wwv_flow_api.g_varchar2_table(28) := '20202020202020202020202020617065782E64656275672E7761726E2827796F752061726520747279696E6720746F2073657420616E206F7074696F6E2074686174206973206E6F7420616C6C6F7765643A2027202B206E616D65293B0A202020202020';
wwv_flow_api.g_varchar2_table(29) := '202020202020202020207D0A2020202020202020202020207D0A20202020202020207D0A202020207D293B0A0A202020202F2F20636865636B206966207765206E65656420746F206C617A79206C6F61642074686520726567696F6E0A20202020696620';
wwv_flow_api.g_varchar2_table(30) := '28636F6E6669672E6C617A794C6F616429207B0A2020202020202020617065782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528656C245B305D2C2066756E6374696F6E2028697356697369626C6529207B0A2020202020';
wwv_flow_api.g_varchar2_table(31) := '20202020202020636F6E6669672E697356697369626C65203D20697356697369626C653B0A20202020202020202020202069662028697356697369626C65202626202821636F6E6669672E6C6F61646564207C7C20636F6E6669672E6E65656473526566';
wwv_flow_api.g_varchar2_table(32) := '726573682929207B0A20202020202020202020202020202020617065782E726567696F6E28636F6E6669672E726567696F6E4964292E7265667265736828293B0A20202020202020202020202020202020636F6E6669672E6C6F61646564203D20747275';
wwv_flow_api.g_varchar2_table(33) := '653B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D2066616C73653B0A2020202020202020202020207D0A20202020202020207D293B0A2020202020202020617065782E6A51756572792877696E646F77';
wwv_flow_api.g_varchar2_table(34) := '292E6F6E2827617065787265616479656E64272C2066756E6374696F6E202829207B0A2020202020202020202020202F2F2077652061646420617661726961626C65207265666572656E636520746F2061766F6964206C6F7373206F662073636F70650A';
wwv_flow_api.g_varchar2_table(35) := '20202020202020202020202076617220656C203D20656C245B305D3B0A2020202020202020202020202F2F207765206861766520746F20616464206120736C696768742064656C617920746F206D616B6520737572652061706578207769646765747320';
wwv_flow_api.g_varchar2_table(36) := '6861766520696E697469616C697A65642073696E6365202873757270726973696E676C79292022617065787265616479656E6422206973206E6F7420656E6F7567680A20202020202020202020202073657454696D656F75742866756E6374696F6E2028';
wwv_flow_api.g_varchar2_table(37) := '29207B0A20202020202020202020202020202020617065782E7769646765742E7574696C2E7669736962696C6974794368616E676528656C2C2074727565293B0A2020202020202020202020207D2C20636F6E6669672E7669736962696C697479436865';
wwv_flow_api.g_varchar2_table(38) := '636B44656C6179207C7C2031303030293B0A20202020202020207D293B0A202020207D0A7D3B0A0A464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E742E72656672657368203D2066756E6374696F6E2028636F6E66696729207B';
wwv_flow_api.g_varchar2_table(39) := '0A20202020766172206C6F6164696E67496E64696361746F72466E3B0A202020202F2F636F6E66696775726573207468652073686F77696E6720616E6420686964696E67206F66206120706F737369626C65207370696E6E65720A202020206966202863';
wwv_flow_api.g_varchar2_table(40) := '6F6E6669672E73686F775370696E6E657229207B0A20202020202020206C6F6164696E67496E64696361746F72466E203D202866756E6374696F6E2028706F736974696F6E2C2073686F774F7665726C617929207B0A2020202020202020202020207661';
wwv_flow_api.g_varchar2_table(41) := '722066697865644F6E426F6479203D20706F736974696F6E203D3D2027626F6479273B0A20202020202020202020202072657475726E2066756E6374696F6E2028704C6F6164696E67496E64696361746F7229207B0A2020202020202020202020202020';
wwv_flow_api.g_varchar2_table(42) := '2020766172206F7665726C6179243B0A20202020202020202020202020202020766172207370696E6E657224203D20617065782E7574696C2E73686F775370696E6E657228706F736974696F6E2C207B2066697865643A2066697865644F6E426F647920';

wwv_flow_api.g_varchar2_table(43) := '7D293B0A202020202020202020202020202020206966202873686F774F7665726C617929207B0A20202020202020202020202020202020202020206F7665726C617924203D202428273C64697620636C6173733D22666F732D726567696F6E2D6F766572';
wwv_flow_api.g_varchar2_table(44) := '6C617927202B202866697865644F6E426F6479203F20272D666978656427203A20272729202B2027223E3C2F6469763E27292E70726570656E64546F28706F736974696F6E293B0A202020202020202020202020202020207D0A20202020202020202020';
wwv_flow_api.g_varchar2_table(45) := '20202020202066756E6374696F6E2072656D6F76655370696E6E65722829207B0A2020202020202020202020202020202020202020696620286F7665726C61792429207B0A2020202020202020202020202020202020202020202020206F7665726C6179';
wwv_flow_api.g_varchar2_table(46) := '242E72656D6F766528293B0A20202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207370696E6E6572242E72656D6F766528293B0A202020202020202020202020202020207D0A202020202020202020';
wwv_flow_api.g_varchar2_table(47) := '202020202020202F2F746869732066756E6374696F6E206D7573742072657475726E20612066756E6374696F6E2077686963682068616E646C6573207468652072656D6F76696E67206F6620746865207370696E6E65720A202020202020202020202020';
wwv_flow_api.g_varchar2_table(48) := '2020202072657475726E2072656D6F76655370696E6E65723B0A2020202020202020202020207D3B0A20202020202020207D2928636F6E6669672E7370696E6E6572506F736974696F6E2C20636F6E6669672E73686F775370696E6E65724F7665726C61';
wwv_flow_api.g_varchar2_table(49) := '79293B0A202020207D0A0A202020202F2F2074726967676572206F7572206265666F72652072656672657368206576656E7420616C6C6F77696E6720666F72206120646576656C6F70657220746F20736B69702074686520726566726573682062792072';
wwv_flow_api.g_varchar2_table(50) := '657475726E696E672066616C73650A20202020766172206576656E7443616E63656C6C6564203D20617065782E6576656E742E747269676765722827617065786265666F726572656672657368272C20272327202B20636F6E6669672E726567696F6E49';
wwv_flow_api.g_varchar2_table(51) := '642C20636F6E666967293B0A20202020696620286576656E7443616E63656C6C656429207B0A2020202020202020617065782E64656275672E7761726E2827746865207265667265736820616374696F6E20686173206265656E2063616E63656C6C6564';
wwv_flow_api.g_varchar2_table(52) := '206279207468652022617065786265666F72657265667265736822206576656E742127293B0A202020202020202072657475726E2066616C73653B0A202020207D0A20202020617065782E7365727665722E706C7567696E28636F6E6669672E616A6178';
wwv_flow_api.g_varchar2_table(53) := '4964656E7469666965722C207B0A2020202020202020706167654974656D733A20636F6E6669672E6974656D73546F5375626D69740A202020207D2C207B0A20202020202020202F2F6E656564656420746F2074726967676572206265666F726520616E';
wwv_flow_api.g_varchar2_table(54) := '642061667465722072656672657368206576656E7473206F6E2074686520726567696F6E0A2020202020202020726566726573684F626A6563743A20272327202B20636F6E6669672E726567696F6E49642C0A20202020202020202F2F74686973206675';
wwv_flow_api.g_varchar2_table(55) := '6E6374696F6E206973207265706F6E7369626C6520666F722073686F77696E672061207370696E6E65720A20202020202020206C6F6164696E67496E64696361746F723A206C6F6164696E67496E64696361746F72466E2C0A2020202020202020737563';
wwv_flow_api.g_varchar2_table(56) := '636573733A2066756E6374696F6E20286461746129207B0A2020202020202020202020202F2F73657474696E672070616765206974656D2076616C7565730A20202020202020202020202069662028646174612E6974656D7329207B0A20202020202020';
wwv_flow_api.g_varchar2_table(57) := '202020202020202020666F7220287661722069203D20303B2069203C20646174612E6974656D732E6C656E6774683B20692B2B29207B0A2020202020202020202020202020202020202020617065782E6974656D28646174612E6974656D735B695D2E69';
wwv_flow_api.g_varchar2_table(58) := '64292E73657456616C756528646174612E6974656D735B695D2E76616C75652C206E756C6C2C20636F6E6669672E73757070726573734368616E67654576656E74293B0A202020202020202020202020202020207D0A2020202020202020202020207D0A';
wwv_flow_api.g_varchar2_table(59) := '2020202020202020202020202F2F7265706C6163696E6720746865206F6C6420636F6E74656E74207769746820746865206E65770A2020202020202020202020202428272327202B20636F6E6669672E726567696F6E577261707065724964292E68746D';
wwv_flow_api.g_varchar2_table(60) := '6C28646174612E636F6E74656E74293B0A2020202020202020202020202F2F2074726967676572206F75722061667465722072656672657368206576656E742873290A202020202020202020202020617065782E6576656E742E74726967676572282761';
wwv_flow_api.g_varchar2_table(61) := '706578616674657272656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A20202020202020207D2C0A20202020202020202F2F6F6D697474696E6720616E206572726F722068616E646C6572206C6574';
wwv_flow_api.g_varchar2_table(62) := '7320617065782E73657276657220757365207468652064656661756C74206F6E650A202020202020202064617461547970653A20276A736F6E270A202020207D293B0A7D3B';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35932815202944156)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'js/script.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '76617220464F533D77696E646F772E464F537C7C7B7D3B464F532E726567696F6E3D464F532E726567696F6E7C7C7B7D2C464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E743D66756E6374696F6E28652C6E297B617065782E64';
wwv_flow_api.g_varchar2_table(2) := '656275672E696E666F2822464F53202D20504C2F53514C2044796E616D696320436F6E74656E74222C652C6E292C6E20696E7374616E63656F662046756E6374696F6E26266E2E63616C6C28722C65293B76617220692C723D746869733B693D652E656C';
wwv_flow_api.g_varchar2_table(3) := '243D24282223222B652E726567696F6E4964292C617065782E726567696F6E2E63726561746528652E726567696F6E49642C7B747970653A22666F732D726567696F6E2D706C73716C2D64796E616D69632D636F6E74656E74222C726566726573683A66';
wwv_flow_api.g_varchar2_table(4) := '756E6374696F6E28297B652E697356697369626C657C7C21652E6C617A79526566726573683F464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E742E726566726573682E63616C6C28722C65293A652E6E65656473526566726573';
wwv_flow_api.g_varchar2_table(5) := '683D21307D2C6F7074696F6E3A66756E6374696F6E286E2C69297B76617220723D5B226C6F61646564222C226E6565647352656672657368222C2273686F775370696E6E65724F7665726C6179222C227370696E6E6572506F736974696F6E222C227669';
wwv_flow_api.g_varchar2_table(6) := '736962696C697479436865636B44656C6179225D2C743D617267756D656E74732E6C656E6774683B696628313D3D3D742972657475726E20655B6E5D3B743E312626286E2626692626722E696E636C75646573286E293F655B6E5D3D693A6E262621722E';
wwv_flow_api.g_varchar2_table(7) := '696E636C75646573286E292626617065782E64656275672E7761726E2822796F752061726520747279696E6720746F2073657420616E206F7074696F6E2074686174206973206E6F7420616C6C6F7765643A20222B6E29297D7D292C652E6C617A794C6F';
wwv_flow_api.g_varchar2_table(8) := '6164262628617065782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528695B305D2C2866756E6374696F6E286E297B652E697356697369626C653D6E2C216E7C7C652E6C6F61646564262621652E6E656564735265667265';
wwv_flow_api.g_varchar2_table(9) := '73687C7C28617065782E726567696F6E28652E726567696F6E4964292E7265667265736828292C652E6C6F616465643D21302C652E6E65656473526566726573683D2131297D29292C617065782E6A51756572792877696E646F77292E6F6E2822617065';
wwv_flow_api.g_varchar2_table(10) := '787265616479656E64222C2866756E6374696F6E28297B766172206E3D695B305D3B73657454696D656F7574282866756E6374696F6E28297B617065782E7769646765742E7574696C2E7669736962696C6974794368616E6765286E2C2130297D292C65';
wwv_flow_api.g_varchar2_table(11) := '2E7669736962696C697479436865636B44656C61797C7C316533297D2929297D2C464F532E726567696F6E2E706C73716C44796E616D6963436F6E74656E742E726566726573683D66756E6374696F6E2865297B766172206E2C692C722C743B69662865';
wwv_flow_api.g_varchar2_table(12) := '2E73686F775370696E6E6572262628693D652E7370696E6E6572506F736974696F6E2C723D652E73686F775370696E6E65724F7665726C61792C743D22626F6479223D3D692C6E3D66756E6374696F6E2865297B766172206E2C6F3D617065782E757469';
wwv_flow_api.g_varchar2_table(13) := '6C2E73686F775370696E6E657228692C7B66697865643A747D293B72657475726E20722626286E3D2428273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C6179272B28743F222D6669786564223A2222292B27223E3C2F6469763E';
wwv_flow_api.g_varchar2_table(14) := '27292E70726570656E64546F286929292C66756E6374696F6E28297B6E26266E2E72656D6F766528292C6F2E72656D6F766528297D7D292C617065782E6576656E742E747269676765722822617065786265666F726572656672657368222C2223222B65';
wwv_flow_api.g_varchar2_table(15) := '2E726567696F6E49642C65292972657475726E20617065782E64656275672E7761726E2827746865207265667265736820616374696F6E20686173206265656E2063616E63656C6C6564206279207468652022617065786265666F726572656672657368';
wwv_flow_api.g_varchar2_table(16) := '22206576656E742127292C21313B617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C7B706167654974656D733A652E6974656D73546F5375626D69747D2C7B726566726573684F626A6563743A2223222B652E72';
wwv_flow_api.g_varchar2_table(17) := '6567696F6E49642C6C6F6164696E67496E64696361746F723A6E2C737563636573733A66756E6374696F6E286E297B6966286E2E6974656D7329666F722876617220693D303B693C6E2E6974656D732E6C656E6774683B692B2B29617065782E6974656D';
wwv_flow_api.g_varchar2_table(18) := '286E2E6974656D735B695D2E6964292E73657456616C7565286E2E6974656D735B695D2E76616C75652C6E756C6C2C652E73757070726573734368616E67654576656E74293B24282223222B652E726567696F6E577261707065724964292E68746D6C28';
wwv_flow_api.g_varchar2_table(19) := '6E2E636F6E74656E74292C617065782E6576656E742E74726967676572282261706578616674657272656672657368222C2223222B652E726567696F6E49642C65297D2C64617461547970653A226A736F6E227D297D3B0A2F2F2320736F757263654D61';
wwv_flow_api.g_varchar2_table(20) := '7070696E6755524C3D7363726970742E6A732E6D6170';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35933062634944187)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'js/script.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227363726970742E6A73225D2C226E616D6573223A5B22464F53222C2277696E646F77222C22726567696F6E222C22706C73716C44796E616D6963436F6E74656E74222C22636F6E66696722';
wwv_flow_api.g_varchar2_table(2) := '2C22696E6974466E222C2261706578222C226465627567222C22696E666F222C2246756E6374696F6E222C2263616C6C222C22636F6E74657874222C22656C24222C2274686973222C2224222C22726567696F6E4964222C22637265617465222C227479';
wwv_flow_api.g_varchar2_table(3) := '7065222C2272656672657368222C22697356697369626C65222C226C617A7952656672657368222C226E6565647352656672657368222C226F7074696F6E222C226E616D65222C2276616C7565222C2277686974654C6973744F7074696F6E73222C2261';
wwv_flow_api.g_varchar2_table(4) := '7267436F756E74222C22617267756D656E7473222C226C656E677468222C22696E636C75646573222C227761726E222C226C617A794C6F6164222C22776964676574222C227574696C222C226F6E5669736962696C6974794368616E6765222C226C6F61';
wwv_flow_api.g_varchar2_table(5) := '646564222C226A5175657279222C226F6E222C22656C222C2273657454696D656F7574222C227669736962696C6974794368616E6765222C227669736962696C697479436865636B44656C6179222C226C6F6164696E67496E64696361746F72466E222C';
wwv_flow_api.g_varchar2_table(6) := '22706F736974696F6E222C2273686F774F7665726C6179222C2266697865644F6E426F6479222C2273686F775370696E6E6572222C227370696E6E6572506F736974696F6E222C2273686F775370696E6E65724F7665726C6179222C22704C6F6164696E';
wwv_flow_api.g_varchar2_table(7) := '67496E64696361746F72222C226F7665726C617924222C227370696E6E657224222C226669786564222C2270726570656E64546F222C2272656D6F7665222C226576656E74222C2274726967676572222C22736572766572222C22706C7567696E222C22';
wwv_flow_api.g_varchar2_table(8) := '616A61784964656E746966696572222C22706167654974656D73222C226974656D73546F5375626D6974222C22726566726573684F626A656374222C226C6F6164696E67496E64696361746F72222C2273756363657373222C2264617461222C22697465';
wwv_flow_api.g_varchar2_table(9) := '6D73222C2269222C226974656D222C226964222C2273657456616C7565222C2273757070726573734368616E67654576656E74222C22726567696F6E577261707065724964222C2268746D6C222C22636F6E74656E74222C226461746154797065225D2C';
wwv_flow_api.g_varchar2_table(10) := '226D617070696E6773223A22414145412C49414149412C4941414D432C4F41414F442C4B41414F2C4741437842412C49414149452C4F414153462C49414149452C514141552C474169423342462C49414149452C4F41414F432C6F42414173422C534141';
wwv_flow_api.g_varchar2_table(11) := '55432C45414151432C4741472F43432C4B41414B432C4D41414D432C4B41444D2C2B424143574A2C45414151432C4741476843412C6141416B42492C5541436C424A2C4541414F4B2C4B41414B432C45414153502C4741477A422C4941416F42512C4541';
wwv_flow_api.g_varchar2_table(12) := '416842442C45414155452C4B414564442C4541414D522C4541414F512C4941414D452C454141452C4941414D562C4541414F572C5541476C43542C4B41414B4A2C4F41414F632C4F41414F5A2C4541414F572C534141552C4341436843452C4B41414D2C';
wwv_flow_api.g_varchar2_table(13) := '6D4341434E432C514141532C57414344642C4541414F652C59414163662C4541414F67422C594143354270422C49414149452C4F41414F432C6F4241416F42652C51414151522C4B41414B432C45414153502C4741457244412C4541414F69422C634141';
wwv_flow_api.g_varchar2_table(14) := '652C4741473942432C4F4141512C53414155432C4541414D432C47414370422C49414149432C4541416D422C434141432C534141532C654141652C7142414171422C6B4241416B422C774241436E46432C45414157432C55414155432C4F41437A422C47';
wwv_flow_api.g_varchar2_table(15) := '414169422C49414162462C454143412C4F41414F74422C4541414F6D422C47414350472C454141572C49414364482C47414151432C47414153432C4541416942492C534141534E2C47414333436E422C4541414F6D422C47414151432C45414352442C49';
wwv_flow_api.g_varchar2_table(16) := '414153452C4541416942492C534141534E2C49414331436A422C4B41414B432C4D41414D75422C4B41414B2C774441413044502C4F414F74466E422C4541414F32422C574143507A422C4B41414B30422C4F41414F432C4B41414B432C6D4241416D4274';
wwv_flow_api.g_varchar2_table(17) := '422C454141492C494141492C534141554F2C4741436C44662C4541414F652C55414159412C47414366412C47414165662C4541414F2B422C534141552F422C4541414F69422C6541437643662C4B41414B4A2C4F41414F452C4541414F572C5541415547';
wwv_flow_api.g_varchar2_table(18) := '2C5541433742642C4541414F2B422C514141532C45414368422F422C4541414F69422C634141652C4D41473942662C4B41414B38422C4F41414F6E432C514141516F432C474141472C6742414167422C5741456E432C49414149432C4541414B31422C45';
wwv_flow_api.g_varchar2_table(19) := '4141492C4741456232422C594141572C574143506A432C4B41414B30422C4F41414F432C4B41414B4F2C694241416942462C474141492C4B414376436C432C4541414F71432C7342414177422C55414B39437A432C49414149452C4F41414F432C6F4241';
wwv_flow_api.g_varchar2_table(20) := '416F42652C514141552C53414155642C4741432F432C4941414973432C4541476743432C45414155432C4541436C43432C454171425A2C47417642497A432C4541414F30432C6341437942482C45416942374276432C4541414F32432C6742416A426743';
wwv_flow_api.g_varchar2_table(21) := '482C454169426678432C4541414F34432C6D424168423142482C45414130422C5141415A462C4541447442442C454145572C534141554F2C474143622C49414149432C45414341432C4541415737432C4B41414B32422C4B41414B612C59414159482C45';
wwv_flow_api.g_varchar2_table(22) := '4141552C43414145532C4D41414F502C49415778442C4F415649442C494143414D2C4541415770432C454141452C6B4341416F432B422C454141632C534141572C4941414D2C59414159512C55414155562C49414531472C574143514F2C47414341412C';
wwv_flow_api.g_varchar2_table(23) := '45414153492C53414562482C45414153472C5941534A68442C4B41414B69442C4D41414D432C514141512C6F42414171422C4941414D70442C4541414F572C53414155582C47414768462C4F414441452C4B41414B432C4D41414D75422C4B41414B2C34';
wwv_flow_api.g_varchar2_table(24) := '454143542C4541455878422C4B41414B6D442C4F41414F432C4F41414F74442C4541414F75442C65414167422C4341437443432C5541415778442C4541414F79442C6541436E422C43414543432C634141652C4941414D31442C4541414F572C53414535';
wwv_flow_api.g_varchar2_table(25) := '4267442C694241416B4272422C4541436C4273422C514141532C53414155432C474145662C47414149412C4541414B432C4D41434C2C4941414B2C49414149432C454141492C45414147412C45414149462C4541414B432C4D41414D74432C4F41415175';
wwv_flow_api.g_varchar2_table(26) := '432C4941436E4337442C4B41414B38442C4B41414B482C4541414B432C4D41414D432C47414147452C49414149432C534141534C2C4541414B432C4D41414D432C4741414733432C4D41414F2C4B41414D70422C4541414F6D452C714241492F457A442C';
wwv_flow_api.g_varchar2_table(27) := '454141452C4941414D562C4541414F6F452C694241416942432C4B41414B522C4541414B532C534145314370452C4B41414B69442C4D41414D432C514141512C6D4241416F422C4941414D70442C4541414F572C53414155582C4941476C4575452C5341';
wwv_flow_api.g_varchar2_table(28) := '4155222C2266696C65223A227363726970742E6A73227D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35933458470944203)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'js/script.js.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2E666F732D726567696F6E2D6F7665726C61792C2E666F732D726567696F6E2D6F7665726C61792D66697865647B706F736974696F6E3A6162736F6C7574653B7A2D696E6465783A3435303B7669736962696C6974793A76697369626C653B7769647468';
wwv_flow_api.g_varchar2_table(2) := '3A313030253B6865696768743A313030253B6261636B67726F756E643A72676261283235352C3235352C3235352C2E35297D2E666F732D726567696F6E2D6F7665726C61792D66697865647B706F736974696F6E3A66697865647D0A2F2A2320736F7572';
wwv_flow_api.g_varchar2_table(3) := '63654D617070696E6755524C3D7374796C652E6373732E6D61702A2F';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35946467188328314)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'css/style.min.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227374796C652E637373225D2C226E616D6573223A5B5D2C226D617070696E6773223A22414141412C6D422C434153412C79422C434152492C69422C434143412C572C434143412C6B422C43';
wwv_flow_api.g_varchar2_table(2) := '4143412C552C434143412C572C434143412C2B422C4341474A2C79422C434143492C63222C2266696C65223A227374796C652E637373222C22736F7572636573436F6E74656E74223A5B222E666F732D726567696F6E2D6F7665726C61797B5C6E202020';
wwv_flow_api.g_varchar2_table(3) := '20706F736974696F6E3A206162736F6C7574653B5C6E202020207A2D696E6465783A203435303B5C6E202020207669736962696C6974793A2076697369626C653B5C6E2020202077696474683A20313030253B5C6E202020206865696768743A20313030';
wwv_flow_api.g_varchar2_table(4) := '253B5C6E202020206261636B67726F756E643A2072676261283235352C203235352C203235352C20302E35293B5C6E7D5C6E5C6E2E666F732D726567696F6E2D6F7665726C61792D66697865647B5C6E20202020706F736974696F6E3A2066697865643B';
wwv_flow_api.g_varchar2_table(5) := '5C6E202020207A2D696E6465783A203435303B5C6E202020207669736962696C6974793A2076697369626C653B5C6E2020202077696474683A20313030253B5C6E202020206865696768743A20313030253B5C6E202020206261636B67726F756E643A20';
wwv_flow_api.g_varchar2_table(6) := '72676261283235352C203235352C203235352C20302E35293B5C6E7D5C6E5C6E225D7D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35946753809328340)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'css/style.css.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2E666F732D726567696F6E2D6F7665726C61797B0A20202020706F736974696F6E3A206162736F6C7574653B0A202020207A2D696E6465783A203435303B0A202020207669736962696C6974793A2076697369626C653B0A2020202077696474683A2031';
wwv_flow_api.g_varchar2_table(2) := '3030253B0A202020206865696768743A20313030253B0A202020206261636B67726F756E643A2072676261283235352C203235352C203235352C20302E35293B0A7D0A0A2E666F732D726567696F6E2D6F7665726C61792D66697865647B0A2020202070';
wwv_flow_api.g_varchar2_table(3) := '6F736974696F6E3A2066697865643B0A202020207A2D696E6465783A203435303B0A202020207669736962696C6974793A2076697369626C653B0A2020202077696474683A20313030253B0A202020206865696768743A20313030253B0A202020206261';
wwv_flow_api.g_varchar2_table(4) := '636B67726F756E643A2072676261283235352C203235352C203235352C20302E35293B0A7D0A2F2A2320736F757263654D617070696E6755524C3D7374796C652E6373732E6D6170202A2F0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(35947118939328356)
,p_plugin_id=>wwv_flow_api.id(35822631205839510)
,p_file_name=>'css/style.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done




