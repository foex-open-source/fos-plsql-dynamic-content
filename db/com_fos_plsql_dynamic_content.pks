create or replace package com_fos_plsql_dynamic_content
as

    function render
        ( p_region              apex_plugin.t_region
        , p_plugin              apex_plugin.t_plugin
        , p_is_printer_friendly boolean
        )
    return apex_plugin.t_region_render_result;

    function ajax
        ( p_region apex_plugin.t_region
        , p_plugin apex_plugin.t_plugin
        )
    return apex_plugin.t_region_ajax_result;

end;
/


