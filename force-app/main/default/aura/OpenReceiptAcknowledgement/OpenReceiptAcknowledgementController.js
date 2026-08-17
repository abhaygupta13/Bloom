({
    doInit: function(cmp, evt, helper) {
        
        try{
           
            var myPageRef = cmp.get("v.pageReference");
            var recordId = myPageRef.state.c__recordId;
            
            cmp.set("v.recordId", recordId);
            
        }catch(e){
            console.log(e.message)
        }
        
    },
    
    reInit : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})