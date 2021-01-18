/* globals apex,$ */

var FOS = window.FOS || {};
FOS.region = FOS.region || {};

/**
 * Initialization function for the dynamic content region.
 * This function must be run for the region to subscribe to the refresh event
 * Input parameter is an object with the following attributes:
 *
 * @param {object}   config                         Configuration object holding all attributes
 * @param {string}   config.ajaxIdentifier          Ajax Identifier needed by apex.server.plugin
 * @param {string}   config.regionId                The main region id. The region on which "refresh" can be triggered
 * @param {string}   config.regionWrapperId         Id of wrapper region. The contents of this element will be replaced with the new content
 * @param {string}   [config.itemsToSubmit]         Comma-separated page item names in jQuery selector format
 * @param {boolean}  [config.suppressChangeEvent]   If there are page items to be returned, this decides whether to trigger a change event or not
 * @param {boolean}  [config.showSpinner]           Shows a spinner or not
 * @param {boolean}  [config.showSpinnerOverlay]    Depends on showSpinner. Adds a translucent overlay behind the spinner
 * @param {string}   [config.spinnerPosition]       Depends on showSpinner. A jQuery selector unto which the spinner will be shown
 * @param {boolean}  [config.sanitizeContent]       Whether to pass the content through DOMPurify
 * @param {object}   [config.DOMPurifyConfig]       Additional options to be passed to DOMPurify. Sanitize Content must be enabled.
 * @param {string}   [config.initialContent]        The initial content to be applied shown if sanitizeContent is enabled and lazyLoad is disabled
 * @param {function} initFn                         Initialization JavaScript Function to change the configuration at run-time
 */
FOS.region.plsqlDynamicContent = function (config, initFn) {

    var pluginName = 'FOS - PL/SQL Dynamic Content';
    apex.debug.info(pluginName, config, initFn);

    var context = this, el$;
    el$ = config.el$ = $('#' + config.regionId);

    // Allow the developer to perform any last (centralized) changes using Javascript Initialization Code
    if (initFn instanceof Function) {
        initFn.call(context, config);
    }

    //implementing the apex.region interface in order to respond to refresh events
    apex.region.create(config.regionId, {
        type: 'fos-region-plsql-dynamic-content',
        refresh: function () {
            if (config.isVisible || !config.lazyRefresh) {
                FOS.region.plsqlDynamicContent.refresh.call(context, config);
            } else {
                config.needsRefresh = true;
            }
        },
        option: function (name, value) {
            var whiteListOptions = ['loaded','needsRefresh','showSpinnerOverlay','spinnerPosition','visibilityCheckDelay'];
            var argCount = arguments.length;
            if (argCount === 1) {
                return config[name];
            } else if (argCount > 1) {
                if (name && value && whiteListOptions.includes(name)) {
                    config[name] = value;
                } else if (name && !whiteListOptions.includes(name)) {
                    apex.debug.warn('you are trying to set an option that is not allowed: ' + name);
                }
            }
        }
    });

    if(config.sanitizeContent && config.initialContent){
        var content = DOMPurify.sanitize(config.initialContent, config.DOMPurifyConfig || {});
        $('#' + config.regionWrapperId).html(content);
    }

    // check if we need to lazy load the region
    if (config.lazyLoad) {
        apex.widget.util.onVisibilityChange(el$[0], function (isVisible) {
            config.isVisible = isVisible;
            if (isVisible && (!config.loaded || config.needsRefresh)) {
                apex.region(config.regionId).refresh();
                config.loaded = true;
                config.needsRefresh = false;
            }
        });
        apex.jQuery(window).on('apexreadyend', function () {
            // we add avariable reference to avoid loss of scope
            var el = el$[0];
            // we have to add a slight delay to make sure apex widgets have initialized since (surprisingly) "apexreadyend" is not enough
            setTimeout(function () {
                apex.widget.util.visibilityChange(el, true);
            }, config.visibilityCheckDelay || 1000);
        });
    }
};

FOS.region.plsqlDynamicContent.refresh = function (config) {
    var loadingIndicatorFn;
    //configures the showing and hiding of a possible spinner
    if (config.showSpinner) {
        loadingIndicatorFn = (function (position, showOverlay) {
            var fixedOnBody = position == 'body';
            return function (pLoadingIndicator) {
                var overlay$;
                var spinner$ = apex.util.showSpinner(position, { fixed: fixedOnBody });
                if (showOverlay) {
                    overlay$ = $('<div class="fos-region-overlay' + (fixedOnBody ? '-fixed' : '') + '"></div>').prependTo(position);
                }
                function removeSpinner() {
                    if (overlay$) {
                        overlay$.remove();
                    }
                    spinner$.remove();
                }
                //this function must return a function which handles the removing of the spinner
                return removeSpinner;
            };
        })(config.spinnerPosition, config.showSpinnerOverlay);
    }

    // trigger our before refresh event allowing for a developer to skip the refresh by returning false
    var eventCancelled = apex.event.trigger('apexbeforerefresh', '#' + config.regionId, config);
    if (eventCancelled) {
        apex.debug.warn('the refresh action has been cancelled by the "apexbeforerefresh" event!');
        return false;
    }
    apex.server.plugin(config.ajaxIdentifier, {
        pageItems: config.itemsToSubmit
    }, {
        //needed to trigger before and after refresh events on the region
        refreshObject: '#' + config.regionId,
        //this function is reponsible for showing a spinner
        loadingIndicator: loadingIndicatorFn,
        success: function (data) {
            //setting page item values
            if (data.items) {
                for (var i = 0; i < data.items.length; i++) {
                    apex.item(data.items[i].id).setValue(data.items[i].value, null, config.suppressChangeEvent);
                }
            }
            //replacing the old content with the new
            var content = data.content;
            if(config.sanitizeContent){
                content = DOMPurify.sanitize(content, config.DOMPurifyConfig || {});
            }
            $('#' + config.regionWrapperId).html(content);
            // trigger our after refresh event(s)
            apex.event.trigger('apexafterrefresh', '#' + config.regionId, config);
        },
        //omitting an error handler lets apex.server use the default one
        dataType: 'json'
    });
};

