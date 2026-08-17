({
    doInit : function(component, event, helper) {
        const action = component.get("c.updateCaseOwner");
        action.setParams({ recordId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:showToast").setParams({
                    title: "Success",
                    message: "Owner is successfully updated.",
                    type: "success"
                }).fire();
                $A.get("e.force:refreshView").fire();
            } else {
                const errors = response.getError();
                let message = (errors && errors[0] && errors[0].message) || "Unknown error";
                $A.get("e.force:showToast").setParams({
                    title: "Error",
                    message: message,
                    type: "error"
                }).fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });

        $A.enqueueAction(action);
    }
})