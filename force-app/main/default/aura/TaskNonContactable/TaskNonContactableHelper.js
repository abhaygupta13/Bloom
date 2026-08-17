({
    handleTaskCompletion : function(component, event, helper) {
        var action = component.get("c.markTaskComplete");
        action.setParams({ 
            recordId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Inside Success');
                var returnValue = response.getReturnValue();
                var message;
                if(returnValue == 'Record Has Been Updated Successfully.'){
                    message = 'Record Has Been Updated Successfully.'
                }else if(returnValue == 'Not Contactable' || returnValue == 'Completed'){
                    message = 'This request is '+returnValue +'.No further action required.'
                }  
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": message,
                    "type" : "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "error",
                    "message": "Please contact your system admin with error message - "+ errors[0].message
                });
                toastEvent.fire(); 
                $A.get("e.force:closeQuickAction").fire(); 
            }
        });
        $A.enqueueAction(action);      
    },
})