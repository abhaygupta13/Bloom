/*
* @Author      : Shruti Kulkarni
* @CreatedDate : 11th AUG 2025
* @Description : Test class for FlowInvocableMethodController, validating functionality related to
				 escalation date calculations.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Shruti        11-AUG-2025    Initial draft
*****************************************************************************************************/
@isTest
private class FlowInvocableMethodControllerTest {
	@isTest
    static void testCalculateEscalationDate() {
        List<FlowInvocableMethodController.InputWrapper> listInputWrapper = new List<FlowInvocableMethodController.InputWrapper>();
        FlowInvocableMethodController.InputWrapper objInputWrapper = new FlowInvocableMethodController.InputWrapper();
        objInputWrapper.escalationTenure = 2;
        listInputWrapper.add(objInputWrapper);

        List<FlowInvocableMethodController.EscalationDetailsWrapper> listEscalationDetailsWrapper = new List<FlowInvocableMethodController.EscalationDetailsWrapper>();

        DateTime startDt = DateTime.newInstance(2025, 6, 27, 2, 0, 0);
        System.debug('startDt >> '+startDt);

        Test.startTest();
        listEscalationDetailsWrapper = FlowInvocableMethodController.calculateEscalationDate(listInputWrapper);
        Test.stopTest();

        for(FlowInvocableMethodController.EscalationDetailsWrapper objEscalationDetail : listEscalationDetailsWrapper)  {
            system.debug('Escalation date >> '+objEscalationDetail.escalationDate);
            System.assert(objEscalationDetail.escalationDate!=null);
        }
    }
}