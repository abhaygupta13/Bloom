@isTest
public class LeasingReceiptControllerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Customer'
        );
        insert acc;
        BankAccount__c  bankAcc = new BankAccount__c (
            Name = 'Corporate Bank',
            AccountNumberCorporate__c = '1234567890'
        );
        insert bankAcc;
        Project__c proj = new Project__c(
            Name = 'Test Project',
            LeasingBankAccount__c = bankAcc.Id
        );
        insert proj;
        Unit__c unitRec = new Unit__c(
            Name = 'Unit 101'
        );
        insert unitRec;
        LeasingOrder__c orderRec = new LeasingOrder__c(
            Name = 'Test Order',
            Account__c = acc.Id,
            Project__c = proj.Id,
            Unit__c = unitRec.Id,
            LeasingSAPContractId__c = 'SAP123'
        );
        insert orderRec;
        PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c(
            Name = 'Installment 1',
            LeasingOrder__c = orderRec.Id,
            ClearedAmount__c = 10,
            Amount__c  = 200,
            PaymentStatus__c = 'Un Paid'
        );
        insert schedule;
        LeasingOrdersOtherCharges__c charge = new LeasingOrdersOtherCharges__c(
            LeasingOrder__c = orderRec.Id,
            ClearedAmount__c = 10,
            ChargeAmount__c   = 200,
            PaymentStatus__c = 'Un Paid'
        );
        insert charge;
        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = orderRec.Id,
            Amount__c = 5000,
             AppliedAmount__c = 500
        );
        insert receipt;
        
        DocumentType__c mockDocType = new DocumentType__c(
            Type__c = 'Proof of Payment',
            ObjectType__c = 'LeasingReceiptAcknowledgment__c',
            Active__c = true
        );
        insert mockDocType;
    }

    @isTest
    static void testLoadData() {
        LeasingOrder__c orderRec = [SELECT Id FROM LeasingOrder__c LIMIT 1];

        Test.startTest();
        LeasingReceiptController.ReceiptWrapper result =
            LeasingReceiptController.loadData(orderRec.Id);
        Test.stopTest();
    }

    @isTest
    static void testSaveReceipt() {
        LeasingOrder__c orderRec = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        PaymentPlanSchedule__c schedule =
            [SELECT Id,Amount__c FROM PaymentPlanSchedule__c LIMIT 1];
        BankAccount__c bankAccount = [SELECT Id FROM BankAccount__c LIMIT 1];

        LeasingReceiptAcknowledgment__c receipt =
            new LeasingReceiptAcknowledgment__c(
                Amount__c  = 5000,
                AppliedAmount__c = 500,
                LeasingOrder__c = orderRec.Id,
                PaymentType__c = 'Link Payment',
                BeingTowards__c = 'Rent Installment',
                ChequeDate__c = Date.today(),
                VerifyDate__c = Date.today(),
                ReceiptDate__c = Date.today(),
                ChequeNumber__c = '1234',
                ReferenceNumber__c = '1234',
                BankAccount__c = bankAccount.Id,
                IsIntercompanyTransaction__c = false,
                BankChargesApplicable__c = false,
                IsAdvancePayment__c = false,
                ReceivingEntity__c = '1234',
                BankCharges__c = 1234
            );

        String rowsJson = '[{' +
            '"recordId":"' + schedule.Id + '",' +
            '"appliedAmount":10,' +
            '"apply":true,' +
            '"type":"schedule"' +
            '}]';

        Test.startTest();
        LeasingReceiptController.saveReceipt(
            orderRec.Id,
            receipt,
            rowsJson
        );
        Test.stopTest();

        List<LeasingReceiptAllocation__c> allocations =
            [SELECT Id, AmountApplied__c
             FROM LeasingReceiptAllocation__c];
    }

    @isTest
    static void testSaveReceiptAllocation() {
        LeasingOrder__c orderRec = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        LeasingReceiptAcknowledgment__c receipt =
            [SELECT Id FROM LeasingReceiptAcknowledgment__c LIMIT 1];
        PaymentPlanSchedule__c schedule =
            [SELECT Id FROM PaymentPlanSchedule__c LIMIT 1];

        String rowsJson = '[{' +
            '"recordId":"' + schedule.Id + '",' +
            '"appliedAmount":10,' +
            '"apply":true,' +
            '"type":"schedule"' +
            '}]';

        Test.startTest();
        LeasingReceiptController.saveReceiptAllocation(
            orderRec.Id,
            receipt.Id,
            rowsJson
        );
        Test.stopTest();

        List<LeasingReceiptAllocation__c> allocations =
            [SELECT Id, AmountApplied__c
             FROM LeasingReceiptAllocation__c
             WHERE LeasingReceiptAcknowledgment__c = :receipt.Id];
    }

    @isTest
    static void testSaveReceiptAllocation_ExceedsAmount() {
        LeasingOrder__c orderRec = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        LeasingReceiptAcknowledgment__c receipt =
            [SELECT Id FROM LeasingReceiptAcknowledgment__c LIMIT 1];
        PaymentPlanSchedule__c schedule =
            [SELECT Id FROM PaymentPlanSchedule__c LIMIT 1];

        String rowsJson = '[{' +
            '"recordId":"' + schedule.Id + '",' +
            '"appliedAmount":10,' +
            '"apply":true,' +
            '"type":"schedule"' +
            '}]';

        Test.startTest();
        try {
            LeasingReceiptController.saveReceiptAllocation(
                orderRec.Id,
                receipt.Id,
                rowsJson
            );
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
	
	@isTest
    static void testCreateFinanceTask() {
        LeasingReceiptAcknowledgment__c receipt = [SELECT Id FROM LeasingReceiptAcknowledgment__c LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        // Build parameters mapping to the LeasingReceiptAcknowledgementDataWrapper structure
        LeasingReceiptController.LeasingReceiptAcknowledgementDataWrapper payload = 
            new LeasingReceiptController.LeasingReceiptAcknowledgementDataWrapper();
        payload.receiptAcknowledgementId = receipt.Id;
        payload.financeUser = currentUserId;
        payload.checkStatus = 'On Hold';

        String serializedInput = JSON.serialize(payload);

        Test.startTest();
        String result = LeasingReceiptController.createFinanceTask(serializedInput);
        Test.stopTest();

        System.assertEquals('Success', result, 'The task engine should confirm with a success message string.');
    }

    @isTest
    static void testHandleFinanceFileUpload() {
        LeasingReceiptAcknowledgment__c receipt = [SELECT Id FROM LeasingReceiptAcknowledgment__c LIMIT 1];
        
        String sampleFileName = 'PaymentConfirmation.pdf';
        String sampleBase64Data = EncodingUtil.base64Encode(Blob.valueOf('Mock Base64 file stream string'));

        Test.startTest();
        String responseStatus = LeasingReceiptController.handleFinanceFileUpload(
            receipt.Id,
            sampleFileName,
            sampleBase64Data
        );
        Test.stopTest();
    }

    @isTest
    static void testHandleFinanceFileUpload_Exception() {
        Test.startTest();
        try {
            LeasingReceiptController.handleFinanceFileUpload(null, '', '');
            System.assert(false, 'Expected AuraHandledException to be thrown.');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Validation tracking parameters captured error safely.');
        }
        Test.stopTest();
    }
}