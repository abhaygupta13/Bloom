@isTest
public class ResaleEmailActionControllerTest {
    @istest
    static void testmethod1(){
        Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account Acc = new Account();
        Acc.LastName__pc = 'Test class Account';
        Acc.LastName = 'Test class Account';
        Acc.PersonEmail='aaa@abc.com';
        Acc.PersonMobilePhone='123456789';
        //Address or Mobile Numbe
        Acc.RecordTypeId = personRecId;
        insert Acc;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@gmail.com'
        );
        insert testContact;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test class name';
        opp.AccountId = Acc.id;
        opp.CloseDate = system.today();
        opp.StageName = 'New';
        opp.ForecastCategoryName = 'Omitted';
        opp.LeadChannel__c = 'Call';
        opp.WinReason__c = 'Won - Special Discount';
        insert opp;
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000
        );
        insert testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            // Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = Acc.Id,
            Opportunity__c=Opp.Id            
        );
        insert testOrder;
        
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            AccountId = Acc.id,
            NewCustomerAccount__c = Acc.id,
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.Id,
            ContactId = testContact.Id
        );
        
        insert tempCase;
        
        Account tempAcc=new Account(
            Name='test'
        );
        insert tempAcc;
        
        Account newPersonAcc = new Account(
            LastName = 'Second Buyer',
            RecordTypeId = personRecId,
            PersonEmail = 'secondbuyer@test.com',
            PersonMobilePhone = '987654321'
        );
        insert newPersonAcc;
        
        JointOwner__c tempJointOwner=new JointOwner__c(
            Account__c=tempAcc.id,
            SharePercentage__c=40,
            Case__c=tempCase.id
        );
        insert tempJointOwner;
        Case tempCase1 =new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id,
            ContactId = testContact.Id,
            AccountId = Acc.id,
            ResaleToCompleteAmount__c = 1000,
            NewCustomerAccount__c = newPersonAcc.id,
             ADMTotalFees__c = 20,
    ADMAdminFees__c = 30,
    EvaluationFees__c = 50,
    MortgageRegistrationFees__c = 50,
    ADMFees__c = 100,
    BouncedChequeFees__c = 10,
    LatePaymentFees__c = 100,
    CancellationFees__c = 100,
    ChequeWithWithdrawlFees__c = 100
    
        );   
        insert tempCase1;
        List<ResaleEmailActionController.EmailTemplateInfo> lstTemplateInfo = ResaleEmailActionController.getEmailTemplates();
        ResaleEmailActionController.getEmailBody(lstTemplateInfo[0].id, tempCase1.Id);
        ResaleEmailActionController.sendEmailUsingTemplate(tempCase1.Id, 'Test', 'Test','test@gmail.com','test@gmail.com');
    }
}