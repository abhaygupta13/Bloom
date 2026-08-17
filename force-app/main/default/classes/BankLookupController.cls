public with sharing class BankLookupController {

    @AuraEnabled(cacheable=true)
    public static List<BankAccount__c> searchBankAccounts(String searchKey) {

        return [
            SELECT Id, Name, AccountNumberCorporate__c
            FROM BankAccount__c
            WHERE Name LIKE :('%' + searchKey + '%')
        ];
    }
}