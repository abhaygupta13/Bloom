@isTest
private class WebServiceUtilityTest {
    @isTest
    static void testDoPost_GenerateAndSendOTP_Valid() {
        
        // Prepare JSON request body
        String body = JSON.serialize(new Map<String, Object>{
            'processType' => 'Registration',
            'commType' => 'Email',
            'transactionId' => '12345678',
            'email' => 'test@test.com',
            'phoneNumber' => '8888888888',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(body);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    static void testDoPost_VerifyOTP_Valid() {
        
        // Prepare JSON request body
        String body = JSON.serialize(new Map<String, Object>{
            'otpValue' => '1111',
            'transactionId' => '12345678'
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(body);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

    }
    @isTest
    static void testDoPost_UploadDocuments_Valid() {
        
        // Prepare JSON request body
        String body = JSON.serialize(new Map<String, Object>{
            'currentScreen'=> 'screen 5',
            'applicationId'=> 'a4XKI000000Go0p2AC',
            'isRfiUpdate'=>true,
            'registrationStatus'=> 'Draft',
            'documents'=> new List<Object>{
                new Map<String, Object>{
                    'category'=> 'Application',
                    'objectType'=>'Broker Application',
                    'parentId'=> 'a4XKI000000Go0p2AC',
                    'role'=> null,
                    'documentType'=> 'Trade License',
                    'fileName'=> 'trade_license6.pdf',
                    'fileType'=> 'pdf',
                    'fileSizeMB'=> 2.5,
                    'fileContent'=> '123'
                }
            }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/UploadDocuments';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(body);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

    }
    @isTest
    static void testDoPost_UnsupportedEndpoint() {
        // Simulate unsupported endpoint
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unknownEndpoint';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{}');

        Test.startTest();
        BAPPWebService.doPost();  
        Test.stopTest();

        // No assert needed — just ensuring it doesn’t crash
    }
}