/*****************************************************************************************
Class       : BankAccountService
Author      : Vikas Baliyan
Description : BankAccount Service class
test Class: 
Created Date: 29 JAN 2025
*****************************************************************************************/
public inherited sharing  class BankAccountService {
    
    private static BankAccountService instance;
    
    private BankAccountService() {
        
    }
    
    public static BankAccountService getInstance() { 
        if(instance == null) {
            instance = new BankAccountService();
        }
        return instance;
    }

    public List<BankAccount__c> getBankAccountByIds(Set<Id> bankIds){
        return [SELECT Id, Name, BankNameCorporate__c, AccountNumberCorporate__c, IBANNoCorporate__c, 
                SwiftCodeCorporate__c, Primary_for_Installment__c, Type__c, BeneficiaryNameCorporate__c FROM BankAccount__c WHERE Id IN: bankIds];
    }
    
    public List<BankAccount__c> getBankAccountByProjectIds(String type, String project){
        List<BankAccount__c> bankAccountList = new List<BankAccount__c>();
        bankAccountList = [SELECT Id, Name, BankNameCorporate__c, AccountNumberCorporate__c,IBANNoCorporate__c,SwiftCodeCorporate__c,BeneficiaryNameCorporate__c 
                FROM BankAccount__c 
                WHERE Type__c =: type 
                AND Project__c =: project LIMIT 1];
        return bankAccountList;
    }

    public List<BankAccount__c> getBankAccountByProject(String type, String project){
        List<BankAccount__c> bankAccList = new List<BankAccount__c>();
        bankAccList = [SELECT Id, Name, BankNameCorporate__c, AccountNumberCorporate__c,IBANNoCorporate__c,SwiftCodeCorporate__c,
                Type__c,BeneficiaryNameCorporate__c
                FROM BankAccount__c  
                WHERE Type__c =: type 
                AND Project__c =: project ];
         return bankAccList;
    }
    
    public List<BankAccount__c> getBankAccountApplicableForSales(){
        List<BankAccount__c> bankAccList = new List<BankAccount__c>();
        bankAccList = [SELECT Id, Name, BankNameCorporate__c, AccountNumberCorporate__c,IBANNoCorporate__c,SwiftCodeCorporate__c,
                Type__c,BeneficiaryNameCorporate__c FROM BankAccount__c WHERE IsApplicableforSales__c = TRUE];
         return bankAccList;
    }
    
    // Insert BankAccount__c records (trigger enabled)
    public List<BankAccount__c> insertBankAccounts(List<BankAccount__c> bankAccList){
        if(bankAccList != NULL && !bankAccList.isEmpty()){
            insert bankAccList;
        }
        return bankAccList; 
    }
    
    // BAPP Update Bank Account
    public static void updateExistingBankAccounts(List<BankAccount__c> bankAccountList){
        if(bankAccountList != null && !bankAccountList.isEmpty()){
            update bankAccountList;
        }
    }
}