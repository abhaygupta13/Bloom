({
    doInit: function (cmp, event, helper) {
        try{
            var vfHost = window.location.origin + "/apex/GcLiveIxn";
            console.log("setting vf src : ", vfHost);
            cmp.set("v.vfHost", vfHost);

            var utilityAPI = cmp.find("GcLiveIxn");
            var workspaceAPI = cmp.find("workspace");
            
            utilityAPI.getAllUtilityInfo().then(function (response) {
                var myUtilityInfo = response[0];
                cmp.set("v.utilityId", myUtilityInfo.id);
            })
            .catch(function (error) {
                console.log(error);
            }); 
           
        }catch(e){
            console.log("error : ", e)
        }
    }
})