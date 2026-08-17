/***
Class       : TaskNonContactable
Author      : Smaartt
Description : 
TestClass   : TaskNonContactableTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              10/06/23           Initial Version 
****************************************************************************************************************/

public class TaskNonContactable {
 @auraenabled
    public static id rejectReq(String req,String reason){
        Task tsk  = [select id,status from Task where id=:req];
        tsk.Description = 'Not Contactable';
        tsk.Status = 'Completed';
        
        tsk.Not_Contactable__c = True;
        try{
            update tsk;
            return tsk.id;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        }
    }
    
    @AuraEnabled
    public static String requestDetail(String requestId){
        Task request = [select Id,status from Task where Id=:requestId LIMIT 1];
        system.debug('request *** ' + request);
        return request.status;
    }
    

}