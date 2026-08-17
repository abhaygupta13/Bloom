@isTest
public class ReceiptAllocationTriggerHandlerTest {
    @isTest static void ReceiptAllocationTriggerHandlerTestMethod(){
        Account tempAcc=new Account(
            Name='test'
        );
        insert tempAcc;
        Account tempAcc1=new Account(
            Name='test2'
        );
        insert tempAcc1;
        Opportunity tempOpp=new Opportunity(
        	Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='call',
            AccountId=tempAcc.Id
        );
        insert tempOpp;
        
        SalesOrder__c  testSalesOrder = new SalesOrder__c(Name = 'Test Salesorder', Account__c=tempAcc1.Id);
        insert testSalesOrder;
        
        ReceiptAcknowledgement__c testRecAck= new ReceiptAcknowledgement__c(
        	Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            SalesOrder__c=testSalesOrder.id
        );
        insert testRecAck;
        
        ReceiptAllocation__c testRecAloc=new ReceiptAllocation__c(
        	ReceiptAcknowledgement__c=testRecAck.id,
            Account__c=tempAcc.id
        );
        insert testRecAloc;
        List<SObject> recAlocList=new List<SObject>();
        recAlocList.add(testRecAloc);
        Map<Id, SObject> recAlocMap= new Map<Id, SObject>();
        recAlocMap.put(testRecAloc.id,testRecAloc);
        
        testRecAloc.Account__c=tempAcc1.id;
        update testRecAloc;
        
       /* List<SObject> recAlocListUpdated=new List<SObject>();
        recAlocListUpdated.add(testRecAloc);
        Map<Id, SObject> recAlocMapUpdated= new Map<Id, SObject>();
        recAlocMapUpdated.put(testRecAloc.id,testRecAloc);
        
        //ReceiptAllocationTriggerHelper helper=new ReceiptAllocationTriggerHelper();
        
        //helper.afterInsertMethod(recAlocList,recAlocMap);
        //helper.afterUpdateMethod(recAlocListUpdated, recAlocMapUpdated, recAlocList, recAlocMap);
        */
    }
    
    @isTest static void testDummyMethod(){
        ReceiptAllocationTriggerHelper.dummyMethod();
    }
}