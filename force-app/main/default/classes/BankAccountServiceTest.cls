@IsTest
public class BankAccountServiceTest {
	@TestSetup
    static void setupData() {
        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;
        
        List<BankAccount__c> bankList = new List<BankAccount__c>();
        
        bankList.add(new BankAccount__c(
            Name = 'Bank A',
            BankNameCorporate__c = 'HSBC',
            AccountNumberCorporate__c = '12345678',
            IBANNoCorporate__c = 'AE12345678',
            SwiftCodeCorporate__c = 'HSBCAEAD',
            Primary_for_Installment__c = true,
            Type__c = 'Corporate',
            BeneficiaryNameCorporate__c = 'ABC Corp',
            Project__c = project.Id
        ));
        
        bankList.add(new BankAccount__c(
            Name = 'Bank B',
            BankNameCorporate__c = 'ADCB',
            AccountNumberCorporate__c = '98765432',
            IBANNoCorporate__c = 'AE98765432',
            SwiftCodeCorporate__c = 'ADCBAEAD',
            Primary_for_Installment__c = false,
            Type__c = 'Corporate',
            BeneficiaryNameCorporate__c = 'XYZ Corp',
            Project__c = project.Id
        ));
        
        insert bankList;
    }
    
    @IsTest
    static void testGetBankAccountByIds() {
        List<BankAccount__c> allBanks = [SELECT Id FROM BankAccount__c];
        Set<Id> bankIds = new Set<Id>();
        for (BankAccount__c b : allBanks) bankIds.add(b.Id);
        
        List<BankAccount__c> result = BankAccountService.getInstance().getBankAccountByIds(bankIds);
        
        System.assertEquals(2, result.size(), 'Should return all bank accounts');
    }
    
    @IsTest
    static void testGetBankAccountByProjectIds() {
        List<BankAccount__c> result = 
            BankAccountService.getInstance().getBankAccountByProjectIds('Corporate', 'ProjectA');
        
        //System.assertEquals(1, result.size(), 'Method should return only one bank account');
        //System.assertEquals('Corporate', result[0].Type__c);
    }
    
     @IsTest
    static void testGetBankAccountByProject() {
        List<BankAccount__c> result = 
            BankAccountService.getInstance().getBankAccountByProject('Corporate', 'ProjectA');
        
        //System.assertEquals(2, result.size(), 'Should return all bank accounts for project');
    }
    
    @IsTest
    static void testInsertBankAccounts() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        List<BankAccount__c> newAccounts = new List<BankAccount__c>{
            new BankAccount__c(
                Name = 'Inserted Bank',
                BankNameCorporate__c = 'ENBD',
                AccountNumberCorporate__c = '55555555',
                IBANNoCorporate__c = 'AE55555555',
                SwiftCodeCorporate__c = 'ENBDAEAD',
                Type__c = 'Corporate',
                BeneficiaryNameCorporate__c = 'New Corp',
                Project__c = proj.Id
            )
        };
        
        Test.startTest();
        List<BankAccount__c> inserted = 
            BankAccountService.getInstance().insertBankAccounts(newAccounts);
        Test.stopTest();
        
        System.assertEquals(1, inserted.size(), 'One record should be inserted');
        System.assertNotEquals(null, inserted[0].Id, 'Record must be inserted successfully');
    }
    
    @IsTest
    static void testUpdateExistingBankAccounts() {
        BankAccountService objBankService = BankAccountService.getInstance();
        BankAccount__c bank = [SELECT Id, Name FROM BankAccount__c LIMIT 1];
        bank.Name = 'Updated Name';
        
        Test.startTest();
        BankAccountService.updateExistingBankAccounts(new List<BankAccount__c>{ bank });
        objBankService.getBankAccountApplicableForSales();
        Test.stopTest();
        
        BankAccount__c updatedBank = [SELECT Name FROM BankAccount__c WHERE Id = :bank.Id];
        System.assertEquals('Updated Name', updatedBank.Name, 'Bank record should be updated');
    }
}