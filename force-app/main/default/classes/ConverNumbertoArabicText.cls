/***
Class       : ConverNumbertoArabicText
Author      : Smaartt
Description : 
TestClass   : ConverNumbertoArabicTextTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/07/23           Initial Version 
*********************************/
public class ConverNumbertoArabicText {
    
    @InvocableMethod(label = 'Fetch Converted Arabic Amount')
    public static void fetchConvertedResponse(List<Id> recordIds) {
        
         List<Integration_Details__mdt> customMetadataRecord = [SELECT End_Point_URL__c, Api_Key__c FROM Integration_Details__mdt Where DeveloperName='ConvertNumberToArabicWords'];
        
        String apiUrl = customMetadataRecord[0].End_Point_URL__c;
        String apiKey = customMetadataRecord[0].Api_Key__c;
        
        
        List<String> results = new List<String>();
        
        // Enqueue a job for each Sales Order record
        for (Id salesorderId : recordIds) {
            System.enqueueJob(new CalloutQueueable(apiUrl, apiKey, salesorderId));
        }
    }
    
}