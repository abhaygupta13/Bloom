({
    onPicklistChange: function(component, event, helper) {
        try{
            let fieldName = event.getSource().get("v.fieldName");
            let newValue = event.getSource().get("v.value");
            let selectedRetiredreason = component.get("v.selectedRetiredreason");
            console.log('newValue'+newValue);
            component.set("v.selectedReason",newValue);
            if (newValue === 'Future Interest') {
                component.set("v.selectedRetiredreason", true);
            } else {
                component.set("v.selectedRetiredreason", false);
                // component.set("v.futureInterestDateError", false); // Reset the error state when the picklist value changes
            }
        }
        catch(e){
            console.log(e.message);
        }
    },
    handleSave: function (component, event, helper) {
        console.log('Inside handleSave');
        let action = component.get("c.markRetiredStatus");
        console.log(component.get("v.recordId"));
        console.log(component.get("v.selectedReason"));
        console.log(component.find("retirementcomment").get("v.value"));
        action.setParams({
            req: component.get("v.recordId"),
            retirementReason: component.get("v.selectedReason"),
            comments: component.find("retirementcomment").get("v.value")
        });
        
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                // Show toast message
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!", 
                    "type" : "success",
                    "message": "Lead has been updated successfully."
                });
                toastEvent.fire();
                
                // Close modal or refresh view
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                let errors = response.getError();
                console.error("Error: ", errors);
            }
        });
        
        $A.enqueueAction(action);
    },
    handleSuccess :function(component, event, helper) {
        var record = event.getParam("response");
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!", 
            "type" : "success",
            "message": "Lead has been updated successfully."
        });
        toastEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        
    },
    handleError : function(component, event, helper) {
        
        var errors = event.getParams();
        console.log(errors);
        console.log(event.getParam("detail"));
        
        console.log(event.getParam("output").fieldErrors);
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!", 
            "type" : "error",
            "message": event.getParam("detail")
        });
        toastEvent.fire();
        
    },
    
    handleReset: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
})