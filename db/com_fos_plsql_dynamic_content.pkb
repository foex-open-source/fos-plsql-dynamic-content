create or replace package body com_fos_plsql_dynamic_content
as

function render
    ( p_region              apex_plugin.t_region
    , p_plugin              apex_plugin.t_plugin
    , p_is_printer_friendly boolean
    )
return apex_plugin.t_region_render_result
as
    l_return apex_plugin.t_region_render_result;

    -- required settings
    l_region_id             varchar2(4000)             := p_region.static_id;
    l_wrapper_id            varchar2(4000)             := p_region.static_id || '_FOS_WRAPPER';
    l_ajax_identifier       varchar2(4000)             := apex_plugin.get_ajax_identifier;
    l_plsql_code            p_region.attribute_01%type := p_region.attribute_01;

    -- page items to submit settings
    l_items_to_submit       varchar2(4000) := apex_plugin_util.page_item_names_to_jquery(p_region.attribute_02);
    l_suppress_change_event boolean        := p_region.attribute_03 is not null and p_region.attribute_04 = 'Y';

    -- spinner settings
    l_show_spinner          boolean        := p_region.attribute_05 != 'N';
    l_show_spinner_overlay  boolean        := p_region.attribute_05 like '%_OVERLAY';
    l_spinner_position      varchar2(4000) :=
        case
            when p_region.attribute_05 like 'ON_PAGE%'   then 'body'
            when p_region.attribute_05 like 'ON_REGION%' then '#' || l_region_id
            else null
        end;
begin

    if apex_application.g_debug then
        apex_plugin_util.debug_region
            ( p_plugin => p_plugin
            , p_region => p_region
            );
    end if;


    -- a wrapper is needed to properly identify and replace the content in case of a refresh
    sys.htp.p('<div id="' || apex_escape.html_attribute(l_wrapper_id) || '">');

    -- executing the pl/sql code
    apex_exec.execute_plsql(l_plsql_code);

    --closing the wrapper
    sys.htp.p('</div>');

    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write('ajaxIdentifier'     , l_ajax_identifier      );
    apex_json.write('regionId'           , l_region_id            );
    apex_json.write('regionWrapperId'    , l_wrapper_id           );
    apex_json.write('itemsToSubmit'      , l_items_to_submit      );
    apex_json.write('suppressChangeEvent', l_suppress_change_event);
    apex_json.write('showSpinner'        , l_show_spinner         );
    apex_json.write('showSpinnerOverlay' , l_show_spinner_overlay );
    apex_json.write('spinnerPosition'    , l_spinner_position     );
    apex_json.close_object;

    -- initialization code for the region widget. needed to handle the refresh event
    apex_javascript.add_onload_code('FOS.region.plsqlDynamicContent.init(' || apex_json.get_clob_output || ');');

    apex_json.free_output;

    return l_return;
end;


function ajax
    ( p_region apex_plugin.t_region
    , p_plugin apex_plugin.t_plugin
    )
return apex_plugin.t_region_ajax_result
as
    -- plug-in attributes
    l_plsql_code      p_region.attribute_01%type := p_region.attribute_01;
    l_items_to_return p_region.attribute_03%type := p_region.attribute_03;

    -- local variables
    l_item_names apex_t_varchar2;

    -- needed for accessing the htp buffer
    l_buffer  sys.htp.htbuf_arr;
    l_rows_x  number := 9999999;
    l_rows    number := 9999999;

    -- resulting content
    l_content clob   := '';

    l_return  apex_plugin.t_region_ajax_result;
begin

    if apex_application.g_debug then
        apex_plugin_util.debug_region
            ( p_plugin => p_plugin
            , p_region => p_region
            );
    end if;

    -- helps remove the unnecesarry "X-ORACLE-IGNORE: IGNORE" which appear when using htp.get_page
    sys.htp.p;
    sys.htp.get_page(l_buffer, l_rows_x);

    -- executing the pl/sql code
    apex_exec.execute_plsql(l_plsql_code);

    -- getting the htp buffer. has the side effect of removing it
    sys.htp.get_page(l_buffer, l_rows);

    -- rewriting it into a clob
    for i in 1 .. l_rows loop
        l_content := l_content || l_buffer(i);
    end loop;

    apex_json.open_object;
    apex_json.write('status' , 'success');
    apex_json.write('content', l_content);

    -- adding info about the page items to return
    if l_items_to_return is not null then

        l_item_names := apex_string.split(l_items_to_return,',');

        apex_json.open_array('items');

        for i in 1 .. l_item_names.count loop
            apex_json.open_object;
            apex_json.write
                ( p_name  => 'id'
                , p_value => l_item_names(i)
                );
            apex_json.write
                ( p_name  => 'value'
                , p_value => apex_util.get_session_state(l_item_names(i))
                );
            apex_json.close_object;
        end loop;

        apex_json.close_array;
    end if;

    apex_json.close_object;

    return l_return;
end;

end;
/


