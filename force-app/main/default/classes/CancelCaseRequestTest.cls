@isTest
public class CancelCaseRequestTest {
    @isTest static void CancelCaseRequestTestMethod(){
        Case tempCase=new Case(
        	CurrencyIsoCode='AED',
            Status='In Progress',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            Case_Sub_Status__c = 'Transfer Initiated'
        );
        insert tempCase;
        
        CancelCaseRequest.markClosedStatus(tempCase.Id);
    }
    @isTest static void CancelCaseRequestTestMethod1(){
        CancelCaseRequest.Utility();
    }
}