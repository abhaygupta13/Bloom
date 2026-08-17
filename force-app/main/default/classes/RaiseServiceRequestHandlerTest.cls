@isTest
public class RaiseServiceRequestHandlerTest {
    
    @isTest static void RaiseServiceRequestHandlerTestMethod(){
          Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
         Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
        
        Profile profileDetail1 = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
       
       
        
         
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
         User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;

        User userRecord3 = new User(Alias = 'Zaki3', Email='Zakial3@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3432'+'@mail.com');
        insert userRecord3;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Round_Robin_User__c rrUser2=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=Reseller.Id,
            Total_Open_Count__c=10,
            User__c=userRecord3.id
            
        );
        insert rrUser2;
        
        

      Id ResalecaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale').getRecordTypeId();
       Id OthercaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Financial_Services').getRecordTypeId();
      
        
        
        
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
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        Unit__c testUnit1=new Unit__c(
            Name='test Unit1',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit1;
        
        
        
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.CustomerSubType__c ='CORPORATE';
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        
        
        
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@tesrt.com',
            CustomerSubType__c ='CORPORATE'
            
        );
        insert tempAcc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        
        
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
         ReceiptAcknowledgement__c testRecAck= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            ReferenceNumber__c='456732',
            SalesOrder__c=testOrder.id,
            Amount__c=100
        );
        insert testRecAck;
        
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            SalesOrder__c=testOrder.id,
            PaymentType__c='Cheque',
            Amount__c=100
            );
        
        case ca= new case();
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale').getRecordTypeId();
        ca.Type = 'Transfer of Right';
        ca.Status = 'New';
         ca.Case_Sub_Status__c = 'Created';
        ca.Sales_Order__c = testOrder.id;
          
        Service_Request_Lines__c sr = new Service_Request_Lines__c();
        sr.Case__c =ca.Id;
        sr.New_Maturity_Date__c =system.today();
        
        SalesOrderOtherCharges__c sot = new SalesOrderOtherCharges__c();
        sot.Amount__c = 200;
        sot.SalesOrder__c=testOrder.id;
        sot.TypeOfCharge__c='ADM Fee';

      JointOwner__c jo = new JointOwner__c();
     jo.Account__c = tempAcc.id;
     jo.SharePercentage__c = 50;
     jo.SalesOrder__c = testOrder.id;
     Insert jo;

     List<string> jostri = new List<string>();
     jostri.add(string.valueof(jo.id));

     Test.startTest();
        RaiseServiceRequestHandler.validationOnReceitpMaturityDate(testRecAck.id,date.today());
        RaiseServiceRequestHandler.getreceipts(testOrder.id);
      RaiseServiceRequestHandler.createCaseComplaint('Sales Complaint','','Assigned', 'Poor Knowledge',null,null,testOrder.id,'Hani Zaki Al Bakri',new SalesOrderOtherCharges__c());
       RaiseServiceRequestHandler.createCaseGeneral('Special Services','','Assigned','Upgrade',null,null,testOrder.id,sot,jostri);
       RaiseServiceRequestHandler.CreateCaseWithServiceReqLines(ca,new list<Service_Request_Lines__c>{sr},'Resale');
       RaiseServiceRequestHandler.getPicklistFieldValueOnCaseRecordType('Sales Complaint');  
        RaiseServiceRequestHandler.getCaseRecordTypes(); 
      Test.stopTest();
       RaiseServiceRequestHandler.getDefaultUserOnCaseSubType('Sales Complaint','Poor Knowledge');
        RaiseServiceRequestHandler.getSalesordetailonRecord(testOrder.id);
       RaiseServiceRequestHandler.caseduplicationcheck(testOrder.id,'Sales Complaint','Poor Knowledge');
        RaiseServiceRequestHandler.getSalesorderJointOwner(testOrder.id);
    }

}