({
	getClosedCaseStatus : function (component, event, helper) {
            var action = component.get("c.markClosedStatus");
            var toastEvent = $A.get("e.force:showToast");
            action.setParams({
                req: component.get("v.recordId"),
            });
            
            action.setCallback(this,function(result){
                var state = result.getState();
                console.log('state ');
                if (state === "SUCCESS") {
                    var reqId = result.getReturnValue();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Success!",
                        message: "Record Has Been Updated Successfully.",
                        type: "success"
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }else if (state === "ERROR") {
                    var errors = result.getError();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "warning",
                        "message": errors[0].message
                    });
                    toastEvent.fire(); 
                    $A.get("e.force:closeQuickAction").fire();
                }
            });        
            $A.enqueueAction(action);     
    },
    
})