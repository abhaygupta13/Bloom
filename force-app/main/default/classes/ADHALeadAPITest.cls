/*****************************************************************************************
Class       : ADHALeadAPITest
Author      : Prashant Sahu
Description : ADHALeadAPI Test Class
Test Class  :
Created Date: 05 AUG 2026
*****************************************************************************************/
@isTest
public class ADHALeadAPITest {
    @isTest 
    static void testPostPositive() {
       
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/ADHALeadAPI';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf( '{"ApplicationNumber":"APP123456",' + '"Status":"Init",' + '"Applicant":{' + '"Name":"Ali",' + '"FamilyName":"Al Mansoori",' + '"EID":"784-1987-1234567-1",' + '"PhoneNumber":"0501234567",' + '"Email":"ali.mansoori@example.com",' + '"Tribe":"Al Mansoori",' + '"Gender":"Male",' + '"DOB":"1987-05-15",' + '"MaritalStatus":"Married",' + '"NumberOfWives":1,' + '"NumberOfChildren":3,' + '"Salary":120000.00,' + '"TownName":"Abu Dhabi"' + '},' + '"LoanValue":1750000,' + '"Project":{' + '"ProjectID":"PRJ001",' + '"Municipality":"Abu Dhabi Municipality",' + '"Region":"Central",' + '"District":"Al Bateen"' + '}' + '}');
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            Test.startTest();
        //    ADHALeadAPI.createLead();
        
                                ADHALeadAPI.Response response = ADHALeadAPI.createLead();
                            //    Lead l = [ SELECT ApplicationNumber__c, LoanAmount__c, Municipality__c, Region__c, District__c, Authority__c FROM Lead];
                                System.debug(response.code);
                                System.debug(response.message);     
                                System.assertEquals(200, response.code, response.message);
                                
                              /*  System.assertEquals('APP123456', l.ApplicationNumber__c);
                                System.assertEquals('Abu Dhabi Municipality', l.Municipality__c);
                                System.assertEquals('Central', l.Region__c);
                                System.assertEquals('Al Bateen', l.District__c);*/
            Test.stopTest(); 
    }
    
    @isTest 
    static void testPostNegative() {
       
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/ADHALeadAPI';
            req.httpMethod = 'POST';
           req.requestBody = Blob.valueOf( '{"Status":"Init",' + '"Applicant":{' + '"Name":"Ali",' + '"FamilyName":"Al Mansoori",' + '"EID":"784-1987-1234567-1",' + '"PhoneNumber":"0501234567",' + '"Email":"ali.mansoori@example.com",' + '"Tribe":"Al Mansoori",' + '"Gender":"Male",' + '"DOB":"1987-05-15",' + '"MaritalStatus":"Married",' + '"NumberOfWives":1,' + '"NumberOfChildren":3,' + '"Salary":120000.00,' + '"TownName":"Abu Dhabi"' + '},' + '"LoanValue":1750000,' + '"Project":{' + '"ProjectID":"PRJ001",' + '"Municipality":"Abu Dhabi Municipality",' + '"Region":"Central",' + '"District":"Al Bateen"' + '}' + '}' );
           RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            Test.startTest();
            //ADHALeadAPI.createLead();
        
                                ADHALeadAPI.Response response = ADHALeadAPI.createLead();
                                System.debug(response.code);
                                System.debug(response.message);     
                                System.assertEquals(500, response.code, response.message);
                                
                            
            Test.stopTest(); 
    }
   
}