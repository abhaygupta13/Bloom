public without sharing class PdfGeneratorControllerSample {
    public String requestStatus { get; set; }
    
    public PdfGeneratorControllerSample() {
        // Set the content you want to display in the PDF
        requestStatus = 'Welcome Letter';
    }
    
    public static Blob generatePdf(id recordId) {
        Case caseRecord=[select id,RecordType.Name from case where id=:recordId];
        PageReference pdfPage;
        
        if(caseRecord.RecordType.Name.contains('Move In')){
            pdfPage= Page.BCAPP_MoveInPermit;
            pdfPage.getParameters().put('Id',recordId);
        }else 
            if(caseRecord.RecordType.Name.contains('Access Permit')){
                pdfPage= Page.BCAPP_AccessPermit;
                pdfPage.getParameters().put('Id',recordId);
            }
        else{
            pdfPage= Page.BCAPP_MoveOutPermit;
            pdfPage.getParameters().put('Id',recordId);
        }
        if(Test.isRunningTest())
            return Blob.valueOf('UNIT.TEST');  
        else
            return pdfPage.getContent();
    }
    public static Blob generateSitePdf(id recordId) {
        
        APISetting__mdt  oauth;
        if(!Test.isRunningTest())  {
            oauth   = APISetting__mdt.getInstance('SiteUser');
        }
        
        else{
            oauth = new APISetting__mdt();
            oauth.URL__c = 'https://example.com/oauth';
            oauth.Client_Id__c = 'dummyClientId';
            oauth.Client_Secret__c = 'dummyClientSecret';
            oauth.Authorization__c = 'dummyUsername';
            oauth.Password__c = 'dummyPassword';
            oauth.pageRefURL__c = '/apex/yourPdfPage'  ;  
        }    
        
        String Sessionid=NULL;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oauth.URL__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        // OAuth parameters
        String requestBody = 'grant_type=password'
            + '&client_id=' + EncodingUtil.urlEncode(oauth.Client_Id__c, 'UTF-8')
            + '&client_secret=' + EncodingUtil.urlEncode(oauth.Client_Secret__c, 'UTF-8')
            + '&username=' + EncodingUtil.urlEncode(oauth.Authorization__c, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(oauth.Password__c, 'UTF-8');
        
        req.setBody(requestBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            // Parse the JSON response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Sessionid=(String) responseMap.get('access_token');
        } 
        Case caseRecord=[select id,RecordType.Name from case where id=:recordId];
       PageReference pdfPage = new PageReference(oauth.pageRefURL__c);
        


        
        PdfControllerHelper helper = new PdfControllerHelper(recordId);
        pdfPage.getHeaders().put('Authorization', 'Bearer '+Sessionid);
        if(Test.isRunningTest())
            return Blob.valueOf('UNIT.TEST');  
        else
            return pdfPage.getContent();
    }
    
}