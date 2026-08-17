({
    fetchUserRecords: function(component) {
        // Fetch list of user records using Apex controller
        var action = component.get("c.getUserRecords");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var users = response.getReturnValue();
                component.set("v.users", users);
            }
        });
        $A.enqueueAction(action);
    },
    
    toastMsg : function( strType, strMessage ) {
        var showToast = $A.get("e.force:showToast");  
        showToast.setParams({
            message : strMessage, 
            type : strType, 
            mode : 'sticky'
        });  
        showToast.fire();
    },
    
    saveUserRecords: function(component, event) {
        var updatedRecords = component.find("userTable").get("v.draftValues"); 
        if(updatedRecords == null){
            helper.toastMsg('success', 'No users updated!'); 
        }
        var action = component.get("c.updateUsers"); 
        action.setParams({
            'updatedUserList' : updatedRecords
        }); 
        action.setCallback( this, function( response ) {
            var state = response.getState();  
            if(state === "SUCCESS"){
                
                this.toastMsg('success', 'Records Saved Successfully.');
                $A.get('e.force:refreshView').fire();
            }else{
                // handle error response
                var errors = response.getError();
                if (errors) {
                    for (var i = 0; i < errors.length; i++) {
                        this.toastMsg('error', errors[i].pageErrors[0].message);
                        
                    }
                } else {
                    this.toastMsg('error', 'Something went wrong. Contact your system administrator.'); 
                }
            } 
            
        }); 
        $A.enqueueAction(action);
    }
})