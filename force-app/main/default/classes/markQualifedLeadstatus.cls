/***
Class       : markQualifedLeadstatus
Author      : Smaartt
Description : 
TestClass   : markQualifedLeadstatusTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class markQualifedLeadstatus {
    @AuraEnabled
    public static void markQualifiedStatus(String req){
        Lead leadNew  = [select Id,status,Owner.Name from Lead where id=:req];
        leadNew.Status = 'In Progress';
        leadNew.ContactCentreLeadStatus__c = 'Qualified';
        leadNew.Qualified_By__c = UserInfo.getUserId();
        leadNew.Qualified_Date__c = DateTime.now();
        try{
            update leadNew;    
        }catch(Exception e){
            throw new Auraexception(e);
        }
    }
}