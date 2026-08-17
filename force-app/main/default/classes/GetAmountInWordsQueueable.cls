/*****************************************************************************************
Class       : GetAmountInWordsQueueable
Author      :  Jhilik
Description : 
test Class  : GetAmountInWordsQueueableTest
Created Date: 20-Oct-2025
*****************************************************************************************/
public without sharing class GetAmountInWordsQueueable implements Queueable, Database.AllowsCallouts {
    private static final string CONVERT_NUMBER_TO_ARABIC_WORDS_API_DETAILS { get { return 'ConvertNumberToArabicWords'; } }
    private Id recordId;
    private String fieldApiName;
    private Decimal  numberValue;

    public GetAmountInWordsQueueable(Id recordId, String fieldApiName, Decimal numberValue) {
        this.recordId = recordId;
        this.fieldApiName = fieldApiName;
        this.numberValue = numberValue;
    }

    public void execute(QueueableContext context) {
        
        SObject sObj = recordId.getSObjectType().newSObject(recordId);
        sObj.put('Id', recordId);
        sObj.put(fieldApiName, getAmountInArabicWords(numberValue));
        update sObj;
    }

    public String getAmountInArabicWords(Decimal amount){
        String result = '';

        MetadataService objMetadataService = MetadataService.getInstance();
        List<Integration_Details__mdt> customMetadataRecord = objMetadataService.getIntegrationDetailsMetadataByDevName(CONVERT_NUMBER_TO_ARABIC_WORDS_API_DETAILS);

        String apiUrl = customMetadataRecord[0].End_Point_URL__c;
        String apiKey = customMetadataRecord[0].Api_Key__c;
        String methodType = customMetadataRecord[0].MethodType__c;

        // Create an HTTP object to send requests
        Http http = new Http();
        HttpRequest request1 = new HttpRequest();
        request1.setEndpoint(apiUrl + '?the_number=' + amount + '&unit=درهم&hundreds_form=مائة');
        request1.setMethod(methodType);
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
            result = String.valueOf(jsonResponse1.get('result'));
        }
        return result;
    }
}