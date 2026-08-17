/***
Class       : srPostponeApprovedActionController
Author      : Sonali S
Description : 
TestClass   : srPostponeApprovedActionControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              26/04/25          Initial Version 
****************************************************************************************************************/

public without sharing class srPostponeApprovedActionController {

    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPostponeApprovedPicklistValues() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.PostponeApproved__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(entry.getLabel());
            }
        }
        return options;
    }

    
    @AuraEnabled 
    public static Map<String, Object> updatePostponeApprovedField(Id caseId, String selectedValue) {
         try {
            PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
            return obj.postponeApprovalUpdate(caseId,selectedValue);
        } catch (Exception e) {
            throw new AuraHandledException('Error: '+ e.getMessage()); 
        }
    }
}