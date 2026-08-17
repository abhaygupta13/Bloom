({
    init: function(component, event, helper) {
        component.set('v.userColumns', [   
            {label: 'Name', fieldName: 'Name', type: 'text'},   
            {label: 'Email', fieldName: 'Email', type: 'text'},  
            {label: 'Phone', fieldName: 'Phone', type: 'text'},
            {label: 'Start Date', fieldName: 'Start_Date__c', type: 'date-local', editable:'true',
            },
            {label: 'End Date', fieldName: 'End_Date__c', type: 'date-local', editable:'true',
            }
        ]);   
        // Fetch list of user records on component initialization
        helper.fetchUserRecords(component);
    },
    
	onSave : function( component, event, helper ) {
        helper.saveUserRecords(component, event);
    }
})