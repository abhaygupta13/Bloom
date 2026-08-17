/***
Class       : markRetiredLeadstatus
Author      : Dhanraj
Description : 
TestClass   : markRetiredLeadstatusTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class markRetiredLeadstatus {
    @AuraEnabled
    public static void markRetiredStatus(String req, String retirementReason, String comments){
        if(req != null){
            Lead leadNew  = [select id,status,Owner.Name from Lead where id=:req];
            leadNew.Status = 'Closed';
            leadNew.LeadManagerStatus__c = 'Retired';
            leadNew.RetiredReason__c = retirementReason != null ? retirementReason : null;
            leadNew.RetirementComments__c = comments != null ? comments : '';
            leadNew.RetiredBy__c = UserInfo.getUserId();
            leadNew.Retried_Date__c = DateTime.now();
            try{
                update leadNew;    
            }catch(Exception e){
                throw new Auraexception(e);
            }
        }
    }
}