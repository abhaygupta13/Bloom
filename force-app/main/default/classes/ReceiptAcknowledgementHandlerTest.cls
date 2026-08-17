@isTest
public class ReceiptAcknowledgementHandlerTest {
    @isTest static void ReceiptAcknowledgementHandlerTestMethod(){
        
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
            Project__c=testProject.Id
        );
        insert testUnit;
        
        Account tempAcc=new Account(
            Name ='test'
        );
        insert tempAcc;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c =tempAcc.Id
        );
        insert testOrder;
        
        PaymentPlan__c tempPayPlan=new PaymentPlan__c(
            Name='Test Payment',
            Description__c='test'
            
        );
        insert tempPayPlan;
        
        PaymentInstallments__c tempPayInstall=new PaymentInstallments__c(
            InstallmentNumber__c=1,
            PaymentPlan__c=tempPayPlan.id,
            InstallmentPercentage__c=10,
            Description__c='test',
            Condition_Type__c='P012'
        );
        insert tempPayInstall;
        
        InstallmentLines__c tempInstLines= new InstallmentLines__c(
            SalesOrder__c=testOrder.id,
            Description__c='test',
            PaymentInstallments__c=tempPayInstall.id,
            PaymentPlan__c=tempPayPlan.Id,
            AmountReceived__c=200,
            InstallmentAmount__c=2000
        );
        insert tempInstLines;
        
        Document__c newDoc=new Document__c();
        newDoc.Document_Name__c='Test';
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id
        );
        insert tempOpp;
        ReceiptAcknowledgement__c testRecAck= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            SalesOrder__c=testOrder.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            ReferenceNumber__c='456732',
            Account__c=tempAcc.id
        );
        insert testRecAck;
        
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            Account__c=tempAcc.id,
            ReferenceNumber__c = '435678',
            SalesOrder__c = testOrder.id
        );
        
        
        ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c =testRecAck.id;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = testOrder.id;
        newReceiptAllocation.Account__c = tempAcc.id;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        
        
        SalesOrderOtherCharges__c tempOtherCharge=new SalesOrderOtherCharges__c(
            SalesOrder__c=testOrder.Id,
            Account__c=tempAcc.Id,
            Amount__c=1000,
            TypeOfCharge__c='ADM Fee',
            AmountReceived__c=200
        );
        insert tempOtherCharge;
        
        
        List<Id> raIds=new List<Id>();
        raIds.add(testRecAck.id);
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('base64');
        cv.Title = 'filename';
        cv.Origin = 'H';
        cv.PathOnClient = '/' + 'filename';
        insert cv;
        
        ReceiptAcknowledgementHandler.ReceiptAcknowlegment parentRecord =  ReceiptAcknowledgementHandler.initialiseReceiptAcknowlegment(tempInstLines.id);
        ReceiptAcknowledgementHandler.initialiseReceiptAcknowlegment(tempOtherCharge.id);
        ReceiptAcknowledgementHandler.getBankDetails(tempInstLines.Id);
        ReceiptAcknowledgementHandler.getBankDetails(tempOtherCharge.Id);
        
        String wrapperString = JSON.serialize(parentRecord);
        System.debug(wrapperString);
        //  ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(receiptRec,lineRec.Id,filesToInsert,wrapperString);
        ReceiptAcknowledgement__c receiptRecord = new ReceiptAcknowledgement__c();
        List<Object> filesToInsert = new List<Object>();
        
        ReceiptAcknowledgementHandler.fetchUserProfileName();
        ReceiptAcknowledgementHandler.getDetailOfReceiptAcknowledgement(tempOtherCharge.id);
        ReceiptAcknowledgementHandler.getDetailOfReceiptAcknowledgement(tempInstLines.id);
        
        ReceiptAcknowledgementHandler.getDetailOfInstallmentRecord(testOrder.id,5,'Installment',false,null);
        ReceiptAcknowledgementHandler.getDetailOfInstallmentRecord(testOrder.id,5,'Installment',true,tempAcc.id);
        
        
        ReceiptAcknowledgementHandler.InsertReceiptAcknowledgement('base64data', 'filename',newDoc,testRecAck1, tempInstLines.id,wrapperString,false);
        
        ReceiptAcknowledgementHandler.createContentVersion('base64', 'filename');
        ReceiptAcknowledgementHandler.createContentLink(cv.id, newDoc.id);
        ReceiptAcknowledgementHandler.fetchAlldetailsofFields(raIds);
        
    }
    @isTest static void ReceiptAcknowledgementHandlerTestMethod1(){
        
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
            Project__c=testProject.Id
        );
        insert testUnit;
        
        Account tempAcc=new Account(
            Name ='test'
        );
        insert tempAcc;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c =tempAcc.Id
        );
        insert testOrder;
        
        PaymentPlan__c tempPayPlan=new PaymentPlan__c(
            Name='Test Payment',
            Description__c='test'
            
        );
        insert tempPayPlan;
        
        PaymentInstallments__c tempPayInstall=new PaymentInstallments__c(
            InstallmentNumber__c=1,
            PaymentPlan__c=tempPayPlan.id,
            InstallmentPercentage__c=10,
            Description__c='test',
            Condition_Type__c='P012'
        );
        insert tempPayInstall;
        
        InstallmentLines__c tempInstLines= new InstallmentLines__c(
            SalesOrder__c=testOrder.id,
            Description__c='test',
            PaymentInstallments__c=tempPayInstall.id,
            PaymentPlan__c=tempPayPlan.Id,
            AmountReceived__c=200
        );
        insert tempInstLines;
        
        Document__c newDoc=new Document__c();
        newDoc.Document_Name__c='Test';
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id
        );
        insert tempOpp;
        ReceiptAcknowledgement__c testRecAck= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            SalesOrder__c=testOrder.id,
            Amount__c=100,
            ReferenceNumber__c='456732',
            Account__c=tempAcc.id
        );
        insert testRecAck;
        
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            Account__c=tempAcc.id,
            ReferenceNumber__c = '435678',
            SalesOrder__c = testOrder.id
        );
        
        
        ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c =testRecAck.id;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = testOrder.id;
        newReceiptAllocation.Account__c = tempAcc.id;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        
        
        SalesOrderOtherCharges__c tempOtherCharge=new SalesOrderOtherCharges__c(
            SalesOrder__c=testOrder.Id,
            Account__c=tempAcc.Id,
            Amount__c=1000,
            TypeOfCharge__c='ADM Fee',
            AmountReceived__c=200
        );
        insert tempOtherCharge;
        
        ReceiptAcknowledgementHandler.insertAllocatedReceiptWthAmt(new List<InstallmentLines__c>{tempInstLines},testRecAck1,new List<SalesOrderOtherCharges__c>{tempOtherCharge});
        ReceiptAcknowledgementHandler.getRemitterNames(tempAcc.Id);
        ReceiptAcknowledgementHandler.getDetailOfReceiptAcknowledgement(testOrder.Id);
    }}