/**
* @File Name : accessPermitEmailHelperQueuable.c_Cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 5, 2025 |   | Initial Version
**/

public class accessPermitEmailHelperQueuable implements Queueable, Database.AllowsCallouts {
    public List<Case> caseList ; 
	List<String> lstEmails=new List<String>();
	Set<id> caseId=New Set<Id>();
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Access Permit').getRecordTypeId();
    public accessPermitEmailHelperQueuable(List<Case> caseList){
        this.caseList = caseList ;  
    }
    public void execute(QueueableContext context) {
		for(case rec:caseList){
           if((rec.Status=='Approved' || rec.Status=='Rejected') && 
              rec.recordTypeId==recordTypeId){
                 caseId.add(rec.Id);
		   }
		}
        if(!caseId.isEmpty()){
            Case caseRecord=[SELECT Parentid,Parent.Account.PersonEmail FROM case WHERE
                             id=:caseId LIMIT 1];
            lstEmails.add(caseRecord.Parent.Account.PersonEmail);
            if(!Test.isRunningTest()){
                BCAPP_CaseController.sendApprovalEmail('Bloom_Access_Permit_Approval_Email', lstEmails, true,caseRecord.Parentid);
            }
            
        }
   }
}