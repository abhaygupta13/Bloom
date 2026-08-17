/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : QR Code Controller
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Biswajeet   	07AUG2024        Initial draft                                                                 
*****************************************************************************************************/
public without sharing class QRCodeController {
    
    @AuraEnabled(cacheable=false)
    public static String getContactUsVCardDownloadUrl() {
        String vCardContent = 
            'BEGIN:VCARD\n' +
            'VERSION:3.0\n' +
            'FN:Bloom Properties\n' +
            'N:Properties;Bloom;;;\n' +
            'ORG:Bloom Holding\n' +
            'TITLE:Bloom Care\n' +
            'TEL;TYPE=WORK,VOICE:(800) 25666\n' +
            'EMAIL:customerservice@bloomholding.com\n' +
            'ADR;TYPE=WORK:;;7th Floor, Bloom Central, Sheikh Rashid Bin Saeed St. Rd 18;Abu Dhabi;;00000;UAE\n' +
            'URL:https://www.bloomholding.com\n' +
            'URL;TYPE=Instagram:https://www.instagram.com/bloomholding\n' +
            'END:VCARD';
        Blob vCardBlob = Blob.valueOf(vCardContent);
        String base64Content = EncodingUtil.base64Encode(vCardBlob);
        return 'data:text/vcard;charset=utf-8;base64,' + base64Content;
    }
}