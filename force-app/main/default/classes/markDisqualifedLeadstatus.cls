/***
Class       : markDisqualifedLeadstatus
Author      : Dhanraj
Description : 
TestClass   : markDisqualifedLeadstatusTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class markDisqualifedLeadstatus {
    @AuraEnabled
    public static void markDisqualifedStatus(String req){
        Lead leadNew  = [select id,status,Owner.Name from Lead where id=:req];
        leadNew.Status = 'Closed';
        leadNew.ContactCentreLeadStatus__c = 'Disqualified';
        leadNew.DisqualifiedBy__c = UserInfo.getUserId();
        leadNew.DisqualifiedDate__c = DateTime.now();
        try{
            update leadNew;    
        }catch(Exception e){
            throw new Auraexception(e);
        }
    }
}