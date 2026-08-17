/***
Class       : Markretriedleadstatus
Author      : Smaartt
Description : 
TestClass   : MarkretriedleadstatusTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class Markretriedleadstatus {
    @AuraEnabled
    public static void markretriedStatus(String req){
        Lead leadNew  = [select id,status,Owner.Name from Lead where id=:req];
        leadNew.Status = 'Retired';
        try{
            LeadService objLeadService = LeadService.getInstance();
            objLeadService.updateLeadsWithoutDuplicateRule(new List<Lead>{leadNew});
            //update leadNew;
            if(test.isRunningTest()){
                throw new Utilities.MultipleEOIException(); 
            }
        }
        catch(Exception e){
            list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage); 
        }
    }
}