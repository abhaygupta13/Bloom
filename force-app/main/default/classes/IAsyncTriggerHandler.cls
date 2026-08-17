/*
@Author : Biswajeet Samal
@CreatedDate : 7th Aug 2024
@Description : Trigger Handler Interface
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public interface IAsyncTriggerHandler{
    
    /*
@Author : Biswajeet Samal
@CreatedDate : 7th Aug 2024
@Description : Invoked by the trigger framework before insert of the records
@Parameters : List<sObject> newList , Map<Id, sObject> newMap
*/
    void changeEventCapture(List<sObject> newList);
    
    /*
@Author : Biswajeet Samal
@CreatedDate : 7th Aug 2024
@Description : Invoked by the trigger framework to check the trigger for the object is enabled or disabled
@Parameters :
*/
    Boolean isDisabled();
}