import { track, api, wire, LightningElement } from 'lwc';
import getVFOrigin from '@salesforce/apex/OCRCtrl.getVFOrigin';
import createPersonAccount from '@salesforce/apex/OCRCtrl.createPersonAccount';
import createLead from '@salesforce/apex/OCRCtrl.createLead';
import getDuplicateAccount from '@salesforce/apex/OCRCtrl.getAccountByDocumentAndEmirateId';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedDocuments from '@salesforce/apex/OCRCtrl.getRelatedDocuments';
import getOcrButtonvisibleDetail from '@salesforce/apex/OCRCtrl.getOcrButtonvisibleDetail';
import addFilesonRecordCreate from '@salesforce/apex/CustomDocManageController.addFilesonRecordCreate';
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import { NavigationMixin } from 'lightning/navigation';
import Id from "@salesforce/user/Id";



export default class OcrAccountCreation extends NavigationMixin(LightningElement) {

    @track ocrData;
    @track leadOcrData;
    @api recordId;
    genderMap = new Map([['M', 'Male'], ['F', 'Female']]);
    accountfieldList;
    showData = false;
    showLoading = true;
    @track isLoading=false;
    @track isLoading1=false;
    @track imgDataList;
    @track callOnce = true;
    @track documentType;
    @track sObjectLookupApiname;
    documentList;
    docOptions = [];
    @track recordId;
    @track showsaveDocbutton = false;
    @track documentType;
    @track showCreatAccount=false;
     @track readOnlyFields = false;
     @track showNavigateButton=false;
     @track uploadedImageCount = 0;
     userId = Id;
     @track showAccountandOpportunity=false;
     @track showCreateLead=false;
     @track createWalkinOpportunity = false;
     @track showNavigateButtonAccountOpportunity=false;
     @track isAccountInserted = false;
     @track mobilecountrycode;
     @track AccountResult;
     @track showAccountResult=false;
     @track showCreatDuplicateAccount=false;
     @track isDuplicateEligible=false;
     @track showCreateAccountandOpportunityDuplicate=false;
     emailaddress;
    phonevalue;
    mobileCountrycode;

    handleChange(event) {
    if (event.target.name === 'email') {
        this.emailaddress = event.target.value;
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/;
      if (!emailRegex.test(this.emailaddress)) {
            this.emailError = 'Invalid email address';
        } else {
            this.emailError = '';
        }
        
        console.log('this.emailaddress: ' + this.emailaddress);
    } else if (event.target.name === 'phone') {
        this.phonevalue = event.target.value;
        console.log('this.phonevalue: ' + this.phonevalue);
    } else if (event.target.name === 'mobileCountrycode') {
        this.mobileCountrycode = event.target.value;
        console.log('this.mobileCountrycode: ' + this.mobileCountrycode);
    }
    
}
   
   


    passportMap = new Map([['Document Number', 'PassportNumber__pc'],
    ['Date of Birth', 'PersonBirthdate'],
    ['Sex', 'Gender__pc'],
    ['Date of Expiry', 'PassportExpiryDate__pc'],
    ['Nationality', 'Nationality__pc'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);

 LeadpassportMap = new Map([['Document Number', 'Passport_Number__c'],
    ['Date of Birth', 'Birthdate__c'],
    ['Sex', 'Gender__c'],
    ['Date of Expiry', 'PassportExpiryDate__c'],
    ['Nationality', 'Nationality__c'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);


    EIDMap = new Map([['Identity Card Number', 'Emirates_Id__pc'],
    ['Date of Birth', 'PersonBirthdate'],
    ['Sex', 'Gender__pc'],
    ['Date of Expiry', 'EID_Expiry_Date__pc'],
    ['Nationality', 'Nationality__pc'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);

    LeadEIDMap = new Map([['Identity Card Number', 'Emirates_Id__c'],
    ['Date of Birth', 'Birthdate__c'],
    ['Sex', 'Gender__c'],
    ['Date of Expiry', 'Emirate_Expiry_Date__c'],
    ['Nationality', 'Nationality__c'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);

    @wire(getVFOrigin)
    vfOrigin;


    connectedCallback() {
        

        try {
            window.addEventListener("message", this.handleVFResponse.bind(this));
        } catch (e) {
            console.log(e.message)
        }


    }


    handleVFResponse(message) {

        //console.log(message.origin)
        //console.log(this.vfOrigin.data)   

        if (message.origin === this.vfOrigin.data) {

            console.log(message.data)
            // console.log(message.data.text.fieldList)
            const data = message.data.text.fieldList;
            const imgData = message.data.images.fieldList;


            let tempArr = [];
            let leadtempArr = [];

            let tempParmsList;
            let docType = '';
            data.forEach((item) => {
                if (item.fieldName == 'Document Class Code') {
                    console.log('Log:Doc Type Value-'+item.value);
                    if (item.value == 'IL' || item.value == 'ID') {
                        this.accountfieldList = this.eidList;
                        tempParmsList = this.eidParamsList;
                        docType = item.value;
                    } else if (item.value == 'P') {
                        this.accountfieldList = this.passportList;
                        tempParmsList = this.passportParamsList;
                        docType = item.value;
                    }
                    return;
                }
            });
            this.documentType = docType;
            //Img Object Preparation Start
            let tempImg = [];
            imgData.forEach((item) => {

                item.valueList.forEach((img) => {
                    if (img.containerType == 1 || img.containerType == 6) {
                        let imgObj = new Object();
                        imgObj.docName = item.fieldName;
                        //imgObj.docList = this.docOptions; //uncommented
                        imgObj.docValue = '';
                        imgObj.showBtn = true; 
                        if (img.containerType == 6)
                            imgObj.isPortrait = true;
                        else
                            imgObj.isPortrait = false;
                        imgObj.base64Data = 'data:image/png;base64,' + img.value;
                        tempImg.push(imgObj);
                    }
                });

            });
            this.imgDataList = tempImg;
            console.log(tempImg)
            //Img Object Preparation End
            console.log('Log2:Document Type--'+docType);

            if (docType == 'P') {

                data.forEach((item) => {


                    if (Array.from(this.passportMap.keys()).includes(item.fieldName)) {
                        console.log('noramlone'+this.passportMap.get(item.fieldName))
                        console.log(item.value)
                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.passportMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                        tempArr.push(obj);
                    } if (Array.from(this.LeadpassportMap.keys()).includes(item.fieldName)) {
                        console.log('leadone'+this.LeadpassportMap.get(item.fieldName))
                        console.log(item.value)
                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.LeadpassportMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                        //tempArr.push(obj);
                        leadtempArr.push(obj);
                    }

                });
            } else if (docType == 'IL' || docType == 'ID') {
                data.forEach((item) => { //'Document Class Code', //Identity Card Number


                    if (Array.from(this.EIDMap.keys()).includes(item.fieldName)) {
                        console.log(item)
                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.EIDMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                        tempArr.push(obj);
                    } if (Array.from(this.LeadEIDMap.keys()).includes(item.fieldName)) {
                        console.log(item)
                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.LeadEIDMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                       // tempArr.push(obj);
                       leadtempArr.push(obj);
                        
                    }

                });

            }
            

            this.ocrData = tempArr;
            this.leadOcrData=leadtempArr;
            this.showData = true;
            console.log(JSON.stringify(ocrData))
        }

    }
    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Account has been updated successfully!',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
    }
    iframeLoadHandler(event) {
        this.showLoading = false;
    }

    navigateToLeadRecord(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordIdOrg, // Replace with your recordId
                objectApiName: 'Lead', // Replace with the object you are navigating to
                actionName: 'view'
            }
        });

    }

    

    createLead(){
        
         this.isLoading=true;
        let obj = new Object();
        obj.sobjectType = 'Lead';
        //obj.LastName='test';
        this.leadOcrData.forEach(item => {
            if (this[item.sfField]) {
                item.OCRValue = this[item.sfField];
            }
            if (item.OCRValue == 'F') {
                obj[item.sfField] = 'Female';
            }
            else if (item.OCRValue == 'M') {
                obj[item.sfField] = 'Male';
            }
            else {
                obj[item.sfField] = item.OCRValue;
            }

        });
        console.log('Account Obj:' + JSON.stringify(obj));

        
        
      
        createLead({
            lead: obj,
             mobileCountrycode:this.mobileCountrycode,
            emailaddress:this.emailaddress,
            phonevalue:this.phonevalue
        }).then(result => {

            if (result) {
               
                //this.showCreatAccount=false;
                this.readOnlyFields = true;
                this.showLoading=false;
                this.recordIdOrg = result;
                console.log('record Id:' + this.recordIdOrg);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Lead has been created successfully.',
                    }),
                );
                this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordIdOrg, // Replace with your recordId
                objectApiName: 'Lead', // Replace with the object you are navigating to
                actionName: 'view'
            }
        });

                this.getDocTypesList();

                this.showsaveDocbutton = true;
                 this.isLoading=false;
                
            }

        }).catch(error => {
             this.isLoading=false;
            this.showToast('Something went wrong', error.body.message, 'error');
        })
    }
    navigateToAccountRecord(){
        const accountId = event.target.dataset.id
        console.log('accounitId'+accountId);
       
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId, 
                objectApiName: 'Account', 
                actionName: 'view'
            }
        });

    }

    createAccount() {
    
       this.isLoading=true;
       this.showAccountandOpportunity=false;
       this.showNavigateButtonAccountOpportunity=false;
        console.log('OCR Data:' + JSON.stringify(this.ocrData));
        let obj = new Object();
        obj.sobjectType = 'Account';
        //obj.LastName='test';
        this.ocrData.forEach(item => {
            if (this[item.sfField]) {
                item.OCRValue = this[item.sfField];
            }
            if (item.OCRValue == 'F') {
                obj[item.sfField] = 'Female';
            }
            else if (item.OCRValue == 'M') {
                obj[item.sfField] = 'Male';
            }
            else {
                obj[item.sfField] = item.OCRValue;
            }

        });
        console.log('Account Obj:' + JSON.stringify(obj));
    
         if(this.isDuplicateEligible!=true){
        getDuplicateAccount({acc: obj})
        .then(result=>{
          
                if(result!=null){
                   
                    this.showAccountResult=true;
                    this.AccountResult= result;
                    console.log('this.AccountResult'+JSON.stringify(this.AccountResult));
                   // this.showCreatAccount=false;
                    //this.showCreatDuplicateAccount=true;
            
                   // this.accountId =result[0].Id;
                
            
            }
           
           
        }).catch(error=>{
            this.error=error;
          
            console.log('error'+JSON.stringify(this.error.body));
            console.log('error'+JSON.stringify(this.error.body.message));
        })}
        
        createPersonAccount({
            acc: obj,
            createwalkinopportunity: this.createWalkinOpportunity,
            mobileCountrycode:this.mobileCountrycode,
            emailaddress:this.emailaddress,
            phonevalue:this.phonevalue,
            isDuplicateEligible:this.isDuplicateEligible
        }).then(result => {

            if (result) {
                this.isLoading=false;
                this.showCreatAccount=false;
                this.readOnlyFields = true;
                this.showLoading=false;
                this.showNavigateButton=true;
                this.isAccountInserted = true;
                this.showAccountResult=false;
                this.showCreatDuplicateAccount=false;
                
                this.recordIdOrg = result;
                
                console.log('record Id:' + this.recordIdOrg);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Person Account has been Created.',
                    }),
                );

                this.getDocTypesList();

                this.showsaveDocbutton = true;
                 this.isLoading=false;;
                
            }

        }).catch(error => {
            this.error=error;
            console.log('error'+this.error);
             this.isLoading=false;
            this.showToast('Something went wrong', error.body.message, 'error');
        })
    }
  
    createDuplicateAccount(){
        this.isDuplicateEligible=true;
        this.createAccount();

    }
    createAccountAndOpportunityDuplicate(){
        this.isDuplicateEligible=true;
        this.createAccountAndOpportunity();
    }
    navigateToAccount() {
        // Navigate to the newly created account
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordIdOrg, // Replace with your recordId
                objectApiName: 'Account', // Replace with the object you are navigating to
                actionName: 'view'
            }
        });
    }
    navigateToAccountopp(){
     this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordIdOrg, // Replace with your recordId
                objectApiName: 'Account', // Replace with the object you are navigating to
                actionName: 'view'
            }
        });
    }

    getDocTypesList() {
        
        getRelatedDocuments({
            recordId: this.recordIdOrg,
            doctype: this.documentType
        }).then(result => {

            this.docOptions = result?.map(
                ({ Id, Document_Name__c }) => ({ value: Id, label: Document_Name__c })
            );


        }).catch(error => {
            this.showToast('Something went wrong', error.body.message, 'error');
        })
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    recordEdited(event) {
        this[event.target.name] = event.target.value;
    }


    imgSaveBtnHandler(event) {
        let index = event.target.dataset.index;
        this.imgDataList[index].docValue = event.target.value;
        console.log('option selected:' + event.target.value);
    }

    imgSaveHandler(event) {
    this.isLoading1 = true;
    let index = event.target.dataset.index;
    if (this.imgDataList[index].docValue) {
        let data = this.imgDataList[index];
        let obj = new Object();
        obj.sobjectType = 'Document__c';
        obj.Id = data.docValue;

        addFilesonRecordCreate({ base64: data.base64Data.split(',')[1], filename: data.docName + '.png', documentObj: obj })
            .then(result => {
                if (result === 'SUCCESS') {
                    this.imgDataList[index].showBtn = false;
                    this.uploadedImageCount++; // Increment the uploaded image count
                    const toastEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'Image is added to the record successfully.',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.showLoading = false;

                    // Check if the uploaded image count is 2 or more, and if so, hide the save button
                    if (this.uploadedImageCount >= 2) {
                        this.showsaveDocbutton = false;
                    }
                    this.isLoading1=false;
                }
            }).catch(error => {
                console.log(error);
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'Unable to process your request.' + error.Message,
                    variant: 'error'
                });
                this.dispatchEvent(toastEvent);
                this.showLoading = true;
            });
    } else {
         this.isLoading1 = false;
        const toastEvent = new ShowToastEvent({
            title: 'Warning',
            message: 'Please select document type',
            variant: 'warning'
        });
        this.dispatchEvent(toastEvent);
    }
}

createAccountAndOpportunity(){
  //  alert('inside create'+this.isDuplicateEligible);
    this.showCreatAccount=false;
    this.createWalkinOpportunity = true;
    this.showNavigateButton=false;
    this.isLoading=true;
   
      
        console.log('OCR Data:' + JSON.stringify(this.ocrData));
        let obj = new Object();
        obj.sobjectType = 'Account';
        //obj.LastName='test';
        this.ocrData.forEach(item => {
            if (this[item.sfField]) {
                item.OCRValue = this[item.sfField];
            }
            if (item.OCRValue == 'F') {
                obj[item.sfField] = 'Female';
            }
            else if (item.OCRValue == 'M') {
                obj[item.sfField] = 'Male';
            }
            else {
                obj[item.sfField] = item.OCRValue;
            }

        });
        console.log('Account Obj:' + JSON.stringify(obj));

        if(this.isDuplicateEligible!=true){
        getDuplicateAccount({acc: obj}).then(result=>{
          
                if(result!=null){
                   //this.showCreateAccountandOpportunityDuplicate=true;
                    this.showAccountResult=true;
                    this.AccountResult= result;
                    console.log('this.AccountResult'+JSON.stringify(this.AccountResult));
                   // this.showCreatAccount=false;
                    
            
                   // this.accountId =result[0].Id;
                
            
            }
           
           
        }).catch(error=>{
            this.error=error;
          
            console.log('error'+JSON.stringify(this.error.body));
            console.log('error'+JSON.stringify(this.error.body.message));
        })}
        
      
        createPersonAccount({
            acc: obj,
            createwalkinopportunity: this.createWalkinOpportunity,
             mobileCountrycode:this.mobileCountrycode,
            emailaddress:this.emailaddress,
            phonevalue:this.phonevalue,
            isDuplicateEligible:this.isDuplicateEligible
        }).then(result => {
       // alert(JSON.stringify(result));
            if (result) {

                this.isLoading=true;
                this.showCreatAccount=false;
                this.readOnlyFields = true;
                this.showLoading=true;
                this.showAccountandOpportunity=false;
                this.showNavigateButtonAccountOpportunity=true;
                this.showCreateAccountandOpportunityDuplicate=false;
                this.isAccountInserted = true;
                this.recordIdOrg = result;
                
                console.log('record Id:' + this.recordIdOrg);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Person Account has been Created.',
                    }),
                );

                this.getDocTypesList();

                this.showsaveDocbutton = true;
                 this.isLoading=false;;
                
            }

        }).catch(error => {
         this.isLoading=false;
            this.showToast('Something went wrong', error.body.message, 'error');
        })
         
    }


@wire(getOcrButtonvisibleDetail, { userId: '$userId' })
    wireOcrData({ error, data }) {
        if (data) {
        this.showCreatAccount = data['Account'] || false;
         this.showCreateLead = data['Lead'] || false;
         this.showAccountandOpportunity = data['Opportunity'] || false;
     }else if (error) {
            console.error('Error fetching OCR button visibility:', error);
        }
    }

    @wire(getPicklistvalue , {
        objName: 'Lead', 
        fieldName: 'MobileCountryCode__c'
    })
    wiredMobileCountrycode({ data, error }) {
        if (data) {
            let temp = [];
        
            for(var key in data){
                temp.push({label:key, value:data[key]});
        }
        this.mobilecountrycode= temp;
        console.log(JSON.stringify(this.mobilecountrycode));
     } else if (error) {
            this.error = error;
            this.mobilecountrycode = undefined; 
        }
    }
    


}