//============================ BCAPP_BusinessRuleValidator =============================
/*
* @Author : Eagles
* @CreatedDate : 23rd OCT 2023
* @Name : BCAPP_BusinessRuleValidator
* @Description : This Apex class provides utility methods to send emails and SMS messages using the Infobip API. 
 *                The class includes methods for handling HTTP requests to send out email and SMS notifications 
 *                with various customization options like placeholders, custom headers, and callback URLs.
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               11 NOV 2023        Initial draft 
*****************************************************************************************************/


public without sharing class SMS_Service {
    
        // Method to send SMS
    public static void sendEmail(String emailAddress, String messageBody) {

        // Set the endpoint URL
        String endpointUrl = 'https://https://m32dp4.api.infobip.com/email/3/send';
        
        // Prepare the request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'from' => 'Jane Smith <jane.smith@somecompany.com>',
            'to' => new List<String>{
                'emailtocaseda',
                'alice.smith@somedomain.com',
                '{"to": "alice.grey@somecompany.com", "placeholders": {"Name":"John Doe"}}'
            },
            'replyTo' => 'all.replies@somedomain.com',
            'subject' => 'Mail subject text and placeholder ph1',
            'text' => 'Dear {{name}}, this is mail body text with placeholders in body {{ph1}} and {{ph2}}',
            'html' => '<h1>Html body</h1><p>Rich HTML message body.</p>',
            'bulkId' => 'customBulkId',
            'intermediateReport' => true,
            'defaultPlaceholders' => '{"ph1": "Success", "ph2": "Example"}',
            'headers' => '{"X-Custom-Header": "HeaderValue"}',
            'notifyUrl' => 'https://www.example.com/email/advanced',
            'notifyContentType' => 'application/json',
            'callbackData' => 'DLR callback data'
        };
        
        // Create a new Http object
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        
        // Set headers
        request.setHeader('Authorization', 'Basic {base64_encoded_username:password}');
        request.setHeader('Content-Type', 'application/json');
        
        // Serialize the request body to JSON
        request.setBody(JSON.serialize(requestBody));
        
        // Send the request and handle the response
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                System.debug(response.getBody());
            } else {
                System.debug('Unexpected HTTP status: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
    
    // Method to send SMS
    @future(callout=true)
    public static void sendSMS(String toPhoneNumber, String messageText) {
        // Create the Map structure for the payload
        Map<String, Object> messageMap = new Map<String, Object>();
        APISetting__mdt  APIInstance = APISetting__mdt.getInstance('Infobip_SMS');

        // Channel and sender details
        messageMap.put('channel', 'SMS');
        messageMap.put('sender', APIInstance.Client_Id__c);
        
        // Destination information
        List<Map<String, String>> destinations = new List<Map<String, String>>();
        Map<String, String> destinationMap = new Map<String, String>();
        destinationMap.put('to', toPhoneNumber);
        destinations.add(destinationMap);
        messageMap.put('destinations', destinations);
        
        // Message content
        Map<String, Object> contentMap = new Map<String, Object>();
        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('text', messageText);
        bodyMap.put('type', 'TEXT');
        contentMap.put('body', bodyMap);
        messageMap.put('content', contentMap);
        
        // Wrap everything in a root map
        Map<String, Object> rootMap = new Map<String, Object>();
        rootMap.put('messages', new List<Map<String, Object>>{messageMap});
        
        // Convert the Map to JSON string
        String payload = JSON.serialize(rootMap);
        
        // Prepare the endpoint URL
        String url = APIInstance.URL__c;//'https://m32dp4.api.infobip.com/messages-api/1/messages';
        
        // Create a new HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', APIInstance.Authorization__c);//'App e53df339a6177598d5b9364cd9144169-1d80352b-11ce-4540-9a6a-391c92e77ef5');
        req.setBody(payload);
        
        // Create an HTTP client to send the request
        Http http = new Http();
        
        try {
            // Send the request
            HttpResponse res = http.send(req);
            // Handle the response (log it, debug it, or process accordingly)
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            // Handle any exceptions
            System.debug('Error sending SMS: ' + e.getMessage());
        }
    }
}