/***
Class       : CalloutQueueable
Author      : Smaartt
Description : 
TestClass   : CalloutQueueableTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/07/23           Initial Version 
2.          v2.0              19/01/24           updated null check and added Number in English Words.           
****************************************************************************************************************/

public class CalloutQueueable implements Queueable, Database.AllowsCallouts {
    private String apiUrl;
    private String apiKey;
    private Id salesorderId;
    
    public CalloutQueueable(String apiUrl, String apiKey, Id salesorderId) {
        this.apiUrl = apiUrl;
        this.apiKey = apiKey;
        this.salesorderId = salesorderId;
    }
    
    public void execute(QueueableContext context) {
        // Fetch the Sales Order record
        List<Salesorder__c> salesorderList = [SELECT Id, Sales_Order_Received_Amount__c, SalesorderAmountRecivedinArabic__c, Sales_Price_Excluding_ADM_Arabic__c,
                                                Sales_Price_Excluding_ADMs__c,Net_Amount_excluding_ADM_Fee_Arabic__c,Net_Amount_in_Arabic_Words__c,
                                                Tax_Amount_in_Arabic_words__c,Tax_Amount_in_English__c, AmountPayable__c,Amount_Payable_in_English__c,
                                                Number_in_words_Arabic__c, TaxableAmount__c, NetAmount__c, Net_Amount_excl_ADMWaiver__c, SellingPrice__c, 
                                                SellingPriceInArabicWords__c
                                                FROM Salesorder__c WHERE Id = :salesorderId];
        
        // Create an HTTP object to send requests
        Http http = new Http();
        try {
            if(!salesorderList.isEmpty()){
                // First API request
                if (salesorderList[0].AmountPayable__c != null && salesorderList[0].AmountPayable__c!=0 && salesorderList[0].Number_in_words_Arabic__c==null){
                    HttpRequest request1 = new HttpRequest();
                    request1.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].AmountPayable__c + '&unit=درهم&hundreds_form=مائة');
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
                        
                        salesorderList[0].Number_in_words_Arabic__c = result1;
                        salesorderList[0].Amount_Payable_in_English__c = Utilities.amountInWords(salesorderList[0].AmountPayable__c,'Dirham','Fils');
                        System.debug(salesorderList[0].Number_in_words_Arabic__c);
                    }    
                }
                
                if (salesorderList[0].TaxableAmount__c != null && salesorderList[0].TaxableAmount__c != 0 &&  salesorderList[0].Tax_Amount_in_Arabic_words__c==null){
                    
                    // Second API request
                    HttpRequest request2 = new HttpRequest();
                    request2.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].TaxableAmount__c + '&unit=درهم&hundreds_form=مائة');
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
                        
                        salesorderList[0].Tax_Amount_in_Arabic_words__c = result2;
                        salesorderList[0].Tax_Amount_in_English__c = Utilities.amountInWords(salesorderList[0].TaxableAmount__c,'Dirham','Fils');
                        
                    }
                    
                    
                }
                
                if (salesorderList[0].NetAmount__c != null &&  salesorderList[0].NetAmount__c !=0 &&  salesorderList[0].Net_Amount_in_Arabic_Words__c==null){
                    // third API request
                    HttpRequest request3 = new HttpRequest();
                    request3.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].NetAmount__c + '&unit=درهم&hundreds_form=مائة');
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
                        
                        salesorderList[0].Net_Amount_in_Arabic_Words__c = result3;  
                    }    
                }
                
                if (salesorderList[0].Net_Amount_excl_ADMWaiver__c != null &&  salesorderList[0].Net_Amount_excl_ADMWaiver__c != 0 && salesorderList[0].Net_Amount_excluding_ADM_Fee_Arabic__c==null){
                    
                    // fourth API request
                    HttpRequest request4 = new HttpRequest();
                    request4.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].Net_Amount_excl_ADMWaiver__c + '&unit=درهم&hundreds_form=مائة');
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
                        
                        salesorderList[0].Net_Amount_excluding_ADM_Fee_Arabic__c = result4;
                        
                    }
                    
                }
            
            if (salesorderList[0].Sales_Price_Excluding_ADMs__c != null &&  salesorderList[0].Sales_Price_Excluding_ADMs__c != 0 && salesorderList[0].Sales_Price_Excluding_ADM_Arabic__c==null){
                    
                    // fourth API request
                    HttpRequest request5 = new HttpRequest();
                    request5.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].Sales_Price_Excluding_ADMs__c + '&unit=درهم&hundreds_form=مائة');
                    request5.setMethod('POST');
                    request5.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                    request5.setHeader('X-RapidAPI-Key', apiKey);
                    request5.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                    
                    HttpResponse response5 = http.send(request5);
                    
                    // Check the response status
                    if (response5.getStatusCode() == 200) {
                        String responseBody5 = response5.getBody();
                        
                        Map<String, Object> jsonResponse5 = (Map<String, Object>) JSON.deserializeUntyped(responseBody5);
                        String result5 = String.valueOf(jsonResponse5.get('result'));
                        
                        salesorderList[0].Sales_Price_Excluding_ADM_Arabic__c = result5;
                        
                    }
                    
                }
            }
            if (salesorderList[0].Sales_Order_Received_Amount__c != null &&  salesorderList[0].Sales_Order_Received_Amount__c != 0 ){
                    
                // fourth API request
                HttpRequest request6 = new HttpRequest();
                request6.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].Sales_Order_Received_Amount__c + '&unit=درهم&hundreds_form=مائة');
                request6.setMethod('POST');
                request6.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request6.setHeader('X-RapidAPI-Key', apiKey);
                request6.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                HttpResponse response6 = http.send(request6);
                
                // Check the response status
                if (response6.getStatusCode() == 200) {
                    String responseBody6 = response6.getBody();
                    
                    Map<String, Object> jsonResponse6 = (Map<String, Object>) JSON.deserializeUntyped(responseBody6);
                    String result6 = String.valueOf(jsonResponse6.get('result'));
                    
                    salesorderList[0].SalesorderAmountRecivedinArabic__c = result6;
                    
                }
                
            }

            if (salesorderList[0].SellingPrice__c != null &&  salesorderList[0].SellingPrice__c != 0){
                    
                // fifth API request
                HttpRequest request5 = new HttpRequest();
                request5.setEndpoint(apiUrl + '?the_number=' + salesorderList[0].Net_Amount_excl_ADMWaiver__c + '&unit=درهم&hundreds_form=مائة');
                request5.setMethod('POST');
                request5.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request5.setHeader('X-RapidAPI-Key', apiKey);
                request5.setHeader('X-RapidAPI-Host', 'tafqit.p.rapidapi.com');
                
                HttpResponse response5 = http.send(request5);
                
                // Check the response status
                if (response5.getStatusCode() == 200) {
                    String responseBody4 = response5.getBody();
                    
                    Map<String, Object> jsonResponse5 = (Map<String, Object>) JSON.deserializeUntyped(responseBody4);
                    String result5 = String.valueOf(jsonResponse5.get('result'));
                    
                    salesorderList[0].SellingPriceInArabicWords__c = result5;
                    
                }
                
            }
            
            // Update the Sales Order record
            update salesorderList;
        } catch (Exception e) {
            // Handle any exceptions here
            System.debug('Exception: ' + e.getMessage());
        }
    }
}