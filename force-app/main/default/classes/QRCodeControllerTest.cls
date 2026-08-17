/*
* @Author : Biswajeet Samal
* @CreatedDate : 13th APR 2025
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Biswajeet  13APR2025        QRCodeControllerTest  
*****************************************************************************************************/
@IsTest
public class QRCodeControllerTest {
    
    @IsTest
    static void testGetContactUsVCardDownloadUrl(){
        test.startTest();
        QRCodeController.getContactUsVCardDownloadUrl();
        test.stopTest();
    }
}