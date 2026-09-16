/*****************************************************************************************
Class       : ADHALeadAPITest
Author      : Prashant Sahu
Description : ADHALeadAPI Test Class
Test Class  :
Created Date: 05 AUG 2026
*****************************************************************************************/


@isTest
public class ADHALeadAPITest {
  /*  @isTest 
    static void testPostPositive() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ADHALeadAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{\"ApplicationNumber\":\"APP123456\",\"Status\":\"Init\",\"Applicant\":{\"Name\":\"Ali\",\"FamilyName\":\"Al Mansoori\",\"EID\":\"784-1987-1234567-1\",\"PhoneNumber\":\"0501234567\",\"Email\":\"ali.mansoori@example.com\",\"Tribe\":\"Al Mansoori\",\"Gender\":\"Male\",\"DOB\":\"1987-05-15\",\"MaritalStatus\":\"Married\",\"NumberOfWives\":1,\"NumberOfChildren\":3,\"Salary\":120000.00,\"TownName\":\"Abu Dhabi\"},\"Project\":{\"ProjectID\":\"PRJ001\",\"Municipality\":\"Abu Dhabi Municipality\",\"Region\":\"Central\",\"District\":\"Al Bateen",\"LoanValue\":\"850000\" },\"Notes\":{\"Authority\":\"ADHA Central Authority\"}} ');
        
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        ADHALeadAPI.createLead();
        
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        System.assertEquals(200, response.code, response.message);
        Test.stopTest(); 
    }*/
      @testSetup
    static void setupData() {
        
         User contactCenterUser = [
        SELECT Id
        FROM User
        WHERE Profile.Name = 'Contact Centre Team'
        AND IsActive = true
        LIMIT 1
    ];

    List<BusinessHours> bhs = [
        SELECT Id
        FROM BusinessHours
        WHERE IsActive = true
        LIMIT 1
    ];

    AssignmentRule__c assr7 = new AssignmentRule__c(
        RecordType__c = 'Lead',
        ProcessName__c = 'ADHA Lead Assignment',
        ProcessType__c = 'Sales',
        IsActive__c = true
    );
    insert assr7;

    AssignmentUser__c assru6 = new AssignmentUser__c(
        AssignmentRule__c = assr7.Id,
        User__c = contactCenterUser.Id,
        BusinessHours__c = bhs[0].Id,
        IsActive__c = true
    );
    insert assru6;
        // Create Project for ADHA API
        Project__c testProject = new Project__c(
            Name = 'Al Metlaa',
            ADHAProjectID__c = 'PRJ001'
        );
        insert testProject;
    }
    
      @isTest
    static void testPostPositive() {

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ADHALeadAPI';
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueOf(
        '{' +
        '"ApplicationNumber":"APP123456",' +
        '"Status":"Init",' +
        '"Applicant":{' +
            '"Name":"Ali",' +
            '"FamilyName":"Al Mansoori",' +
            '"EID":"784-1987-1234567-1",' +
            '"PhoneNumber":"0501234567",' +
            '"Email":"ali.mansoori@example.com",' +
            '"Tribe":"Al Mansoori",' +
            '"Gender":"Male",' +
            '"DOB":"1987-05-15",' +
            '"MaritalStatus":"Married",' +
            '"NumberOfWives":1,' +
            '"NumberOfChildren":3,' +
            '"Salary":120000.00,' +
            '"TownName":"Abu Dhabi"' +
        '},' +
        '"Project":{' +
            '"ProjectID":"PRJ001",' +
            '"Municipality":"Abu Dhabi Municipality",' +
            '"Region":"Central",' +
            '"District":"Al Bateen",' +
            '"LoanValue":"850000"' +
        '},' +
        '"Notes":{' +
            '"Authority":"ADHA Central Authority"' +
        '}' +
        '}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();

       

       // System.assertEquals(500, response.code, response.message);

       
        
    }
      
    @isTest 
    static void testPostNegative() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ADHALeadAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{\"ApplicationNumber\":\"APP123456\",\"Status\":\"Init\",\"Applicant\":{\"Name\":\"Ali\",\"FamilyName\":\"Al Mansoori\",\"EID\":\"784-1987-1234567-1\",\"PhoneNumber\":\"0501234567\",\"Email\":\"ali.mansoori@example.com\",\"Tribe\":\"Al Mansoori\",\"Gender\":\"Male\",\"DOB\":\"1987-05-15\",\"MaritalStatus\":\"Married\",\"NumberOfWives\":1,\"NumberOfChildren\":3,\"Salary\":120000.00,\"TownName\":\"Abu Dhabi\"},\"Project\":{\"ProjectID\":\"PRJ001\",\"Municipality\":\"Abu Dhabi Municipality\",\"Region\":\"Central\",\"District\":\"Al Bateen"},\"Notes\":{\"Authority\":\"ADHA Central Authority\"}} ');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();  
        Test.stopTest(); 
    }
    @isTest 
    static void testPostNegative1() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ADHALeadAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{ "ApplicationNumber": "APP-UAT-10002", "Applicant": { "Name": "Ahmed", "Tribe": "ALKATHEERI", "FamilyName": "Alketheeri", "Gender": "Male", "EID": "784199012345678", "DOB": "1996-07-26", "MaritalStatus": "Married", "TownName": "Abu Dhabi", "NumberOfWives": 1, "NumberOfChildren": 0, "Salary": 45000, "PhoneNumber": "971501234567", "Email": "uat.test10001@example.com" }, "LoanValue": 1750000, "Project": { "ProjectID": "H-41-1311-01", "Municipality": "Abu Dhabi City", "Region": "10" }, "Status": "Init" }');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();  
        Test.stopTest(); 
    }
}