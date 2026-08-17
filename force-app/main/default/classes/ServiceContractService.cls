/*
* @Author : Eagles
* @CreatedDate : 22 dec 2024
* @Description : ServiceContractService
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Eagles    22 dec 2024        Initial draft 
*****************************************************************************************************/

public class ServiceContractService {
	
	public static void insertService(Service_Contract__c sContract){
		INSERT sContract;
	}

	public static List<Service_Contract__c> lstSContrscts(String accountID){
		List<Service_Contract__c> lstContracts =[SELECT Move_Out_Date__c FROM Service_Contract__c where Customer_Name__c=:accountID];
		return lstContracts;
	}

	public static void updateService(Service_Contract__c sContract){ 
		update sContract;
	}
}