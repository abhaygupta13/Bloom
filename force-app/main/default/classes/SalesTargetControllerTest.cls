/*****************************************************************************************
Class       : SalesTargetController Test
Author      : Vikas Baliyan
Description : SalesTargetController Test
Test Class  : 
Created Date: 07 JAN 2025 
*****************************************************************************************/
@isTest
public class SalesTargetControllerTest {
    @TestSetup
    static void testData(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueEmail = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        String uniqueEmail2 = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        String uniqueEmail3 = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        User user = TestDataFactory.createUser(p.Id, uniqueEmail, uniqueEmail, 'test', 'user');
        User user2 = TestDataFactory.createUser(p.Id, uniqueEmail2, uniqueEmail2, 'test2', 'user');
        User user3 = TestDataFactory.createUser(p.Id, uniqueEmail3, uniqueEmail3, 'test3', 'user');
        List<User> userList = new List<User>();
        userList.add(user); userList.add(user2); userList.add(user3);
        insert userList; 
        SalesTarget__c target = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail, 500000, 500000, '2025', 'Q1');
        SalesTarget__c target2 = TestDataFactory.createSalesTarget('Q2_2025_'+uniqueEmail2, 500000, 500000, '2025', 'Q2');
        SalesTarget__c target3 = TestDataFactory.createSalesTarget('Q3_2025_'+uniqueEmail3, 500000, 500000, '2025', 'Q3');
        List<SalesTarget__c> salesTargetList = new List<SalesTarget__c>();
        salesTargetList.add(target); salesTargetList.add(target2); salesTargetList.add(target3);
        insert salesTargetList;
    }

    @IsTest
    static void testCreateSalesTarget(){
        List<SalesTarget__c> salesTargetList = [SELECT Id, ExternalIdentifier__c, DirectTargetAmount__c, IndirectTargetAmount__c, Year__c, Quarter__c FROM SalesTarget__c];
        salesTargetList[0].DirectTargetAmount__c = 600000;
        salesTargetList[1].DirectTargetAmount__c = 600000;
        salesTargetList[2].DirectTargetAmount__c = 600000;
        Test.startTest();
           SalesTargetController.createSalesTarget(salesTargetList);
        Test.stopTest();
        List<SalesTarget__c> updatedSalesTargetList = [SELECT Id, SalesManager__c,ExternalIdentifier__c, DirectTargetAmount__c, IndirectTargetAmount__c, Year__c, Quarter__c FROM SalesTarget__c];
        Assert.areEqual(updatedSalesTargetList[0].DirectTargetAmount__c, 600000, 'Record not updated');
        Assert.areEqual(updatedSalesTargetList[1].DirectTargetAmount__c, 600000, 'Record not updated');
    }
    @IsTest
    static void testGetUsersByEmails(){
        String uniqueEmail = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = TestDataFactory.createUser(p.Id, uniqueEmail, uniqueEmail, 'test1234', 'user1234');
        insert user;
        Test.startTest();
            Map<String, String> emailToNameMap = SalesTargetController.getUsersByEmails( new List<String>{uniqueEmail});
        Test.stopTest();
        Assert.areEqual(emailToNameMap.size(), 1, 'Record not found');

    }
}