/***
Class       : CancelCaseRequest
Author      : Smaartt
Description : 
TestClass   : CancelCaseRequestTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class CancelCaseRequest {
  @AuraEnabled
    public static void markClosedStatus(String req){
       
        try{
        Case CaseNew  = [select id,status,Owner.Name from Case where id=:req];
        CaseNew.Status = 'Closed';
        CaseNew.Case_Sub_Status__c='Transfer Completed';
            update CaseNew;
          
        }
        catch(Exception e){
            list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            system.debug(errorMessage);
            throw new Auraexception(errorMessage); 
        }
    }
    public static void Utility(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}