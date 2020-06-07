window.FOS                     = window.FOS                     || {};
FOS.region                     = FOS.region                     || {};
FOS.region.plsqlDynamicContent = FOS.region.plsqlDynamicContent || {};

/**
 * Initialization function for the dynamic content region.
 * This function must be run for the region to subscribe to the refresh event
 * Ixpects as parameter an object with the following attributes:
 *
 * @param {Object}  config                         Configuration object holding all attributes
 * @param {string}  config.ajaxIdentifier          Ajax Identifier needed by apex.server.plugin
 * @param {string}  config.regionId                The main region id. The region on which "refresh" can be triggered
 * @param {string}  config.regionWrapperId         Id of wrapper region. The contents of this element will be replaced with the new content
 * @param {string}  [config.itemsToSubmit]         Comma-separated page item names in jQuery selector format
 * @param {boolean} [config.suppressChangeEvent]   If there are page items to be returned, this decides whether to trigger a change event or not
 * @param {boolean} [config.showSpinner]           Shows a spinner or not
 * @param {boolean} [config.showSpinnerOverlay]    Depends on showSpinner. Adds a translucent overlay behind the spinner
 * @param {string}  [config.spinnerPosition]       Depends on showSpinner. A jQuery selector unto which the spinner will be shown
 */

FOS.region.plsqlDynamicContent.init = function(config){

    apex.debug.info('FOS.region.plsqlDynamicContent.init', config);

    var loadingIndicatorFn;

    //configures the showing and hiding of a possible spinner
    if(config.showSpinner){
        loadingIndicatorFn = (function(position, showOverlay){
            var fixedOnBody = position == 'body';
            return function( pLoadingIndicator) {
                var overlay$;
                var spinner$ = apex.util.showSpinner(position, {fixed: fixedOnBody});
                if(showOverlay){
                    overlay$ = $('<div class="fos-region-overlay' + (fixedOnBody ? '-fixed' : '') + '"></div>').prependTo(position);
                }
                function removeSpinner(){
                    if(overlay$){
                        overlay$.remove();
                    }
                    spinner$.remove();
                }
                //this function must return a function which handles the removing of the spinner
                return removeSpinner;
            };
        })(config.spinnerPosition, config.showSpinnerOverlay);
    }

    //implementing the apex.region interface in order to respond to refresh events
    apex.region.create(config.regionId, {
        type: 'fos-region-plsql-dynamic-content',
        refresh: function(){
            apex.server.plugin(config.ajaxIdentifier, {
                pageItems: config.itemsToSubmit
            }, {
                //needed to trigger before and after refresh events on the region
                refreshObject: '#' + config.regionId,
                //this function is reponsible for showing a spinner
                loadingIndicator: loadingIndicatorFn,
                success: function(data){
                    //setting page item values
                    if(data.items){
                        for(var i = 0; i < data.items.length; i++){
                            apex.item(data.items[i].id).setValue(data.items[i].value, null, config.suppressChangeEvent);
                        }
                    }
                    //replacing the old content with the new
                    $('#' + config.regionWrapperId).html(data.content);
                },
                //omitting an error handler lets apex.server use the default one
                dataType: 'json'
            });
        }
    });
};


