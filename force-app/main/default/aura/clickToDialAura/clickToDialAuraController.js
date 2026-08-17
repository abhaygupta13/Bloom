({
    doInit: function(component, event, helper) {
        window.setTimeout($A.getCallback(function() {
            const panel = document.querySelector('.quick-actions-panel');

            if (panel) {
                const content = panel.querySelector('.slds-modal__content');
                console.log('Parent after render:', content);

                if (content) {
                    console.log('content.style.height after render:', content.style.height);
                    content.style.height = '100%';
                    content.style.maxHeight = '300px';
                }
            }
        }), 0);
    },

    handleClose: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})