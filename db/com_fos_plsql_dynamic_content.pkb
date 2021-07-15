create or replace package body com_fos_plsql_dynamic_content
as

-- =============================================================================
--
--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)
--
--  This is a refreshable version of the PL/SQL Dynamic Content Region.
--
--  License: MIT
--
--  GitHub: https://github.com/foex-open-source/fos-plsql-dynamic-content
--
-- =============================================================================

G_METHOD_HTP  constant varchar2(10) := 'htp';
G_METHOD_CLOB constant varchar2(10) := 'clob';

procedure htp_p_clob
  ( p_clob clob
  )
as
    l_offset number;
    l_chunk  varchar2(32767);
begin
    while apex_string.next_chunk
            ( p_str    => p_clob
            , p_chunk  => l_chunk
            , p_offset => l_offset
            , p_amount => 30000 -- can't use 32767 b/c of multibyte characters; if using many multibyte characters, you need to turn this even lower
            )
    loop
       sys.htp.prn(l_chunk);
    end loop;
end;

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

    c_method                p_region.attribute_14%type := nvl(p_region.attribute_14, G_METHOD_HTP);
    l_plsql_code            p_region.attribute_01%type := p_region.attribute_01;

    l_lazy_load             boolean                    := nvl(p_region.attribute_11, 'N') = 'Y';
    l_lazy_refresh          boolean                    := nvl(p_region.attribute_12, 'N') = 'Y';

    c_options               apex_t_varchar2            := apex_string.split(p_region.attribute_15, ':');
    c_substitute_values     boolean                    := 'substitute-values' member of c_options;
    c_sanitize_content      boolean                    := 'sanitize-content'  member of c_options;

    -- Javascript Initialization Code
    l_init_js_fn            varchar2(32767)            := nvl(apex_plugin_util.replace_substitutions(p_region.init_javascript_code), 'undefined');

    -- page items to submit settings
    l_items_to_submit       varchar2(4000)             := apex_plugin_util.page_item_names_to_jquery(p_region.attribute_02);
    l_suppress_change_event boolean                    := p_region.attribute_03 is not null and p_region.attribute_04 = 'Y';

    -- spinner settings
    l_show_spinner          boolean                    := p_region.attribute_05 != 'N';
    l_show_spinner_overlay  boolean                    := p_region.attribute_05 like '%_OVERLAY';
    l_spinner_position      varchar2(4000)             :=
        case
            when p_region.attribute_05 like 'ON_PAGE%'   then 'body'
            when p_region.attribute_05 like 'ON_REGION%' then '#' || l_region_id
            else null
        end;

    -- variables for CLOB mode

    -- used to store the original g_clob_01 value
    -- and restore it once we're done with g_clob_01
    l_temp_g_clob_01        clob;
    c_data_variable         varchar2(4000)             := 'R' || p_region.id || '_DATA';
begin
    -- standard debugging intro, but only if necessary
    if apex_application.g_debug
    then
        apex_plugin_util.debug_region
          ( p_plugin => p_plugin
          , p_region => p_region
          );
    end if;

    -- sanity checks
    if c_sanitize_content and not c_method = G_METHOD_CLOB then
        raise_application_error(-20000, 'The sanitize option can only be used in combination with Output Method: APEX_APPLICATION.g_clob_01');
    end if;

    -- conditionally load the DOMPurify library
    if c_sanitize_content then
        apex_javascript.add_library
          ( p_name       => 'purify#MIN#'
          , p_directory  => p_plugin.file_prefix || 'js/dompurify/2.2.6/'
          , p_key        => 'fos-purify'
          );
    end if;

    -- a wrapper is needed to properly identify and replace the content in case of a refresh
    sys.htp.p('<div id="' || apex_escape.html_attribute(l_wrapper_id) || '">');

    -- we let the devloper choose whether we substitute values automatically for them or not
    if c_substitute_values
    then
        l_plsql_code := apex_plugin_util.replace_substitutions(l_plsql_code);
    end if;

    -- only when lazy-loading is turned off we immediately execute the plsql code.
    -- with lazy-loading the page will be rendered first, then an ajax call executes the code
    if not l_lazy_load
    then
        if c_method = G_METHOD_CLOB then
            l_temp_g_clob_01 := apex_application.g_clob_01;
            apex_application.g_clob_01 := null;
        end if;

        apex_exec.execute_plsql(l_plsql_code);

        if c_method = G_METHOD_CLOB then
            if not c_sanitize_content then
                htp_p_clob(apex_application.g_clob_01);
            else
                apex_json.initialize_clob_output;
                apex_json.open_object;
                apex_json.write('val', apex_application.g_clob_01);
                apex_json.close_object;
                htp.p('<script>');
                htp_p_clob('var ' || c_data_variable || ' = (' || apex_json.get_clob_output || ').val;');
                htp.p('</script>');
                apex_json.free_output;

                apex_application.g_clob_01 := l_temp_g_clob_01;
            end if;
        end if;
    end if;

    -- closing the wrapper
    sys.htp.p('</div>');

    -- creating a json object with the region settings to pass to the client
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
    apex_json.write('lazyLoad'           , l_lazy_load            );
    apex_json.write('lazyRefresh'        , l_lazy_refresh         );
    apex_json.write('sanitizeContent'    , c_sanitize_content     );

    if c_sanitize_content then
        apex_json.write_raw('DOMPurifyConfig', '{}');
    end if;

    if not l_lazy_load and c_sanitize_content and c_method = G_METHOD_CLOB then
        apex_json.write_raw('initialContent', c_data_variable);
    end if;

    apex_json.close_object;

    -- initialization code for the region widget. needed to handle the refresh event
    apex_javascript.add_onload_code('FOS.region.plsqlDynamicContent(' || apex_json.get_clob_output|| ', '|| l_init_js_fn || ');');

    apex_json.free_output;

    return l_return;
end render;

function ajax
  ( p_region apex_plugin.t_region
  , p_plugin apex_plugin.t_plugin
  )
return apex_plugin.t_region_ajax_result
as

    c_method                  p_region.attribute_14%type := nvl(p_region.attribute_14, G_METHOD_HTP);

    -- plug-in attributes
    l_plsql_code              p_region.attribute_01%type := p_region.attribute_01;
    l_items_to_return         p_region.attribute_03%type := p_region.attribute_03;
    c_substitute_values       boolean                    := instr(p_region.attribute_15, 'substitute-values') > 0;

    -- local variables
    l_item_names              apex_t_varchar2;

    -- needed for accessing the htp buffer
    l_htp_buffer              sys.htp.htbuf_arr;
    l_rows_x                  number                     := 9999999;
    l_rows                    number                     := 9999999;

    -- resulting content
    l_content                 clob                       := '';
    l_buffer                  varchar2(32767);

    l_return                  apex_plugin.t_region_ajax_result;

    -- fast append of a clob
    -- see benchmarks here: https://gist.github.com/vlsi/052424856512f80137989c817cb8f046
    procedure clob_append
      ( p_clob    in out nocopy clob
      , p_buffer  in out nocopy varchar2
      , p_append  in            varchar2
      )
    as
    begin
        p_buffer := p_buffer || p_append;
    exception
        when value_error then
            if p_clob is null
            then
                p_clob := p_buffer;
            else
                sys.dbms_lob.writeappend(p_clob, length(p_buffer), p_buffer);
            end if;
            p_buffer := p_append;
    end clob_append;
    --
begin
    -- standard debugging intro, but only if necessary
    if apex_application.g_debug
    then
        apex_plugin_util.debug_region
          ( p_plugin => p_plugin
          , p_region => p_region
          );
    end if;

    if c_method = G_METHOD_HTP then

        -- helps remove the unnecesarry "X-ORACLE-IGNORE: IGNORE" which appear when using htp.get_page
        sys.htp.p;
        sys.htp.get_page(l_htp_buffer, l_rows_x);

        -- we let the devloper choose whether we substitute values automatically for them or not
        if c_substitute_values
        then
            l_plsql_code := apex_plugin_util.replace_substitutions(l_plsql_code);
        end if;

        -- executing the pl/sql code
        apex_exec.execute_plsql(l_plsql_code);

        -- getting the htp buffer, where l_plsql_code might have written into.
        -- has the side effect of removing it
        sys.htp.get_page(l_htp_buffer, l_rows);

        -- rewriting htp buffer into a clob and pass back in json object
        for l_idx in 1 .. l_rows
        loop
            --l_content := l_content || l_htp_buffer(l_idx); -- slower
            clob_append(l_content, l_buffer, l_htp_buffer(l_idx));
        end loop;
        l_content := l_content || l_buffer;

    elsif c_method = G_METHOD_CLOB then

        -- executing the pl/sql code
        apex_exec.execute_plsql(l_plsql_code);
        l_content := apex_application.g_clob_01;

    end if;

    apex_json.open_object;
    apex_json.write('status' , 'success');
    apex_json.write('content', l_content);

    -- adding info about the page items to return
    if l_items_to_return is not null
    then

        l_item_names := apex_string.split(l_items_to_return,',');

        apex_json.open_array('items');

        for l_idx in 1 .. l_item_names.count
        loop
            apex_json.open_object;
            apex_json.write
              ( p_name  => 'id'
              , p_value => l_item_names(l_idx)
              );
            apex_json.write
              ( p_name  => 'value'
              , p_value => apex_util.get_session_state(l_item_names(l_idx))
              );
            apex_json.close_object;
        end loop;

        apex_json.close_array;
    end if;

    apex_json.close_object;

    return l_return;
end ajax;

end;
/


