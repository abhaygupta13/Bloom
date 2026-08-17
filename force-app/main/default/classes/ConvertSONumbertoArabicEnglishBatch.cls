/***
Class       : ConvertSONumbertoArabicEnglishBatch
Author      : Smaartt
Description : 
TestClass   : ConvertSONumbertoArabicEnglishBatchTest
Execution   :  database.executeBatch(new ConvertSONumbertoArabicEnglishBatch(projectId),1);
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              19/01/24           Initial Version 
****************************************************************************************************************/

public class ConvertSONumbertoArabicEnglishBatch  implements Database.batchable<sobject>, Database.AllowsCallouts {
    public string query;
    public Id ProjectId;
    Public String apiUrl;
    Public string apiKey;
     List<Integration_Details__mdt> customMetadataRecord = [SELECT End_Point_URL__c, Api_Key__c FROM Integration_Details__mdt Where DeveloperName='ConvertNumberToArabicWords'];
            
    public ConvertSONumbertoArabicEnglishBatch(Id PrjId){
        this.ProjectId = PrjId;
        
        this.apiUrl = customMetadataRecord[0].End_Point_URL__c;
       this.apiKey = customMetadataRecord[0].Api_Key__c;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        query ='SELECT Id,Net_Amount_excluding_ADM_Fee_Arabic__c,NetAmountInWords__c,Net_Amount_in_Arabic_Words__c,Tax_Amount_in_Arabic_words__c,Tax_Amount_in_English__c, AmountPayable__c,Amount_Payable_in_English__c,Number_in_words_Arabic__c, TaxableAmount__c,NetAmount__c,Net_Amount_excl_ADMWaiver__c FROM Salesorder__c  WHERE Unit__r.Project__c=:ProjectId';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Salesorder__c> scope)
    {
        
        
        for(Salesorder__c so : scope){
            Http http = new Http();
            /*if (  so.AmountPayable__c != null && so.AmountPayable__c!=0 && so.Number_in_words_Arabic__c==null){
                HttpRequest request1 = new HttpRequest();
                request1.setEndpoint(apiUrl + '?the_number=' + so.AmountPayable__c + '&unit=درهم&hundreds_form=مائة');
                request1.setMethod('POST');
                request1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request1.setHeader('X-RapidAPI-Key', apiKey);
                request1.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                // Send the first request and get the response
                HttpResponse response1 = http.send(request1);
                
                // Check the response status
                if (response1.getStatusCode() == 200) {
                    String responseBody1 = response1.getBody();
                    System.debug(responseBody1);
                    Map<String, Object> jsonResponse1 = (Map<String, Object>) JSON.deserializeUntyped(responseBody1);
                    String result1 = String.valueOf(jsonResponse1.get('result'));
                    
                    so.Number_in_words_Arabic__c = result1;
                    so.Amount_Payable_in_English__c = Utilities.amountInWords(so.AmountPayable__c,'Dirham','Fils');
                    System.debug(so.Number_in_words_Arabic__c);
                }    
            }
            if (so.TaxableAmount__c != null && so.TaxableAmount__c != 0 &&  so.Tax_Amount_in_Arabic_words__c==null){
                
                // Second API request
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(apiUrl + '?the_number=' + so.TaxableAmount__c + '&unit=درهم&hundreds_form=مائة');
                request2.setMethod('POST');
                request2.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request2.setHeader('X-RapidAPI-Key', apiKey);
                request2.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                // Send the second request and get the response
                HttpResponse response2 = http.send(request2);
                
                // Check the response status
                if (response2.getStatusCode() == 200) {
                    String responseBody2 = response2.getBody();
                    
                    Map<String, Object> jsonResponse2 = (Map<String, Object>) JSON.deserializeUntyped(responseBody2);
                    String result2 = String.valueOf(jsonResponse2.get('result'));
                    
                    so.Tax_Amount_in_Arabic_words__c = result2;
                    so.Tax_Amount_in_English__c = Utilities.amountInWords(so.TaxableAmount__c,'Dirham','Fils');
                    
                }
                
                
            }*/
           
                
           
           
            
            if (so.NetAmount__c != null &&  so.NetAmount__c !=0 &&  so.Net_Amount_in_Arabic_Words__c==null){
                // third API request
                HttpRequest request3 = new HttpRequest();
                request3.setEndpoint(apiUrl + '?the_number=' + so.NetAmount__c + '&unit=درهم&hundreds_form=مائة');
                request3.setMethod('POST');
                request3.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request3.setHeader('X-RapidAPI-Key', apiKey);
                request3.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                // Send the second request and get the response
                HttpResponse response3 = http.send(request3);
                
                // Check the response status
                if (response3.getStatusCode() == 200) {
                    String responseBody3 = response3.getBody();
                    
                    Map<String, Object> jsonResponse3 = (Map<String, Object>) JSON.deserializeUntyped(responseBody3);
                    String result3 = String.valueOf(jsonResponse3.get('result'));
                    
                    so.Net_Amount_in_Arabic_Words__c = result3;
                    so.NetAmountInWords__c = Utilities.amountInWords(so.NetAmount__c,'Dirham','Fils');
                    
                }    
            }
            
            if (so.Net_Amount_excl_ADMWaiver__c != null &&  so.Net_Amount_excl_ADMWaiver__c != 0 && so.Net_Amount_excluding_ADM_Fee_Arabic__c==null){
                
                // fourth API request
                HttpRequest request4 = new HttpRequest();
                request4.setEndpoint(apiUrl + '?the_number=' + so.Net_Amount_excl_ADMWaiver__c + '&unit=درهم&hundreds_form=مائة');
                request4.setMethod('POST');
                request4.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request4.setHeader('X-RapidAPI-Key', apiKey);
                request4.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                HttpResponse response4 = http.send(request4);
                
                // Check the response status
                if (response4.getStatusCode() == 200) {
                    String responseBody4 = response4.getBody();
                    
                    Map<String, Object> jsonResponse4 = (Map<String, Object>) JSON.deserializeUntyped(responseBody4);
                    String result4 = String.valueOf(jsonResponse4.get('result'));
                    
                    so.Net_Amount_excluding_ADM_Fee_Arabic__c = result4;
                    
                }
                
            }
            
        }
        database.update(scope,false);
        
    }
    
    public void finish(Database.BatchableContext BC){
    }
    
}